`include "ninjin.svh"

module ninjin_ddr_buf
  ( input                     clk
  , input                     xrst
  , input                     req // TODO: temporal signal
  , input [LWIDTH-1:0]        total_len
  , input                     mem_ddr
  , input [IMGSIZE-1:0]       mem_ddr_addr
  , input signed [DWIDTH-1:0] mem_ddr_wdata
  , output                      ddr_req
  , output                      ddr_mode
  , output signed [DWIDTH-1:0]  mem_ddr_rdata
  );

  enum reg {
    DDR_READ, DDR_WRITE
  } r_mode;
  reg r_req;

  assign req = r_req;

  always @(posedge clk)
    if (!xrst)
      r_req <= 0;
    else

  always @(posedge clk)
    if (!xrst)
      r_mode <= DDR_READ;
    else

  // one is for user interface, other is for ddr interface
  // roles switch for each burst
  for (genvar i = 0; i < 2; i++)
    mem_sp #(DWIDTH, BURST_LEN) mem_buf(
      .mem_we     (),
      .mem_addr   (),
      .mem_wdata  (),
      .mem_rdata  (),
      .*
    );

endmodule

