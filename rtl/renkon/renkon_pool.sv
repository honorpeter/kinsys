`include "renkon.svh"

module renkon_pool
  ( input                      clk
  , input                      xrst
  , input                      out_en
  , input                      buf_feat_req
  , input         [LWIDTH-1:0] w_fea_size
  , input         [LWIDTH-1:0] w_pool_size
  , input  signed [DWIDTH-1:0] pixel_in
  , output signed [DWIDTH-1:0] pixel_out
  );

  wire signed [DWIDTH-1:0] pixel_feat [PSIZE**2-1:0];

  renkon_linebuf #(PSIZE, D_POOLBUF) buf_feat(
    .buf_input  (pixel_in),
    .buf_output (pixel_feat),
    .*
  );

  if (PSIZE == 2)
    renkon_pool_max4 pool_tree(
      .pixel (pixel_feat),
      .pmap  (pixel_out),
      .*
    );

endmodule
