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

  linebuf buf_feat(.*);

endmodule
