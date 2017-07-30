`include "renkon.svh"

module renkon_ctrl
  ( input                       clk
  , input                       xrst
  , input                       req
  , input  [RENKON_CORELOG-1:0] net_sel
  , input                       net_we
  , input  [RENKON_NETSIZE-1:0] net_addr
  , input  [IMGSIZE-1:0]        in_offset
  , input  [IMGSIZE-1:0]        out_offset
  , input  [RENKON_NETSIZE-1:0] net_offset
  , input  [LWIDTH-1:0]         total_in
  , input  [LWIDTH-1:0]         total_out
  , input  [LWIDTH-1:0]         img_size
  , input  [LWIDTH-1:0]         conv_size
  , input  [LWIDTH-1:0]         pool_size
  , input  signed [DWIDTH-1:0]  out_wdata
  , output                      ack
  , output                      buf_pix_en
  , output                      wreg_we
  , output                      conv_oe
  , output                      breg_we
  , output                      bias_oe
  , output                      relu_oe
  , output                      pool_oe
  , output                      serial_we
  , output [RENKON_CORELOG:0]   serial_re
  , output [OUTSIZE-1:0]        serial_addr
  , output                      buf_feat_en
  , output                      img_we
  , output [IMGSIZE-1:0]        img_addr
  , output signed [DWIDTH-1:0]  img_wdata
  , output [RENKON_CORE-1:0]    mem_net_we
  , output [RENKON_NETSIZE-1:0] mem_net_addr
  , output                      mem_feat_we
  , output                      mem_feat_rst
  , output [FACCUM-1:0]         mem_feat_addr
  , output [FACCUM-1:0]         mem_feat_addr_d1
  , output [LWIDTH-1:0]         w_img_size
  , output [LWIDTH-1:0]         w_conv_size
  , output [LWIDTH-1:0]         w_fea_size
  , output [LWIDTH-1:0]         w_pool_size
  );

  wire [1:0] core_state;
  wire       first_input;
  wire       last_input;

  ctrl_bus bus_core();
  ctrl_bus bus_conv();
  ctrl_bus bus_bias();
  ctrl_bus bus_relu();
  ctrl_bus bus_pool();

  renkon_ctrl_core ctrl_core(
    .in_ctrl  (bus_pool),
    .out_ctrl (bus_core),
    .*
  );

  renkon_ctrl_conv ctrl_conv(
    .in_ctrl  (bus_core),
    .out_ctrl (bus_conv),
    .*
  );

  renkon_ctrl_bias ctrl_bias(
    .in_ctrl  (bus_conv),
    .out_ctrl (bus_bias),
    .*
  );

  renkon_ctrl_relu ctrl_relu(
    .in_ctrl  (bus_bias),
    .out_ctrl (bus_relu),
    .*
  );

  renkon_ctrl_pool ctrl_pool(
    .in_ctrl  (bus_relu),
    .out_ctrl (bus_pool),
    .*
  );

endmodule
