`include "renkon.svh"

module pool
  ( input                      clk
  , input                      xrst
  , input                      out_en
  , input                      buf_feat_en
  , input         [LWIDTH-1:0] w_fea_size
  , input         [LWIDTH-1:0] w_pool_size
  , input  signed [DWIDTH-1:0] pixel_in
  , output signed [DWIDTH-1:0] pixel_out
  );

  wire signed [DWIDTH-1:0] pixel_feat [PSIZE**2-1:0];

  linebuf buf_feat(
    .buf_en     (buf_feat_en),
    .buf_input  (pixel_in[DWIDTH-1:0]),
    .img_size   (w_fea_size[LWIDTH-1:0]),
    .fil_size   (w_pool_size[LWIDTH-1:0]),
    .buf_output (pixel_feat),
    .*
  );

  if (PSIZE == 2)
    pool_max4 pool_tree(
      .pixel (pixel_feat),
      .pmap  (pixel_out),
      .*
    );

endmodule
