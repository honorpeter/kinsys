`include "ninjin.svh"

module ninjin_ddr_buf
  ( input                     clk
  , input                     xrst
  // Meta inputs
  , input                     prefetch
  , input [IMGSIZE-1:0]       base_addr
  , input [LWIDTH-1:0]        total_len
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

  localparam  RATE = BWIDTH / DWIDTH;
  localparam  RATELOG = $clog2(RATE);

  localparam  M_IDLE  = 0,
              M_INCR  = 1,
              M_TRANS = 2;

  // localparam  ALPHA  = 'd0,
  //             BRAVO  = 'd1,
  //             BOOT   = 'd2;
  typedef enum reg [1:0] {
    ALPHA=0, BRAVO=1, BOOT=2
  } reg_which;

  wire                        s_pref_end;
  wire                        s_read_end;
  wire                        s_write_end;
  wire                        s_pref_edge;
  wire                        s_read_edge;
  wire                        s_write_edge;
  wire [1:0]                  mode;
  wire                        txn_start;
  wire                        txn_stop;
  wire                        pre_we;
  wire [BUFSIZE-1:0]          pre_addr;
  wire signed [BWIDTH-1:0]    pre_wdata;
  wire [BWIDTH-1:0]           pre_rdata;
  wire                        buf_we    [1:0];
  wire [BUFSIZE-1:0]          buf_addr  [1:0];
  wire signed [BWIDTH-1:0]    buf_wdata [1:0];
  wire [BWIDTH-1:0]           buf_rdata [1:0];
  wire                        switch_buf;
  wire signed [IMGSIZE-1:0]   addr_diff;
  wire signed [LWIDTH-1:0]    len_diff;
  wire [BUFSIZE+RATELOG-1:0]  addr_offset;
  wire [RATELOG-1:0]          word_offset;
  wire signed [DWIDTH-1:0]    boot  [RATE-1:0];
  wire signed [DWIDTH-1:0]    alpha [RATE-1:0];
  wire signed [DWIDTH-1:0]    bravo [RATE-1:0];
  wire                        mem_we_edge;
  wire [LWIDTH-1:0]           rest_len;

  enum reg [1:0] {
    S_IDLE=0, S_PREF=1, S_READ=2, S_WRITE=3
  } r_state [1:0];
  // enum reg [1:0] {
  //   ALPHA=0, BRAVO=1, BOOT=2
  // } r_which [1:0];
  reg_which               r_which [1:0];
  reg [1:0]               r_mode;
  reg                     r_mem_we;
  reg [IMGSIZE-1:0]       r_mem_addr;
  reg signed [DWIDTH-1:0] r_mem_wdata;
  reg [LWIDTH-1:0]        r_mem_diff;
  reg                     r_ddr_req;
  reg                     r_ddr_mode;
  reg [IMGSIZE-1:0]       r_ddr_base;
  reg [LWIDTH-1:0]        r_ddr_len;
  reg                     r_buf_we;
  reg [IMGSIZE-1:0]       r_buf_addr;
  reg signed [BWIDTH-1:0] r_buf_wdata;
  reg [IMGSIZE-1:0]       r_buf_base [1:0];
  reg [RATE-1:0]          r_we_accum;
  reg [LWIDTH-1:0]        r_total_len;
  reg [LWIDTH-1:0]        r_count_len;
  reg [LWIDTH-1:0]        r_count_inner;
  reg [LWIDTH-1:0]        r_pref_len;
  reg [IMGSIZE-1:0]       r_base_addr;
  reg                     r_switch_buf;
  reg_which               r_first_buf;
  reg [RATELOG-1:0]       r_word_offset;

  /*
   * When ddr_req asserts, ddr_mode and ddr_base are fetched.
   * Then m_axi starts streaming with ddr_stream channel.
   * The ddr_stream represents both reading and writing data stream
   * in context of ddr_mode.
   */

//==========================================================
// core control
//==========================================================
// {{{

  assign s_pref_end  = r_state[0] == S_PREF
                    && pre_we && pre_addr == r_pref_len - 1;
  assign s_read_end  = r_state[0] == S_READ
                    && r_count_len != 0 && r_count_inner == r_count_len;
  assign s_write_end = r_state[0] == S_WRITE
                    && r_count_len != 0 && r_count_inner == r_count_len;

  assign s_pref_edge  = r_state[0] == S_PREF  && r_state[1] != S_PREF;
  assign s_read_edge  = r_state[0] == S_READ  && r_state[1] != S_READ;
  assign s_write_edge = r_state[0] == S_WRITE && r_state[1] != S_WRITE;

  assign mode = addr_diff == 0 ? M_IDLE
              : addr_diff == 1 ? M_INCR
              : M_TRANS;

  assign addr_diff = mem_addr - r_mem_addr;
  assign len_diff  = total_len - r_total_len;

  for (genvar i = 0; i < 2; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst)
          r_state[0] <= S_IDLE;
        else
          case (r_state[0])
            S_IDLE:
              if (prefetch)
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

  always @(posedge clk)
    if (!xrst)
      r_mode <= M_IDLE;
    else
      r_mode <= mode;

  for (genvar i = 0; i < 2; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst)
          r_which[0] <= BOOT;
        else
          case (r_which[0])
            BOOT:
              // if (s_write_edge)
              if (txn_start && mem_we)
                r_which[0] <= r_first_buf;
              else if (switch_buf)
                r_which[0] <= r_first_buf;

            ALPHA:
              if (s_read_end || s_write_end)
                r_which[0] <= BOOT;
              else if (switch_buf)
                r_which[0] <= BRAVO;
              else if (s_pref_edge)
                r_which[0] <= BOOT;

            BRAVO:
              if (s_read_end || s_write_end)
                r_which[0] <= BOOT;
              else if (switch_buf)
                r_which[0] <= ALPHA;
              else if (s_pref_edge)
                r_which[0] <= BOOT;

            default:
              r_which[0] <= BOOT;
          endcase
    else
      always @(posedge clk)
        if (!xrst)
          r_which[i] <= BOOT;
        else
          r_which[i] <= r_which[i-1];

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
      r_mem_diff <= 0;
    else if (r_state[0] == S_IDLE)
      r_mem_diff <= 0;
    else if (switch_buf)
      r_mem_diff <= r_mem_diff + BURST_LEN * (RATE-1);

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
            r_count_inner <= r_count_inner + txn_start + (addr_diff == 1 ? 1 : 0);
      endcase

// }}}
//==========================================================
// memory control
//==========================================================
// {{{

  assign mem_we_edge  = mem_we && !r_mem_we;
  assign addr_offset  = mem_addr - r_base_addr;
  assign word_offset  = addr_offset[RATELOG-1:0];

  assign txn_start  = r_count_len == 0
                   && ( mode == M_INCR  && r_mode == M_IDLE
                     || mode == M_INCR  && r_mode == M_TRANS
                   );

  assign txn_stop   = mode == M_IDLE  && r_mode == M_INCR
                   || mode == M_TRANS && r_mode == M_INCR;

  for (genvar i = 0; i < RATE; i++) begin
    assign boot[i]  = pre_rdata[(i+1)*DWIDTH-1:i*DWIDTH];
    assign alpha[i] = buf_rdata[ALPHA][(i+1)*DWIDTH-1:i*DWIDTH];
    assign bravo[i] = buf_rdata[BRAVO][(i+1)*DWIDTH-1:i*DWIDTH];
  end

  always @(posedge clk)
    if (!xrst)
      r_word_offset <= 0;
    else
      r_word_offset <= word_offset;

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


  assign mem_rdata  = r_mem_we            ? r_mem_wdata
                    : r_which[1] == BOOT  ? boot[r_word_offset]
                    : r_which[1] == ALPHA ? alpha[r_word_offset]
                    : r_which[1] == BRAVO ? bravo[r_word_offset]
                    : 0;

// }}}
//==========================================================
// ddr control
//==========================================================
// {{{

  assign ddr_req  = r_ddr_req;
  assign ddr_mode = r_ddr_mode;
  assign ddr_base = r_ddr_base;
  assign ddr_len  = r_ddr_len;

  assign ddr_rdata  = r_which[1] == ALPHA ? buf_rdata[BRAVO]
                    : r_which[1] == BRAVO ? buf_rdata[ALPHA]
                    : r_which[1] == BOOT  ? pre_rdata
                    : 0;

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
          r_ddr_req <= s_read_edge
                    || RATE*BURST_LEN < r_count_len && r_switch_buf;
        S_WRITE:
          r_ddr_req <= switch_buf;
        default:
          r_ddr_req <= 0;
      endcase

  always @(posedge clk)
    if (!xrst)
      r_ddr_mode <= 0;
    else
      case (r_state[0])
        S_IDLE:
          r_ddr_mode <= 0;
        S_PREF:
          r_ddr_mode <= DDR_READ;
        S_READ:
          r_ddr_mode <= DDR_READ;
        S_WRITE:
          r_ddr_mode <= DDR_WRITE;
        default:
          r_ddr_mode <= 0;
      endcase

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
          case (r_which[0])
            ALPHA:    r_ddr_base <= r_buf_base[ALPHA] + BURST_LEN;
            BRAVO:    r_ddr_base <= r_buf_base[BRAVO] + BURST_LEN;
            BOOT:     r_ddr_base <= r_base_addr       + BURST_LEN;
            default:  r_ddr_base <= 0;
          endcase
        S_WRITE:
          case (r_which[0])
            ALPHA:    r_ddr_base <= r_buf_base[ALPHA];
            BRAVO:    r_ddr_base <= r_buf_base[BRAVO];
            BOOT:     r_ddr_base <= r_base_addr;
            default:  r_ddr_base <= 0;
          endcase
        default:
          r_ddr_base <= 0;
      endcase

  assign rest_len = r_count_len - RATE*BURST_LEN;
  always @(posedge clk)
    if (!xrst)
      r_ddr_len <= 0;
    else
      case (r_state[0])
        S_IDLE:
          r_ddr_len <= 0;
        S_PREF:
          if (0 < r_count_len && r_count_len <= RATE*BURST_LEN)
            r_ddr_len <= r_count_len[LWIDTH-1:RATELOG] + |r_count_len[RATELOG-1:0];
          else
            r_ddr_len <= BURST_LEN;
        S_READ:
          if (RATE*BURST_LEN < r_count_len && r_count_len <= 2*RATE*BURST_LEN)
            r_ddr_len <= rest_len[LWIDTH-1:RATELOG] + |rest_len[RATELOG-1:0];
          else
            r_ddr_len <= BURST_LEN;
        S_WRITE:
          if (0 < r_count_len && r_count_len <= RATE*BURST_LEN)
            r_ddr_len <= r_count_len[LWIDTH-1:RATELOG] + |r_count_len[RATELOG-1:0];
          else
            r_ddr_len <= BURST_LEN;
        default:
          r_ddr_len <= 0;
      endcase

// }}}
//==========================================================
// prefetcher
//==========================================================
// {{{

  assign pre_we     = gen_pre_we(mem_we, ddr_we);
  assign pre_addr   = gen_pre_addr(mem_addr, ddr_addr, r_base_addr);
  assign pre_wdata  = gen_pre_wdata(mem_wdata, ddr_wdata);

  always @(posedge clk)
    if (!xrst)
      r_pref_len <= 0;
    else if (r_total_len < BURST_LEN)
      r_pref_len <= rest_len;
    else
      r_pref_len <= BURST_LEN;

  mem_sp #(BWIDTH, BUFSIZE) mem_pre(
    .mem_we     (pre_we),
    .mem_addr   (pre_addr),
    .mem_wdata  (pre_wdata),
    .mem_rdata  (pre_rdata),
    .*
  );

  function gen_pre_we
    ( input mem_we
    , input ddr_we
    );

    case (r_which[0])
      BOOT:
        if (r_state[0] == S_PREF)
          gen_pre_we = ddr_we;
        else
          // gen_pre_we = mem_we;
          gen_pre_we = 0;
      default:
        gen_pre_we = 0;
    endcase
  endfunction

  function [BUFSIZE-1:0] gen_pre_addr
    ( input [IMGSIZE-1:0] mem_addr
    , input [IMGSIZE-1:0] ddr_addr
    , input [IMGSIZE-1:0] r_base_addr
    );

    case (r_which[0])
      BOOT:
        if (r_state[0] == S_PREF)
          gen_pre_addr = ddr_addr - r_base_addr;
        else
          gen_pre_addr = mem_addr - r_base_addr >> RATELOG;
      default:
        gen_pre_addr = 0;
    endcase
  endfunction

  function signed [BWIDTH-1:0] gen_pre_wdata
    ( input signed [DWIDTH-1:0] mem_wdata
    , input signed [BWIDTH-1:0] ddr_wdata
    );

    case (r_which[0])
      BOOT:
        if (r_state[0] == S_PREF)
          gen_pre_wdata = ddr_wdata;
        else
          gen_pre_wdata = mem_wdata;
      default:
        gen_pre_wdata = 0;
    endcase
  endfunction

// }}}
//==========================================================
// buffer control
//==========================================================
// {{{

  assign switch_buf = r_count_len > RATE*BURST_LEN
                   && r_count_inner == RATE * BURST_LEN - 1;
  // assign switch_buf = r_switch_buf;

  always @(posedge clk)
    if (!xrst)
      r_switch_buf <= 0;
    else if (r_count_len > RATE*BURST_LEN && r_count_inner == RATE * BURST_LEN - 1)
      r_switch_buf <= 1;
    else
      r_switch_buf <= 0;

  always @(posedge clk)
    if (!xrst)
      r_first_buf <= ALPHA;
    else if (s_write_end)
      case (r_which[0])
        ALPHA:    r_first_buf <= BRAVO;
        BRAVO:    r_first_buf <= ALPHA;
        default:  r_first_buf <= ALPHA;
      endcase

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
      r_buf_addr <= r_mem_addr - (r_buf_base[r_which[0][0]] + r_mem_diff)
                 >> RATELOG;

  always @(posedge clk)
    if (!xrst)
      r_buf_wdata <= 0;
    else
      r_buf_wdata <= {r_buf_wdata[BWIDTH-DWIDTH-1:0], r_mem_wdata};

  // one is for user interface, other is for ddr interface
  // roles switch for each burst
  for (genvar i = 0; i < 2; i++) begin : double
    assign buf_we[i]    = gen_buf_we(i, r_buf_we, ddr_we);
    assign buf_addr[i]  = gen_buf_addr(i, r_buf_addr, ddr_addr, mem_addr, r_buf_base, r_mem_diff);
    assign buf_wdata[i] = gen_buf_wdata(i, r_buf_wdata, ddr_wdata);

    always @(posedge clk)
      if (!xrst)
        r_buf_base[i] <= 0;
      else if (r_mem_we && txn_start)
        r_buf_base[i] <= r_mem_addr;
      else if (!r_mem_we && txn_start)
        r_buf_base[i] <= r_mem_addr + BURST_LEN;
      else if (r_which[0] == reg_which'((i+1)%2) && switch_buf)
        r_buf_base[i] <= r_buf_base[(i+1)%2] + BURST_LEN;

    mem_sp #(BWIDTH, BUFSIZE) mem_buf(
      .mem_we     (buf_we[i]),
      .mem_addr   (buf_addr[i]),
      .mem_wdata  (buf_wdata[i]),
      .mem_rdata  (buf_rdata[i]),
      .*
    );
  end : double

  function gen_buf_we
    ( input integer i
    , input r_buf_we
    , input ddr_we
    );

    if (reg_which'(i) == ALPHA)
      case (r_which[0])
        ALPHA:
          gen_buf_we = r_buf_we;
        BRAVO:
          gen_buf_we = ddr_we;
        BOOT:
          if (r_first_buf == ALPHA && r_state[0] != S_PREF)
            gen_buf_we = ddr_we;
          else
            gen_buf_we = 0;
        default:
          gen_buf_we = 0;
      endcase
    else
      case (r_which[0])
        BRAVO:
          gen_buf_we = r_buf_we;
        ALPHA:
          gen_buf_we = ddr_we;
        BOOT:
          if (r_first_buf == BRAVO && r_state[0] != S_PREF)
            gen_buf_we = ddr_we;
          else
            gen_buf_we = 0;
        default:
          gen_buf_we = 0;
      endcase
  endfunction

  function [BUFSIZE-1:0] gen_buf_addr
    ( input integer i
    , input [BUFSIZE-1:0] r_buf_addr
    , input [IMGSIZE-1:0] ddr_addr
    , input [IMGSIZE-1:0] mem_addr
    , input [IMGSIZE-1:0] r_buf_base [1:0]
    , input [LWIDTH-1:0]  r_mem_diff
    );

    if (reg_which'(i) == ALPHA)
      case (r_which[0])
        ALPHA:
          if (r_state[0] == S_READ)
            gen_buf_addr = mem_addr - (r_buf_base[i] + r_mem_diff) >> RATELOG;
          else
            gen_buf_addr = r_buf_addr;
        BRAVO:
          gen_buf_addr = ddr_addr - r_buf_base[i];
        BOOT:
          if (r_first_buf == ALPHA && r_state[0] != S_PREF)
            gen_buf_addr = ddr_addr - r_buf_base[i];
          else
            gen_buf_addr = 0;
        default:
          gen_buf_addr = 0;
      endcase
    else
      case (r_which[0])
        BRAVO:
          if (r_state[0] == S_READ)
            gen_buf_addr = mem_addr - (r_buf_base[i] + r_mem_diff) >> RATELOG;
          else
            gen_buf_addr = r_buf_addr;
        ALPHA:
          gen_buf_addr = ddr_addr - r_buf_base[i];
        BOOT:
          if (r_first_buf == BRAVO && r_state[0] != S_PREF)
            gen_buf_addr = ddr_addr - r_buf_base[i];
          else
            gen_buf_addr = 0;
        default:
          gen_buf_addr = 0;
      endcase
  endfunction

  function signed [BWIDTH-1:0] gen_buf_wdata
    ( input integer i
    , input [BWIDTH-1:0] r_buf_wdata
    , input [BWIDTH-1:0] ddr_wdata
    );

    if (reg_which'(i) == ALPHA)
      case (r_which[0])
        ALPHA:
          gen_buf_wdata = r_buf_wdata;
        BRAVO:
          gen_buf_wdata = ddr_wdata;
        BOOT:
          if (r_first_buf == ALPHA && r_state[0] != S_PREF)
            gen_buf_wdata = ddr_wdata;
          else
            gen_buf_wdata = 0;
        default:
          gen_buf_wdata = 0;
      endcase
    else
      case (r_which[0])
        BRAVO:
          gen_buf_wdata = r_buf_wdata;
        ALPHA:
          gen_buf_wdata = ddr_wdata;
        BOOT:
          if (r_first_buf == BRAVO && r_state[0] != S_PREF)
            gen_buf_wdata = ddr_wdata;
          else
            gen_buf_wdata = 0;
        default:
          gen_buf_wdata = 0;
      endcase
  endfunction

// }}}
endmodule

