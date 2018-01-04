`include "renkon.svh"

module renkon_conv
  ( input                       clk
  , input                       xrst
  , input  [LWIDTH-1:0]         _qbits
  , input                       out_en
  , input                       wreg_we
  , input                       mem_feat_we
  , input                       mem_feat_rst
  , input  [FACCUM-1:0]         mem_feat_waddr
  , input  [FACCUM-1:0]         mem_feat_raddr
  , input  signed [DWIDTH-1:0]  pixel_in [CONV_KERN**2-1:0]
  , input  signed [DWIDTH-1:0]  read_weight
  , output signed [DWIDTH-1:0]  pixel_out
  );

  wire signed [DWIDTH-1:0] weight [CONV_KERN**2-1:0];
  wire signed [DWIDTH-1:0] mem_feat_rdata;
  wire signed [DWIDTH-1:0] mem_feat_wdata;
  wire signed [DWIDTH-1:0] result;

  renkon_conv_wreg wreg(.*);

  // if (CONV_KERN == 3)
    renkon_conv_tree9 tree(
      .pixel  (pixel_in),
      .fmap   (result),
      .*
    );
  // else if (CONV_KERN == 5)
  //   renkon_conv_tree25 tree(
  //     .pixel  (pixel_in),
  //     .fmap   (result),
  //     .*
  //   );

  renkon_accum feat_accum(
    .pixel_in (result),
    .reset    (mem_feat_rst),
    .sum_old  (mem_feat_rdata),
    .sum_new  (mem_feat_wdata),
    .*
  );

  mem_dp #(DWIDTH, FACCUM) mem_feat(
    .mem_we1    (mem_feat_we),
    .mem_addr1  (mem_feat_waddr),
    .mem_wdata1 (mem_feat_wdata),
    .mem_rdata1 (),
    .mem_we2    (1'b0),
    .mem_addr2  (mem_feat_raddr),
    .mem_wdata2 ({DWIDTH{1'b0}}),
    .mem_rdata2 (mem_feat_rdata),
    .*
  );

endmodule
