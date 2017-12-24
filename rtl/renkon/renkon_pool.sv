`include "renkon.svh"

module renkon_pool
  ( input                      clk
  , input                      xrst
  , input                      enable
  , input                      out_en
  , input         [LWIDTH-1:0] _fea_size
  , input         [LWIDTH-1:0] _pool_size
  , input                             buf_feat_wcol
  , input                             buf_feat_rrow [PSIZE-1:0]
  , input  [$clog2(PSIZE+1):0]        buf_feat_wsel
  , input  [$clog2(PSIZE+1):0]        buf_feat_rsel
  , input                             buf_feat_we
  , input  [$clog2(D_POOLBUF+1)-1:0]  buf_feat_addr
  , input  signed [DWIDTH-1:0] pixel_in
  , output signed [DWIDTH-1:0] pixel_out
  );

  wire signed [DWIDTH-1:0] pmap;
  wire signed [DWIDTH-1:0] pixel_feat [PSIZE**2-1:0];

  reg signed [DWIDTH-1:0] pixel_out$;

  assign pixel_out = pixel_out$;

if (1)
  renkon_linebuf #(PSIZE, D_POOLBUF) buf_feat(
    .buf_wsel   (buf_feat_wsel),
    .buf_rsel   (buf_feat_rsel),
    .buf_we     (buf_feat_we),
    .buf_addr   (buf_feat_addr),
    .buf_input  (pixel_in),
    .buf_output (pixel_feat),
    .*
  );
else
  renkon_linebuf_pad #(PSIZE, D_POOLBUF) buf_feat(
    .buf_wcol   (buf_feat_wcol),
    .buf_rrow   (buf_feat_rrow),
    .buf_wsel   (buf_feat_wsel),
    .buf_rsel   (buf_feat_rsel),
    .buf_we     (buf_feat_we),
    .buf_addr   (buf_feat_addr),
    .buf_input  (pixel_in),
    .buf_output (pixel_feat),
    .*
  );

  if (PSIZE == 2)
    renkon_pool_max4 pool_tree(
      .pixel (pixel_feat),
      .pmap  (pmap),
      .*
    );

  always @(posedge clk)
    if(!xrst)
      pixel_out$ <= 0;
    else if (!enable)
      pixel_out$ <= pixel_in;
    else if (out_en)
      pixel_out$ <= pmap;

endmodule
