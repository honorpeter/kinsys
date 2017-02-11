`include "renkon.svh"

module conv
  ( input                       clk
  , input                       xrst
  , input                       out_en
  , input                       wreg_we
  , input                       mem_feat_we
  , input                       mem_feat_rst
  , input         [FACCUM-1:0]  mem_feat_addr
  , input         [FACCUM-1:0]  mem_feat_addr_d
  , input         [DWIDTH-1:0]  pixel_in [FSIZE**2-1:0]
  , input  signed [DWIDTH-1:0]  read_weight
  , output signed [DWIDTH-1:0]  pixel_out
  );

  if (FSIZE == 3)
    conv_tree9  tree(.*);
  else if (FSIZE == 5)
    conv_tree25 tree(.*);

  conv_wreg wreg(.*);

  mem_dp #(DWIDTH, FACCUM) mem_feat(.*);

  accum feat_accum(.*);

endmodule
