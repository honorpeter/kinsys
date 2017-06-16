`include "ninjin.svh"

module ninjin_ddr_buf
  ( input                     clk
  , input                     xrst
  , input                     req // TODO: temporal signal
  , input [LWIDTH-1:0]        total_len
  , input                     mem_we
  , input [MEMSIZE-1:0]       mem_addr
  , input signed [DWIDTH-1:0] mem_wdata
  , input [BWIDTH-1:0]        ddr_rdata
  , output                      ddr_we
  , output                      ddr_re
  , output [MEMSIZE-1:0]        ddr_addr
  , output [BWIDTH-1:0]         ddr_wdata
  , output signed [DWIDTH-1:0]  mem_rdata
  );

  localparam RATE = BWIDTH / DWIDTH;

  wire [MEMSIZE-1:0]  addr_diff;

  enum reg [1:0] {
    M_IDLE, M_INCR, M_TRANS
  } r_mode;
  reg               r_turn;
  reg               r_ddr_we;
  reg               r_ddr_re;
  reg [MEMSIZE-1:0] r_ddr_addr;
  reg [BWIDTH-1:0]  r_ddr_wdata;
  reg [DWIDTH-1:0]  r_wdata [RATE-1:0];
  reg [MEMSIZE-1:0] r_mem_addr;

  /*
   * When ddr_req asserts, ddr_mode and ddr_base are fetched.
   * Then m_axi starts streaming with ddr_stream channel.
   * The ddr_stream represents both reading and writing data stream
   * in context of ddr_mode.
   */

  assign ddr_req    = r_ddr_req;
  assign ddr_mode   = r_ddr_mode;
  assign ddr_base   = r_ddr_base;
  assign ddr_wdata  = r_ddr_wdata;

  always @(posedge clk)
    if (!xrst)
      r_turn <= 0;

  always @(posedge clk)
    if (!xrst)
      r_ddr_req <= 0;

  always @(posedge clk)
    if (!xrst)
      r_ddr_mode <= 0;

  always @(posedge clk)
    if (!xrst)
      r_ddr_base <= 0;

  always @(posedge clk)
    if (!xrst)
      r_ddr_wdata <= 0;
    else
      r_ddr_wdata <= buf_rdata[r_turn];

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

  assign addr_diff = r_mem_addr - mem_addr;

  always @(posedge clk)
    if (!xrst)
      r_mem_addr <= 0;
    else
      r_mem_addr <= mem_addr;

  always @(posedge clk)
    if (!xrst)
      r_mode <= M_IDLE;
    else
      case (addr_diff)
        0:
          r_mode <= M_IDLE;
        1:
          r_mode <= M_INCR;
        default:
          r_mode <= M_TRANS;
      endcase

  // TODO: little endian? big endian?
  assign buf_wdata = {r_wdata[1], r_wdata[0]};

  // one is for user interface, other is for ddr interface
  // roles switch for each burst
  for (genvar i = 0; i < 2; i++)
    mem_sp #(BWIDTH, BURST_LEN) mem_buf(
      .mem_we     (buf_we[i]),
      .mem_addr   (buf_addr[i]),
      .mem_wdata  (buf_wdata[i]),
      .mem_rdata  (buf_rdata[i]),
      .*
    );

endmodule

