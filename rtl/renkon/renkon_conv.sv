`include "renkon.svh"
`include "mem_dp.sv"

module renkon_conv
  ( input                       clk
  , input                       xrst
  , input                       out_en
  , input                       wreg_we
  , input                       mem_feat_we
  , input                       mem_feat_rst
  , input         [FACCUM-1:0]  mem_feat_addr
  , input         [FACCUM-1:0]  mem_feat_addr_d1
  , input  signed [DWIDTH-1:0]  pixel_in [FSIZE**2-1:0]
  , input  signed [DWIDTH-1:0]  read_weight
  , output signed [DWIDTH-1:0]  pixel_out
  );

  wire signed [DWIDTH-1:0] weight [25-1:0];
  wire signed [DWIDTH-1:0] read_feat;
  wire signed [DWIDTH-1:0] result;
  wire signed [DWIDTH-1:0] write_feat;

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
    .sum_old  (read_feat),
    .sum_new  (write_feat),
    .*
  );

  mem_dp #(DWIDTH, FACCUM) mem_feat(
    .read_data1   (),
    .write_data1  (write_feat),
    .mem_we1      (mem_feat_we),
    .mem_addr1    (mem_feat_addr_d1),
    .read_data2   (read_feat),
    .write_data2  ({DWIDTH{1'b0}}),
    .mem_we2      (1'b0),
    .mem_addr2    (mem_feat_addr),
    .*
  );

endmodule
