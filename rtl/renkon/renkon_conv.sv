`include "renkon.svh"

module renkon_conv
  ( input                       clk
  , input                       xrst
  , input                       out_en
  , input                       wreg_we
  , input                       mem_feat_we
  , input                       mem_feat_rst
  , input  [FACCUM-1:0]         mem_feat_addr
  , input  [FACCUM-1:0]         mem_feat_addr_d1
  , input  signed [DWIDTH-1:0]  pixel_in [FSIZE**2-1:0]
  , input  signed [DWIDTH-1:0]  read_weight
  , output signed [DWIDTH-1:0]  pixel_out
  );

  wire signed [DWIDTH-1:0] weight [FSIZE**2-1:0];
  wire signed [DWIDTH-1:0] feat_rdata;
  wire signed [DWIDTH-1:0] feat_wdata;
  wire signed [DWIDTH-1:0] result;

  renkon_conv_wreg wreg(.*);

  if (FSIZE == 3)
    renkon_conv_tree9  tree(
      .pixel  (pixel_in),
      .fmap   (result),
      .*
    );
  else if (FSIZE == 5)
    renkon_conv_tree25 tree(
      .pixel  (pixel_in),
      .fmap   (result),
      .*
    );

  renkon_accum feat_accum(
    .pixel_in (result),
    .reset    (mem_feat_rst),
    .sum_old  (feat_rdata),
    .sum_new  (feat_wdata),
    .*
  );

  mem_dp #(DWIDTH, FACCUM) mem_feat(
    .mem_we1    (mem_feat_we),
    .mem_addr1  (mem_feat_addr_d1),
    .mem_wdata1 (feat_wdata),
    .mem_rdata1 (),
    .mem_we2    (1'b0),
    .mem_addr2  (mem_feat_addr),
    .mem_wdata2 ({DWIDTH{1'b0}}),
    .mem_rdata2 (feat_rdata),
    .*
  );

endmodule
