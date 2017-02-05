`include "renkon.svh"
`include "ctrl_bus.svh"

module ctrl
  ( input                       clk
  , input                       xrst
  , input                       req
  , input                       img_we
  , input         [IMGSIZE-1:0] input_addr
  , input         [IMGSIZE-1:0] output_addr
  , input  signed [DWIDTH-1:0]  write_img
  , input  signed [DWIDTH-1:0]  write_result
  , input         [CORELOG:0]   net_we
  , input         [NETSIZE-1:0] net_addr
  , input         [LWIDTH-1:0]  total_in
  , input         [LWIDTH-1:0]  total_out
  , input         [LWIDTH-1:0]  img_size
  , input         [LWIDTH-1:0]  fil_size
  , output                      ack
  , output                      wreg_we
  , output                      conv_oe
  , output                      pool_oe
  , output                      buf_feat_en
  , output                      mem_img_we
  , output        [IMGSIZE-1:0] mem_img_addr
  , output signed [DWIDTH-1:0]  write_mem_img
  , output        [CORE-1:0]    mem_net_we
  , output        [NETSIZE-1:0] mem_net_addr
  , output                      mem_feat_we
  , output                      mem_feat_rst
  , output        [FACCUM-1:0]  mem_feat_addr
  , output        [FACCUM-1:0]  mem_feat_addr_d1
  , output        [LWIDTH-1:0]  w_img_size
  , output        [LWIDTH-1:0]  w_fil_size
  , output        [LWIDTH-1:0]  w_fea_size
  , output        [LWIDTH-1:0]  w_pool_size
  );

  ctrl_bus bus_core();
  ctrl_bus bus_conv();
  ctrl_bus bus_bias();
  ctrl_bus bus_relu();
  ctrl_bus bus_pool();

  ctrl_core ctrl_core(
    .in_ctrl  (bus_pool),
    .out_ctrl (bus_core),
    .*
  );

  ctrl_conv ctrl_conv(
    .in_ctrl  (bus_core),
    .out_ctrl (bus_conv),
    .*
  );

  ctrl_bias ctrl_bias(
    .in_ctrl  (bus_conv),
    .out_ctrl (bus_bias),
    .*
  );

  ctrl_relu ctrl_relu(
    .in_ctrl  (bus_bias),
    .out_ctrl (bus_relu),
    .*
  );

  ctrl_pool ctrl_pool(
    .in_ctrl  (bus_relu),
    .out_ctrl (bus_pool),
    .*
  );

endmodule