`include "renkon.svh"

module conv
  (
  );

  if (FSIZE == 3)
    conv_tree9  tree(.*);
  else if (FSIZE == 5)
    conv_tree25 tree(.*);

  conv_wreg wreg(.*);

  mem_dp #(DWIDTH, FACCUM) mem_feat(.*);

  accum feat_accum(.*);

endmodule
