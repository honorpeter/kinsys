`include "gobou.svh"

module gobou_ctrl
  ( input                       clk
  , input                       xrst
  , input                       req
  , input  [GOBOU_CORELOG-1:0]  net_sel
  , input                       net_we
  , input  [GOBOU_NETSIZE-1:0]  net_addr
  , input  [IMGSIZE-1:0]        in_offset
  , input  [IMGSIZE-1:0]        out_offset
  , input  [GOBOU_NETSIZE-1:0]  net_offset
  , input  [LWIDTH-1:0]         total_out
  , input  [LWIDTH-1:0]         total_in
  , input  signed [DWIDTH-1:0]  out_wdata
`ifdef DIST
`else
  , input                       img_we
  , input  signed [DWIDTH-1:0]  img_wdata
`endif
  , output                      ack
  , output                      mem_img_we
  , output [IMGSIZE-1:0]        mem_img_addr
  , output signed [DWIDTH-1:0]  mem_img_wdata
  , output [GOBOU_CORE-1:0]     mem_net_we
  , output [GOBOU_NETSIZE-1:0]  mem_net_addr
  , output                      breg_we
  , output                      serial_we
  , output                      mac_oe
  , output                      accum_we
  , output                      accum_rst
  , output                      bias_oe
  , output                      relu_oe
  );

  ctrl_bus bus_core();
  ctrl_bus bus_mac();
  ctrl_bus bus_bias();
  ctrl_bus bus_relu();

  gobou_ctrl_core ctrl_core(
    .in_ctrl  (bus_relu),
    .out_ctrl (bus_core),
    .*
  );

  gobou_ctrl_mac ctrl_mac(
    .in_ctrl  (bus_core),
    .out_ctrl (bus_mac),
    .*
  );

  gobou_ctrl_bias ctrl_bias(
    .in_ctrl  (bus_mac),
    .out_ctrl (bus_bias),
    .*
  );

  gobou_ctrl_relu ctrl_relu(
    .in_ctrl  (bus_bias),
    .out_ctrl (bus_relu),
    .*
  );

endmodule
