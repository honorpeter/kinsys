`include "renkon.svh"
`include "mem_dp.sv"

module conv
  ( input                       clk
  , input                       xrst
  , input                       out_en
  , input                       wreg_we
  , input                       mem_feat_we
  , input                       mem_feat_rst
  , input         [FACCUM-1:0]  mem_feat_addr
  , input         [FACCUM-1:0]  mem_feat_addr_d1
  , input         [DWIDTH-1:0]  pixel_in [FSIZE**2-1:0]
  , input  signed [DWIDTH-1:0]  read_weight
  , output signed [DWIDTH-1:0]  pixel_out
  );

  wire signed [DWIDTH-1:0] weight [25-1:0];

  if (FSIZE == 3)
    conv_tree9  tree(
      .pixel  (pixel_in),
      .fmap   (result),
      .*
    );
  else if (FSIZE == 5)
    conv_tree25 tree(
      .pixel  (pixel_in),
      .fmap   (result),
      .*
    );

  conv_wreg wreg(.*);

  mem_dp #(DWIDTH, FACCUM) mem_feat(
    .read_data1   (),
    .write_data1  (write_feat),
    .mem_we1      (mem_feat_we),
    .mem_addr1    (mem_feat_addr_d1),
    .read_data2   (read_feat),
    .write_data2  (0),
    .mem_we2      (0),
    .mem_addr2    (mem_feat_addr),
    .*
  );

  accum feat_accum(
    .pixel_in (result),
    .reset    (mem_feat_rst),
    .sum_old  (read_feat),
    .sum_new  (write_feat),
    .*
  );

endmodule
