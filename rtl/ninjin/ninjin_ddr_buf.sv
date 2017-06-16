`include "ninjin.svh"

/* TODO:
 *  - Implement prefetch mode (when mode == M_TRANS && r_mode == M_INCR)
 *  - Pass proper signals to M_AXI interface
 *  - Implement double buffering scheme with DWIDTH-BWIDTH convert.
 */

module ninjin_ddr_buf
  ( input                     clk
  , input                     xrst
  , input [LWIDTH-1:0]        total_len
  , input                     mem_we
  , input [IMGSIZE-1:0]       mem_addr
  , input signed [DWIDTH-1:0] mem_wdata
  , input [BWIDTH-1:0]        ddr_rdata
  , output                      ddr_we
  , output                      ddr_re
  , output [IMGSIZE-1:0]        ddr_addr
  , output [BWIDTH-1:0]         ddr_wdata
  , output signed [DWIDTH-1:0]  mem_rdata
  );

  localparam RATE = BWIDTH / DWIDTH;

  localparam  M_IDLE  = 'd0,
              M_INCR  = 'd1,
              M_TRANS = 'd2;

  wire [1:0]                mode;
  wire                      buf_we    [1:0];
  wire [MEMSIZE-1:0]        buf_addr  [1:0];
  wire signed [BWIDTH-1:0]  buf_wdata [1:0];
  wire [BWIDTH-1:0]         buf_rdata [1:0];
  wire [MEMSIZE-1:0]        addr_diff;
  wire                      txn_start;
  wire                      txn_stop;

  reg [1:0]               r_mode;
  reg                     r_turn;
  reg                     r_ddr_we;
  reg                     r_ddr_re;
  reg [IMGSIZE-1:0]       r_ddr_addr;
  reg [BWIDTH-1:0]        r_ddr_wdata;
  reg                     r_buf_we    [1:0];
  reg [MEMSIZE-1:0]       r_buf_addr  [1:0];
  reg signed [BWIDTH-1:0] r_buf_wdata [1:0];
  reg [BWIDTH-1:0]        r_buf_rdata [1:0];
  reg [DWIDTH-1:0]        r_we [RATE-1:0];
  reg [DWIDTH-1:0]        r_wdata [RATE-1:0];
  reg [IMGSIZE-1:0]       r_mem_addr;
  reg [DWIDTH-1:0]        r_mem_rdata;

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
      r_mem_addr <= 0;
    else
      r_mem_addr <= mem_addr;

  assign mode = addr_diff == 0 ? M_IDLE
              : addr_diff == 1 ? M_INCR
              : M_TRANS;

  always @(posedge clk)
    if (!xrst)
      r_mode <= 0;
    else
      r_mode <= mode;

//==========================================================
// memory control
//==========================================================

  assign txn_start  = mode == M_INCR  && r_mode == M_IDLE
                   || mode == M_INCR  && r_mode == M_TRANS;
  assign txn_stop   = mode == M_IDLE  && r_mode == M_INCR
                   || mode == M_TRANS && r_mode == M_INCR;

  for (genvar i = 0; i < RATE; i++)
    if (i == 0) begin
      always @(posedge clk)
        if (!xrst)
          r_wdata[0] <= 0;
        else
          r_wdata[0] <= mem_wdata;
    end
    else begin
      always @(posedge clk)
        if (!xrst)
          r_wdata[i] <= 0;
        else
          r_wdata[i] <= r_wdata[i-1];
    end

  for (genvar i = 0; i < RATE; i++)
    if (i == 0) begin
      always @(posedge clk)
        if (!xrst)
          r_we[0] <= 0;
        else
          r_we[0] <= mem_we;
    end
    else begin
      always @(posedge clk)
        if (!xrst)
          r_we[i] <= 0;
        else
          r_we[i] <= r_we[i-1];
    end

  assign mem_rdata = r_mem_rdata;

  always @(posedge clk)
    if (!xrst)
      r_mem_rdata <= 0;

//==========================================================
// ddr control
//==========================================================

  assign ddr_we     = r_ddr_we;
  assign ddr_re     = r_ddr_re;
  assign ddr_addr   = r_ddr_addr;
  assign ddr_wdata  = r_ddr_wdata;

  always @(posedge clk)
    if (!xrst)
      r_ddr_we <= 0;
    else if (txn_start)
      r_ddr_we <= mem_we;

  always @(posedge clk)
    if (!xrst)
      r_ddr_re <= 0;
    else if (txn_start)
      r_ddr_re <= !mem_we;

  always @(posedge clk)
    if (!xrst)
      r_ddr_addr <= 0;
    else if (txn_start)
      r_ddr_addr <= r_mem_addr;

  always @(posedge clk)
    if (!xrst)
      r_ddr_wdata <= 0;
    else
      r_ddr_wdata <= buf_rdata[!r_turn];

//==========================================================
// buffer control
//==========================================================

  // r_turn indicates which buffer is for user interface
  always @(posedge clk)
    if (!xrst)
      r_turn <= 0;
    else if (txn_stop)
      r_turn <= ~r_turn;

  assign buf_we    = r_buf_we;
  assign buf_addr  = r_buf_addr;
  assign buf_wdata = r_buf_wdata;

  // for (genvar i = 0; i < 2; i++) begin
  //   assign buf_we   [i] = 0;
  //   assign buf_addr [i] = 0;
  //   assign buf_wdata[i] = 0;
  // end

  // one is for user interface, other is for ddr interface
  // roles switch for each burst
  for (genvar i = 0; i < 2; i++) begin
    always @(posedge clk)
      if (!xrst)
        r_buf_we[i] <= 0;
      else if (r_turn == i)
        r_buf_we[i] <= r_we[1] && r_we[0];
      else
        r_buf_we[i] <= 0;

    always @(posedge clk)
      if (!xrst)
        r_buf_addr[i] <= 0;
      else if (r_turn == i)
        r_buf_addr[i] <= mem_addr - r_ddr_addr;
      else
        r_buf_addr[i] <= 0;

    always @(posedge clk)
      if (!xrst)
        r_buf_wdata[i] <= 0;
      else if (r_turn == i)
        // TODO: How to switch concat description for 32bit and 64bit?
        r_buf_wdata[i] <= {r_wdata[1], r_wdata[0]};
      else
        r_buf_wdata[i] <= 0;

    mem_sp #(BWIDTH, $clog2(BURST_LEN)) mem_buf(
      .mem_we     (buf_we[i]),
      .mem_addr   (buf_addr[i]),
      .mem_wdata  (buf_wdata[i]),
      .mem_rdata  (buf_rdata[i]),
      .*
    );
  end

endmodule

