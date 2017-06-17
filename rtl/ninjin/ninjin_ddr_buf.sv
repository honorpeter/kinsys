`include "ninjin.svh"

/* TODO:
 *  - Implement prefetch mode (r_state[0] == S_TRANS && r_state[1] == S_INCR)
 *  - Pass proper signals to S_AXI interface
 *  - Implement double buffering scheme with DWIDTH-BWIDTH convert.
 */

module ninjin_ddr_buf
  ( input                     clk
  , input                     xrst
  , input [LWIDTH-1:0]        total_len
  , input                     mem_we
  , input [IMGSIZE-1:0]       mem_addr
  , input signed [DWIDTH-1:0] mem_wdata
  , input                     ddr_we
  , input [IMGSIZE-1:0]       ddr_addr
  , input [BWIDTH-1:0]        ddr_rdata
  , output                      ddr_req
  , output                      ddr_mode
  , output [IMGSIZE-1:0]        ddr_base
  , output [BWIDTH-1:0]         ddr_wdata
  , output signed [DWIDTH-1:0]  mem_rdata
  );

  localparam RATE = BWIDTH / DWIDTH;

  wire                      txn_start;
  wire                      txn_stop;
  wire [MEMSIZE-1:0]        addr_diff;
  wire                      buf_we    [1:0];
  wire [MEMSIZE-1:0]        buf_addr  [1:0];
  wire signed [BWIDTH-1:0]  buf_wdata [1:0];
  wire [BWIDTH-1:0]         buf_rdata [1:0];

  enum reg [1:0] {
    S_IDLE, S_INCR, S_TRANS
  } r_state [1:0];
  reg                     r_turn;
  reg [RATE-1:0]          r_we_accum;
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

  always @(posedge clk)
    if (!xrst)
      r_state[0] <= S_IDLE;
    else
      case (addr_diff)
        0:
          r_state[0] <= S_IDLE;
        1:
          r_state[0] <= S_INCR;
        default:
          r_state[0] <= S_TRANS;
      endcase

  always @(posedge clk)
    if (!xrst)
      r_state[1] <= S_IDLE;
    else
      r_state[1] <= r_state[0];

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

//==========================================================
// memory control
//==========================================================

  assign txn_start  = r_state[0] == S_INCR  && r_state[1] == S_IDLE
                   || r_state[0] == S_INCR  && r_state[1] == S_TRANS;

  assign txn_stop   = r_state[0] == S_IDLE  && r_state[1] == S_INCR
                   || r_state[0] == S_TRANS && r_state[1] == S_INCR;

  reg signed [DWIDTH-1:0] r_mem_rdata;
  assign mem_rdata = r_mem_rdata;
  always @(posedge clk)
    if (!xrst)
      r_mem_rdata <= 0;
    else if (mem_we)
      r_mem_rdata <= mem_wdata;
    else
      r_mem_rdata <= 0;

//==========================================================
// ddr control
//==========================================================

//==========================================================
// buffer control
//==========================================================

  // r_turn indicates which buffer is for user interface
  always @(posedge clk)
    if (!xrst)
      r_turn <= 0;
    else if (buf_we[r_turn] && buf_addr[r_turn] == BURST_LEN-1)
      r_turn <= ~r_turn;

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
      r_buf_wdata <= 0;
    else
      r_buf_wdata <= {r_buf_wdata[BWIDTH-DWIDTH-1:0], r_mem_wdata};

  // one is for user interface, other is for ddr interface
  // roles switch for each burst
  for (genvar i = 0; i < 2; i++) begin
    always @(posedge clk)
      if (!xrst)
        r_mem_base[i] <= 0;
      else if (r_turn == i) begin
        if (!txn_start && r_state[0] != S_INCR)
          r_mem_base[i] <= mem_addr;
      end
      else
        if (buf_we[(i+1)%2] && buf_addr[r_turn] == BURST_LEN-1)
          r_mem_base[i] <= mem_addr;

    assign buf_we[i]    = r_turn == i ? r_buf_we : 0;
    assign buf_addr[i]  = r_turn == i ? r_mem_addr - r_mem_base[i] >> 1 : 0;
    assign buf_wdata[i] = r_turn == i ? r_buf_wdata : 0;

    mem_sp #(BWIDTH, $clog2(BURST_LEN)) mem_buf(
      .mem_we     (buf_we[i]),
      .mem_addr   (buf_addr[i]),
      .mem_wdata  (buf_wdata[i]),
      .mem_rdata  (buf_rdata[i]),
      .*
    );
  end

  mem_sp #(BWIDTH, $clog2(BURST_LEN)) mem_pre(
    .mem_we     (buf_we[i]),
    .mem_addr   (buf_addr[i]),
    .mem_wdata  (buf_wdata[i]),
    .mem_rdata  (buf_rdata[i]),
    .*
  );

endmodule

