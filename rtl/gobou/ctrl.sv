`include "gobou.svh"
`include "ctrl_bus.svh"

module ctrl
  ( input                       clk
  , input                       xrst
  , input                       req
  , input                       img_we
  , input        [IMGSIZE-1:0]  input_addr
  , input        [IMGSIZE-1:0]  output_addr
  , input signed [DWIDTH-1:0]   write_img
  , input signed [DWIDTH-1:0]   write_result
  , input        [CORELOG:0]    net_we
  , input        [NETSIZE-1:0]  net_addr
  , input        [LWIDTH-1:0]   total_out
  , input        [LWIDTH-1:0]   total_in
  , output                      ack
  , output                      mem_img_we
  , output [IMGSIZE-1:0]        mem_img_addr
  , output signed [DWIDTH-1:0]  write_mem_img
  , output        [CORE-1:0]    mem_net_we
  , output        [NETSIZE-1:0] mem_net_addr
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

  ctrl_core ctrl_core(
    .in_ctrl  (bus_relu),
    .out_ctrl (bus_core),
    .*
  );

  ctrl_mac ctrl_mac(
    .in_ctrl  (bus_core),
    .out_ctrl (bus_mac),
    .*
  );

  ctrl_bias ctrl_bias(
    .in_ctrl  (bus_mac),
    .out_ctrl (bus_bias),
    .*
  );

  ctrl_relu ctrl_relu(
    .in_ctrl  (bus_bias),
    .out_ctrl (bus_relu),
    .*
  );

endmodule
