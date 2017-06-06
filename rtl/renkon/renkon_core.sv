`include "renkon.svh"

module renkon_core
  ( input                       clk
  , input                       xrst
  , input                       bias_oe
  , input                       breg_we
  , input                       buf_feat_en
  , input                       conv_oe
  , input                       mem_feat_rst
  , input                       mem_feat_we
  , input                       relu_oe
  , input                       wreg_we
  , input                       pool_oe
  , input         [FACCUM-1:0]  mem_feat_addr
  , input         [FACCUM-1:0]  mem_feat_addr_d1
  , input         [LWIDTH-1:0]  w_fea_size
  , input         [LWIDTH-1:0]  w_pool_size
  , input  signed [DWIDTH-1:0]  pixel [FSIZE**2-1:0]
  , input  signed [DWIDTH-1:0]  net_rdata
  , output signed [DWIDTH-1:0]  pmap
  );

  wire signed [DWIDTH-1:0] fmap;
  wire signed [DWIDTH-1:0] bmap;
  wire signed [DWIDTH-1:0] amap;

  renkon_conv conv(
    .wreg_we      (wreg_we),
    .out_en       (conv_oe),
    .read_weight  (net_rdata),
    .pixel_in     (pixel),
    .pixel_out    (fmap),
    .*
  );

  renkon_bias bias(
    .breg_we    (breg_we),
    .out_en     (bias_oe),
    .read_bias  (net_rdata),
    .pixel_in   (fmap),
    .pixel_out  (bmap),
    .*
  );

  renkon_relu relu(
    .out_en     (relu_oe),
    .pixel_in   (bmap),
    .pixel_out  (amap),
    .*
  );

  renkon_pool pool(
    .out_en     (pool_oe),
    .pixel_in   (amap),
    .pixel_out  (pmap),
    .*
  );

endmodule