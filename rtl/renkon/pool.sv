`include "renkon.svh"

module pool
  ( input                      clk
  , input                      xrst
  , input                      out_en
  , input  signed [DWIDTH-1:0] pixel_in
  , output signed [DWIDTH-1:0] pixel_out
  );

  if (PSIZE == 2)
    pool_max4 pool_tree(.*);

  linebuf buf_feat(
    .buf_en     (buf_feat_en),
    .buf_input  (pixel_in[DWIDTH-1:0]),
    .img_size   (w_fea_size[LWIDTH-1:0]),
    .fil_size   (w_pool_size[LWIDTH-1:0]),
    .*
  );

endmodule
