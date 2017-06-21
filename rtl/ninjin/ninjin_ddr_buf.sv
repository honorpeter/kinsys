`include "ninjin.svh"

/* TODO:
 *  - Implement prefetch mode (r_mode[0] == M_TRANS && r_mode[1] == M_INCR)
 *  - Pass proper signals to M_AXI interface
 *  - Implement double buffering scheme with DWIDTH-BWIDTH convert.
 */

module ninjin_ddr_buf
  ( input                     clk
  , input                     xrst
  // Meta inputs
  , input                     prefetch_en
  , input [LWIDTH-1:0]        total_len
  , input [IMGSIZE-1:0]       base_addr
  // memory ports
  , input                     mem_we
  , input [IMGSIZE-1:0]       mem_addr
  , input signed [DWIDTH-1:0] mem_wdata
  // m_axi ports (fed back)
  , input                     ddr_we
  , input [IMGSIZE-1:0]       ddr_addr
  , input [BWIDTH-1:0]        ddr_wdata
  // m_axi signals
  , output                      ddr_req
  , output                      ddr_mode
  , output [IMGSIZE-1:0]        ddr_base
  , output [LWIDTH-1:0]         ddr_len
  , output [BWIDTH-1:0]         ddr_rdata
  // memory data
  , output signed [DWIDTH-1:0]  mem_rdata
  );

  localparam RATE = BWIDTH / DWIDTH;
  localparam RATELOG = $clog2(RATE);

  localparam  M_IDLE  = 0,
              M_INCR  = 1,
              M_TRANS = 2;

  // localparam ALPHA  = 'd0,
  //            BRAVO  = 'd1,
  //            BOOT   = 'd2;

  wire [1:0]                mode;
  wire                      txn_start;
  wire                      txn_stop;
  wire signed [IMGSIZE-1:0] addr_diff;
  wire                      pre_we;
  wire [BUFSIZE-1:0]        pre_addr;
  wire signed [BWIDTH-1:0]  pre_wdata;
  wire [BWIDTH-1:0]         pre_rdata;
  wire                      buf_we    [1:0];
  wire [BUFSIZE-1:0]        buf_addr  [1:0];
  wire signed [BWIDTH-1:0]  buf_wdata [1:0];
  wire [BWIDTH-1:0]         buf_rdata [1:0];
  wire switch_buf, pref_read_end;
  wire s_pref_edge, s_read_edge, s_write_edge;
  wire signed [LWIDTH-1:0]  len_diff;
  wire s_pref_end, s_read_end, s_write_end;
  wire [BUFSIZE+RATELOG-1:0] spagetti;
  wire [RATELOG-1:0] fuga;
  wire signed [DWIDTH-1:0] boot [RATE-1:0];
  wire signed [DWIDTH-1:0] crime [RATE-1:0];
  wire signed [DWIDTH-1:0] punish [RATE-1:0];
  wire mem_we_edge;
  wire [LWIDTH-1:0] my_new_length;

  enum reg [1:0] {
    S_IDLE, S_PREF, S_READ, S_WRITE
  } r_state [1:0];
  enum reg [1:0] {
    ALPHA=0, BRAVO=1, BOOT=2
  } r_which;
  reg [1:0]               r_mode;
  reg [RATE-1:0]          r_we_accum;
  reg [LWIDTH-1:0]        r_total_len;
  reg                     r_mem_we;
  reg [IMGSIZE-1:0]       r_mem_addr;
  reg signed [DWIDTH-1:0] r_mem_wdata;
  reg [IMGSIZE-1:0]       r_mem_base [1:0];
  reg                     r_buf_we;
  reg [IMGSIZE-1:0]       r_buf_addr;
  reg signed [BWIDTH-1:0] r_buf_wdata;
  reg [LWIDTH-1:0]        r_count_burst;
  reg [LWIDTH-1:0]        r_count_len;
  reg [LWIDTH-1:0]        r_count_inner;
  reg r_switch_buf;
  reg [LWIDTH-1:0] r_pref_len;
  reg [IMGSIZE-1:0] r_base_addr;
  reg [RATELOG-1:0] _fuga;
  reg r_ddr_req;
  reg r_ddr_mode;
  reg [IMGSIZE-1:0] r_ddr_base;
  reg [LWIDTH-1:0]  r_ddr_len;

  /*
   * When ddr_req asserts, ddr_mode and ddr_base are fetched.
   * Then m_axi starts streaming with ddr_stream channel.
   * The ddr_stream represents both reading and writing data stream
   * in context of ddr_mode.
   */

  assign s_pref_edge  = r_state[0] == S_PREF  && r_state[1] != S_PREF;
  assign s_read_edge  = r_state[0] == S_READ  && r_state[1] != S_READ;
  assign s_write_edge = r_state[0] == S_WRITE && r_state[1] != S_WRITE;

//==========================================================
// core control
//==========================================================
// {{{

  assign addr_diff = mem_addr - r_mem_addr;
  assign len_diff  = total_len - r_total_len;
  assign s_write_end = r_state[0] == S_WRITE && r_count_len <= RATE*BURST_LEN && switch_buf;
  assign s_read_end  = r_state[0] == S_READ && r_count_inner == r_count_len;


  for (genvar i = 0; i < 2; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst)
          r_state[0] <= S_IDLE;
        else
          case (r_state[0])
            S_IDLE:
              if (prefetch_en)
                r_state[0] <= S_PREF;
              else if (r_mem_we && addr_diff == 1)
                r_state[0] <= S_WRITE;
              else if (!r_mem_we && addr_diff == 1)
                r_state[0] <= S_READ;
            S_PREF:
              if (s_pref_end)
                r_state[0] <= S_IDLE;
            S_READ:
              if (s_read_end)
                r_state[0] <= S_IDLE;
            S_WRITE:
              if (s_write_end)
                r_state[0] <= S_IDLE;
            default:
              r_state[0] <= S_IDLE;
          endcase
      else
        always @(posedge clk)
          if (!xrst)
            r_state[i] <= S_IDLE;
          else
            r_state[i] <= r_state[i-1];

  assign mode = addr_diff == 0 ? M_IDLE
              : addr_diff == 1 ? M_INCR
              : M_TRANS;

  always @(posedge clk)
    if (!xrst)
      r_mode <= M_IDLE;
    else
      r_mode <= mode;

  assign pref_read_end = r_state[0] == S_READ
                      && r_count_burst == 0 && switch_buf;
  always @(posedge clk)
    if (!xrst)
      r_which <= BOOT;
    else
      case (r_which)
        BOOT:
          // if (s_write_edge)
          if (txn_start && mem_we)
            r_which <= ALPHA;
          else if (switch_buf)
            r_which <= ALPHA;

        ALPHA:
          if (s_read_end)
            r_which <= BOOT;
          else if (switch_buf)
            r_which <= BRAVO;
          else if (s_pref_edge)
            r_which <= BOOT;

        BRAVO:
          if (s_read_end)
            r_which <= BOOT;
          else if (switch_buf)
            r_which <= ALPHA;
          else if (s_pref_edge)
            r_which <= BOOT;

        default:
          r_which <= BOOT;
      endcase

  // r_which indicates which buffer is for user interface
  // always @(posedge clk)
  //   if (!xrst)
  //     r_which <= 0;
  //   else if (buf_we[r_which] && buf_addr[r_which] == BURST_LEN-1)
  //     r_which <= ~r_which;

  always @(posedge clk)
    if (!xrst)
      r_total_len <= 0;
    else
      r_total_len <= total_len;

  always @(posedge clk)
    if (!xrst)
      r_base_addr <= 0;
    else
      r_base_addr <= base_addr;

  always @(posedge clk)
    if (!xrst)
      r_count_burst <= 0;
    else if (r_state[0] == S_IDLE)
      r_count_burst <= 0;
    else if (switch_buf)
      r_count_burst <= r_count_burst + 1;

  always @(posedge clk)
    if (!xrst)
      r_count_len <= 0;
    else if (r_state[0] == S_IDLE)
      r_count_len <= 0;
    else if (s_pref_edge || s_read_edge || s_write_edge)
      r_count_len <= r_total_len;
    else if (switch_buf)
      r_count_len <= r_count_len - RATE*BURST_LEN;

  always @(posedge clk)
    if (!xrst)
      r_count_inner <= 0;
    else
      case (r_state[0])
        S_IDLE:
          if (txn_start && !r_mem_we)
            r_count_inner <= 2;
          else
            r_count_inner <= 0;
        S_WRITE:
          if (r_count_inner == RATE * BURST_LEN-1)
            r_count_inner <= 0;
          else
            r_count_inner <= r_count_inner + 1;
        S_PREF:
          if (ddr_we)
            r_count_inner <= r_count_inner + 1;
        S_READ:
          if (r_count_inner == RATE * (r_count_len > BURST_LEN ? BURST_LEN : r_count_len)-1)
            r_count_inner <= 0;
          else
            r_count_inner <= r_count_inner + txn_start + (addr_diff == 1 ? 1 : 00);
      endcase

// }}}
//==========================================================
// memory control
//==========================================================
// {{{

  assign spagetti = mem_addr - r_base_addr;
  assign fuga = spagetti[RATELOG-1:0];
  always @(posedge clk) _fuga <= fuga;

  for (genvar i = 0; i < RATE; i++) begin
    assign boot[i]   = pre_rdata[(i+1)*DWIDTH-1:i*DWIDTH];
    assign crime[i]  = buf_rdata[ALPHA][(i+1)*DWIDTH-1:i*DWIDTH];
    assign punish[i] = buf_rdata[BRAVO][(i+1)*DWIDTH-1:i*DWIDTH];
  end

  assign txn_start  = r_count_len == 0
                   && ( mode == M_INCR  && r_mode == M_IDLE
                     || mode == M_INCR  && r_mode == M_TRANS
                   );

  assign txn_stop   = mode == M_IDLE  && r_mode == M_INCR
                   || mode == M_TRANS && r_mode == M_INCR;

  always @(posedge clk)
    if (!xrst)
      r_mem_addr <= 0;
    else
      r_mem_addr <= mem_addr;

  always @(posedge clk)
    if (!xrst)
      r_mem_we <= 0;
    else
      r_mem_we <= mem_we;

  always @(posedge clk)
    if (!xrst)
      r_mem_wdata <= 0;
    else
      r_mem_wdata <= mem_wdata;

  reg signed [DWIDTH-1:0] r_mem_rdata;
  // assign mem_rdata = r_mem_rdata;

  assign mem_rdata  = r_mem_we          ? r_mem_wdata
                    : r_which == BOOT   ? boot[_fuga]
                    : r_which == ALPHA  ? crime[_fuga]
                    : r_which == BRAVO  ? punish[_fuga]
                    : 0;

  // always @(posedge clk)
  //   if (!xrst)
  //     r_mem_rdata <= 0;
  //   else
  //     case (r_which)
  //       BOOT:     r_mem_rdata <= pre_rdata;
  //       ALPHA:    r_mem_rdata <= buf_rdata[ALPHA];
  //       BRAVO:    r_mem_rdata <= buf_rdata[BRAVO];
  //       default:  r_mem_rdata <= 0;
  //     endcase

// }}}
//==========================================================
// ddr control
//==========================================================
// {{{

  assign ddr_req  = r_ddr_req;
  assign ddr_mode = r_ddr_mode;
  assign ddr_base = r_ddr_base;
  assign ddr_len  = r_ddr_len;

  assign ddr_rdata  = r_which == ALPHA  ? buf_rdata[BRAVO]
                    : r_which == BRAVO  ? buf_rdata[ALPHA]
                    : r_which == BOOT   ? pre_rdata
                    : 0;
  // reg signed [BWIDTH-1:0] r_ddr_rdata;
  // assign ddr_rdata = r_ddr_rdata;
  // always @(posedge clk)
  //   if (!xrst)
  //     r_ddr_rdata <= 0;
  //   else
  //     case (r_which)
  //       BOOT:
  //         r_ddr_rdata <= pre_rdata;
  //       ALPHA:
  //         r_ddr_rdata <= buf_rdata[BRAVO];
  //       BRAVO:
  //         r_ddr_rdata <= buf_rdata[ALPHA];
  //       default:
  //         r_ddr_rdata <= 0;
  //     endcase

  always @(posedge clk)
    if (!xrst)
      r_ddr_req <= 0;
    else
      case (r_state[0])
        S_IDLE:
          r_ddr_req <= 0;
        S_PREF:
          r_ddr_req <= s_pref_edge;
        S_READ:
          r_ddr_req <= s_read_edge || r_switch_buf;
        S_WRITE:
          r_ddr_req <= switch_buf;
        default:
          r_ddr_req <= 0;
      endcase

    // else if (s_pref_edge || s_read_edge)
    //   r_ddr_req <= 1;
    // else if (switch_buf)
    //   r_ddr_req <= 1;
    // else
    //   r_ddr_req <= 0;

  always @(posedge clk)
    if (!xrst)
      r_ddr_mode <= 0;
    else if (r_state[0] == S_PREF || r_state[0] == S_READ)
      r_ddr_mode <= DDR_READ;
    else if (r_state[0] == S_WRITE)
      r_ddr_mode <= DDR_WRITE;

  always @(posedge clk)
    if (!xrst)
      r_ddr_base <= 0;
    else
      case (r_state[0])
        S_IDLE:
          r_ddr_base <= 0;
        S_PREF:
          r_ddr_base <= r_base_addr;
        S_READ:
          case (r_which)
            ALPHA:    r_ddr_base <= r_mem_base[ALPHA] + BURST_LEN;
            BRAVO:    r_ddr_base <= r_mem_base[BRAVO] + BURST_LEN;
            BOOT:     r_ddr_base <= r_base_addr + BURST_LEN;
            default:  r_ddr_base <= 0;
          endcase
        S_WRITE:
          case (r_which)
            ALPHA:    r_ddr_base <= r_mem_base[ALPHA];
            BRAVO:    r_ddr_base <= r_mem_base[BRAVO];
            BOOT:     r_ddr_base <= r_base_addr;
            default:  r_ddr_base <= 0;
          endcase
        default:
          r_ddr_base <= 0;
      endcase

  assign my_new_length = r_count_len[LWIDTH-1:RATELOG] + |r_count_len[RATELOG-1:0];
  always @(posedge clk)
    if (!xrst)
      r_ddr_len <= 0;
    else if (0 < r_count_len && r_count_len < RATE * BURST_LEN)
      r_ddr_len <= my_new_length;
    else
      r_ddr_len <= BURST_LEN;

// }}}
//==========================================================
// prefetcher
//==========================================================
// {{{

  always @(posedge clk)
    if (!xrst)
      r_pref_len <= 0;
    else if (r_total_len < BURST_LEN)
      r_pref_len <= my_new_length;
    else
      r_pref_len <= BURST_LEN;

  assign s_pref_end = r_state[0] == S_PREF
                   && pre_we && pre_addr == r_pref_len - 1;

  assign pre_we     = r_which == BOOT ? r_state[0] == S_PREF ? ddr_we
                                      : 0//mem_we
                    : 0;
  assign pre_addr   = r_which == BOOT ? r_state[0] == S_PREF ? ddr_addr - r_base_addr
                                      : spagetti[BUFSIZE+RATELOG-1:RATELOG]
                    : 0;
  assign pre_wdata  = r_which == BOOT ? r_state[0] == S_PREF ? ddr_wdata
                                      : mem_wdata
                    : 0;

  mem_sp #(BWIDTH, BUFSIZE) mem_pre(
    .mem_we     (pre_we),
    .mem_addr   (pre_addr),
    .mem_wdata  (pre_wdata),
    .mem_rdata  (pre_rdata),
    .*
  );

// }}}
//==========================================================
// buffer control
//==========================================================
// {{{

  // assign switch_buf = r_mem_we && r_we_accum == RATE-1;
  // assign switch_buf = buf_we[r_which[0]] &&
  //                   ( r_count_len < RATE*BURST_LEN ? buf_addr[r_which[0]] == my_new_length-1
  //                                                  : buf_addr[r_which[0]] == BURST_LEN-1
  //                   );
  // assign switch_buf = r_switch_buf;
  assign switch_buf = r_count_inner == RATE * BURST_LEN - 1;
  always @(posedge clk)
    if (!xrst)
      r_switch_buf <= 0;
    else if (r_count_len > RATE*BURST_LEN && r_count_inner == RATE * BURST_LEN - 1)
      r_switch_buf <= 1;
    else
      r_switch_buf <= 0;

  always @(posedge clk)
    if (!xrst)
      r_we_accum <= 0;
    else if (r_mem_we)
      if (r_we_accum == RATE - 1)
        r_we_accum <= 0;
      else
        r_we_accum <= r_we_accum + 1;

  always @(posedge clk)
    if (!xrst)
      r_buf_we <= 0;
    else
      r_buf_we <= r_mem_we && r_we_accum == RATE-1;

  always @(posedge clk)
    if (!xrst)
      r_buf_addr <= 0;
    else if (r_state[0] == S_IDLE)
      r_buf_addr <= 0;
    else
      r_buf_addr <= r_mem_addr - r_mem_base[r_which[0]] - BURST_LEN * (RATE-1) * r_count_burst >> 1;

  always @(posedge clk)
    if (!xrst)
      r_buf_wdata <= 0;
    else
      r_buf_wdata <= {r_buf_wdata[BWIDTH-DWIDTH-1:0], r_mem_wdata};

  // one is for user interface, other is for ddr interface
  // roles switch for each burst
  assign mem_we_edge = mem_we && !r_mem_we;
  for (genvar i = 0; i < 2; i++) begin : hoge
    int j = (i+1) % 2;

    always @(posedge clk)
      if (!xrst)
        r_mem_base[i] <= 0;
      else if (r_mem_we && txn_start)
        r_mem_base[i] <= r_mem_addr;
      else if (!r_mem_we && txn_start)
        r_mem_base[i] <= r_mem_addr + BURST_LEN;
      else if (r_which == j && switch_buf)
        r_mem_base[i] <= r_mem_base[j] + BURST_LEN;

    if (i == ALPHA) begin
      assign buf_we[i]    = r_which == i    ? r_buf_we
                          : r_which == j    ? ddr_we
                          : r_which == BOOT ? r_state[0] != S_PREF ? ddr_we
                                                                   : 0
                          : 0;
      assign buf_addr[i]  = r_which == i    ? r_state[0] == S_READ  ? mem_addr - r_mem_base[i] - BURST_LEN * (RATE-1) * r_count_burst >> 1
                                                                    : r_buf_addr
                          : r_which == j    ? ddr_addr - r_mem_base[i]
                          : r_which == BOOT ? r_state[0] != S_PREF ? ddr_addr-r_mem_base[i]
                                                                   : 0
                          : 0;
      assign buf_wdata[i] = r_which == i    ? r_buf_wdata
                          : r_which == j    ? ddr_wdata
                          : r_which == BOOT ? r_state[0] != S_PREF ? ddr_wdata
                                                                   : 0
                          : 0;
    end
    else begin
      assign buf_we[i]    = r_which == i ? r_buf_we
                          : r_which == j ? ddr_we
                          : 0;
      assign buf_addr[i]  = r_which == i ? r_state[0] == S_READ ? mem_addr - r_mem_base[i] - BURST_LEN * (RATE-1) * r_count_burst >> 1
                                                                : r_buf_addr
                          : r_which == j ? ddr_addr - r_mem_base[i]
                          : 0;
      assign buf_wdata[i] = r_which == i ? r_buf_wdata
                          : r_which == j ? ddr_wdata
                          : 0;
    end

    mem_sp #(BWIDTH, BUFSIZE) mem_buf(
      .mem_we     (buf_we[i]),
      .mem_addr   (buf_addr[i]),
      .mem_wdata  (buf_wdata[i]),
      .mem_rdata  (buf_rdata[i]),
      .*
    );
  end : hoge

// }}}
endmodule

