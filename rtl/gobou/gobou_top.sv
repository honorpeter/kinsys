`include "gobou.svh"

module gobou_top
  ( input                     clk
  , input                     xrst
  , input                     req
  , input signed [DWIDTH-1:0] img_rdata
  , input [GOBOU_CORELOG-1:0] net_sel
  , input                     net_we
  , input [GOBOU_NETSIZE-1:0] net_addr
  , input signed [DWIDTH-1:0] net_wdata
  , input [IMGSIZE-1:0]       in_offset
  , input [IMGSIZE-1:0]       out_offset
  , input [GOBOU_NETSIZE-1:0] net_offset

  // Network parameters
  , input [LWIDTH-1:0]        total_out
  , input [LWIDTH-1:0]        total_in

  , output                      ack
  , output                      img_we
  , output [IMGSIZE-1:0]        img_addr
  , output signed [DWIDTH-1:0]  img_wdata
  );

  wire [GOBOU_CORE-1:0]     mem_net_we;
  wire [GOBOU_NETSIZE-1:0]  mem_net_addr;
  wire signed [DWIDTH-1:0]  net_rdata [GOBOU_CORE-1:0];
  wire signed [DWIDTH-1:0]  result    [GOBOU_CORE-1:0];
  wire signed [DWIDTH-1:0]  out_wdata;
  wire                      breg_we;
  wire                      serial_we;
  wire                      mac_oe;
  wire                      accum_we;
  wire                      accum_rst;
  wire                      bias_oe;
  wire                      relu_oe;

  gobou_ctrl ctrl(.*);

  for (genvar i = 0; i < GOBOU_CORE; i++) begin : pe
    mem_sp #(DWIDTH, GOBOU_NETSIZE) mem_net(
      .mem_we     (mem_net_we[i]),
      .mem_addr   (mem_net_addr),
      .mem_wdata  (net_wdata),
      .mem_rdata  (net_rdata[i]),
      .*
    );

    gobou_core core(
      .pixel  (img_rdata),
      .weight (net_rdata[i]),
      .avec   (result[i]),
      .*
    );
  end : pe

  gobou_serial_vec serial(
    .in_data  (result),
    .out_data (out_wdata),
    .*
  );

endmodule
