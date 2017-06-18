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
  , input [BWIDTH-1:0]        ddr_rdata
  // m_axi signals
  , output                      ddr_req
  , output                      ddr_mode
  , output [IMGSIZE-1:0]        ddr_base
  , output [BWIDTH-1:0]         ddr_wdata
  // memory data
  , output signed [DWIDTH-1:0]  mem_rdata
  );

  localparam RATE = BWIDTH / DWIDTH;

  localparam ALPHA  = 'd0,
             BRAVO  = 'd1,
             PREBUF = 'd2,
             NONE   = 'd3;

  wire                      txn_start;
  wire                      txn_stop;
  wire [BUFSIZE-1:0]        addr_diff;
  wire                      buf_we    [1:0];
  wire [BUFSIZE-1:0]        buf_addr  [1:0];
  wire signed [BWIDTH-1:0]  buf_wdata [1:0];
  wire [BWIDTH-1:0]         buf_rdata [1:0];

  enum reg [1:0] {
    S_IDLE, S_PREF, S_READ, S_WRITE
  } r_state [1:0];
  enum reg [1:0] {
    M_IDLE, M_INCR, M_TRANS
  } r_mode [1:0];
  reg [1:0] r_which;
  reg [RATE-1:0]          r_we_accum;
  reg [LWIDTH-1:0]        r_total_len;
  reg                     r_mem_we;
  reg [IMGSIZE-1:0]       r_mem_addr;
  reg signed [DWIDTH-1:0] r_mem_wdata;
  reg [IMGSIZE-1:0]       r_mem_base [1:0];
  reg                     r_buf_we;
  reg signed [BWIDTH-1:0] r_buf_wdata;

  /*
   * When ddr_req asserts, ddr_mode and ddr_base are fetched.
   * Then m_axi starts streaming with ddr_stream channel.
   * The ddr_stream represents both reading and writing data stream
   * in context of ddr_mode.
   */

//==========================================================
// core control
//==========================================================

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
              if (prefetch_en)
                r_state[0] <= S_PREF;
              else if (mem_we)
                r_state[0] <= S_WRITE;
            S_PREF:
              if (s_pref_end)
                r_state[0] <= S_READ;
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

  for (genvar i = 0; i < 2; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst)
          r_mode[0] <= M_IDLE;
        else
          case (addr_diff)
            0:
              r_mode[0] <= M_IDLE;
            1:
              r_mode[0] <= M_INCR;
            default:
              r_mode[0] <= M_TRANS;
          endcase
    else
      always @(posedge clk)
        if (!xrst)
          r_mode[i] <= M_IDLE;
        else
          r_mode[i] <= r_mode[i-1];

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

//==========================================================
// memory control
//==========================================================

  assign txn_start  = r_mode[0] == M_INCR  && r_mode[1] == M_IDLE
                   || r_mode[0] == M_INCR  && r_mode[1] == M_TRANS;

  assign txn_stop   = r_mode[0] == M_IDLE  && r_mode[1] == M_INCR
                   || r_mode[0] == M_TRANS && r_mode[1] == M_INCR;

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

  assign mem_rdata = r_mem_rdata;

  always @(posedge clk)
    if (!xrst)
      r_mem_rdata <= 0;
    else
      case (r_which)
        NONE:
          r_mem_rdata <= 0;
        PREBUF:
          r_mem_rdata <= pre_rdata;
        ALPHA:
          r_mem_rdata <= buf_rdata[ALPHA];
        BRAVO:
          r_mem_rdata <= buf_rdata[BRAVO];
        default:
          r_mem_rdata <= 0;
      endcase

//==========================================================
// ddr control
//==========================================================

  assign ddr_req = r_ddr_req;
  assign ddr_mode = r_ddr_mode;
  assign ddr_base = r_ddr_base;

  assign ddr_wdata  = r_which == ALPHA   ? buf_rdata[ALPHA]
                    : r_which == BRAVO   ? buf_rdata[BRAVO]
                    : r_which == PREBUF  ? pre_rdata
                    : r_which == NONE    ? 0
                    : 0;

  assign s_pref_edge = r_state[0] == S_PREF && r_state[1] != S_PREF;
  always @(posedge clk)
    if (!xrst)
      r_ddr_req <= 0;
    else if (s_pref_edge)
      r_ddr_req <= 1;
    else if (switch_buf)
      r_ddr_req <= 1;
    else
      r_ddr_req <= 0;

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
          r_ddr_base <= base_addr;
        S_READ:
        S_WRITE:
          case (r_which)
            NONE:
              r_ddr_base <= 0;
            PREBUF:
              r_ddr_base <= base_addr;
            ALPHA:
              r_ddr_base <= r_mem_base[ALPHA];
            BRAVO:
              r_ddr_base <= r_mem_base[BRAVO];
            default:
              r_ddr_base <= 0;
          endcase
        default:
          r_ddr_base <= 0;
      endcase
    else if (r_state[0] == S_PREF || r_state[0] == S_WRITE)
      r_ddr_base <= base_addr;

//==========================================================
// prefetcher
//==========================================================

  assign s_pref_end = r_state[0] == S_PREF
                   && pre_addr == r_base_addr + BURST_LEN;

  assign pre_we     = r_state[0] == S_PREF ? ddr_we    : 0;
  assign pre_addr   = r_state[0] == S_PREF ? ddr_addr  : 0;
  assign pre_wdata  = r_state[0] == S_PREF ? ddr_wdata : 0;

  mem_sp #(BWIDTH, $clog2(BURST_LEN)) mem_pre(
    .mem_we     (pre_we),
    .mem_addr   (pre_addr),
    .mem_wdata  (pre_wdata),
    .mem_rdata  (pre_rdata),
    .*
  );

//==========================================================
// buffer control
//==========================================================

  always @(posedge clk)
    if (!xrst)
      r_which <= NONE;
    else
      case (r_which)
        NONE:
          if (prefetch_en)
            r_which <= PREBUF;
          else if (mem_we)
            r_which <= ALPHA;

        PREBUF:
          if (pref_read_end)
            r_which <= ALPHA;

        ALPHA:
          if (s_read_end || s_write_end)
            r_which <= NONE;
          else if (switch_buf)
            r_which <= BRAVO;

        BRAVO:
          if (s_read_end || s_write_end)
            r_which <= NONE;
          else if (switch_buf)
            r_which <= ALPHA;

        default:
          r_which <= NONE;
      endcase

  // r_which indicates which buffer is for user interface
  // always @(posedge clk)
  //   if (!xrst)
  //     r_which <= 0;
  //   else if (buf_we[r_which] && buf_addr[r_which] == BURST_LEN-1)
  //     r_which <= ~r_which;

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
    else if (r_we_accum == RATE-1)
      r_buf_we <= r_mem_we;
    else
      r_buf_we <= 0;

  always @(posedge clk)
    if (!xrst)
      r_buf_wdata <= 0;
    else
      r_buf_wdata <= {r_buf_wdata[BWIDTH-DWIDTH-1:0], r_mem_wdata};

  // one is for user interface, other is for ddr interface
  // roles switch for each burst
  for (genvar i = 0; i < 2; i++) begin
    always @(posedge clk)
      if (!xrst)
        r_mem_base[i] <= 0;
      else if (r_which == i) begin
        if (!txn_start && r_mode[0] != M_INCR)
          r_mem_base[i] <= mem_addr;
      end
      else
        if (buf_we[(i+1)%2] && buf_addr[r_which] == BURST_LEN-1)
          r_mem_base[i] <= mem_addr;

    assign buf_we[i]    = r_which == i ? r_buf_we : 0;
    assign buf_addr[i]  = r_which == i ? r_mem_addr - r_mem_base[i] >> 1 : 0;
    assign buf_wdata[i] = r_which == i ? r_buf_wdata : 0;

    mem_sp #(BWIDTH, $clog2(BURST_LEN)) mem_buf(
      .mem_we     (buf_we[i]),
      .mem_addr   (buf_addr[i]),
      .mem_wdata  (buf_wdata[i]),
      .mem_rdata  (buf_rdata[i]),
      .*
    );
  end

endmodule

