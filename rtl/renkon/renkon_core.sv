`include "renkon.svh"

module renkon_core
  ( input                       clk
  , input                       xrst
  , input                       bias_oe
  , input                       breg_we
  , input                       conv_oe
  , input                       relu_oe
  , input                       wreg_we
  , input                       pool_oe
  , input                       mem_feat_rst
  , input                       mem_feat_we
  , input         [FACCUM-1:0]  mem_feat_raddr
  , input         [FACCUM-1:0]  mem_feat_waddr
  , input                             buf_feat_wcol
  , input                             buf_feat_rrow [POOL_KERN-1:0]
  , input  [$clog2(POOL_KERN+1):0]    buf_feat_wsel
  , input  [$clog2(POOL_KERN+1):0]    buf_feat_rsel
  , input                             buf_feat_we
  , input  [$clog2(D_POOLBUF+1)-1:0]  buf_feat_addr
  , input  [LWIDTH-1:0]         _qbits
  , input                       _bias_en
  , input                       _relu_en
  , input                       _pool_en
  , input  signed [DWIDTH-1:0]  pixel [CONV_KERN**2-1:0]
  , input  signed [DWIDTH-1:0]  net_rdata
  , output signed [DWIDTH-1:0]  result
  );

  wire signed [DWIDTH-1:0] fmap;
  wire signed [DWIDTH-1:0] bmap;
  wire signed [DWIDTH-1:0] amap;
  wire signed [DWIDTH-1:0] pmap;

  assign result = pmap;

  renkon_conv conv(
    .wreg_we      (wreg_we),
    .out_en       (conv_oe),
    .read_weight  (net_rdata),
    .pixel_in     (pixel),
    .pixel_out    (fmap),
    .*
  );

  renkon_bias bias(
    .enable     (_bias_en),
    .breg_we    (breg_we),
    .out_en     (bias_oe),
    .read_bias  (net_rdata),
    .pixel_in   (fmap),
    .pixel_out  (bmap),
    .*
  );

  renkon_relu relu(
    .enable     (_relu_en),
    .out_en     (relu_oe),
    .pixel_in   (bmap),
    .pixel_out  (amap),
    .*
  );

  renkon_pool pool(
    .enable     (_pool_en),
    .out_en     (pool_oe),
    .pixel_in   (amap),
    .pixel_out  (pmap),
    .*
  );

endmodule
