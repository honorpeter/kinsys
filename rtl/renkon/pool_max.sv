`include "renkon.svh"

module pool_max4
  ( input                      clk
  , input                      xrst
  , input                      out_en
  , input  signed [DWIDTH-1:0] pixel_feat [4-1:0]
  , output signed [DWIDTH-1:0] pixel_out
  );

  wire signed [DWIDTH-1:0] max0_0;
  wire signed [DWIDTH-1:0] max0_1;
  wire signed [DWIDTH-1:0] max1_0;
  wire signed [DWIDTH-1:0] pmap;

  reg signed [DWIDTH-1:0] r_pixel_feat [4-1:0];
  reg signed [DWIDTH-1:0] r_pmap;

  assign max0_0 = (r_pixel_feat0 > r_pixel_feat1)
                ? r_pixel_feat0
                : r_pixel_feat1;

  assign max0_1 = (r_pixel_feat2 > r_pixel_feat3)
                ? r_pixel_feat2
                : r_pixel_feat3;

  assign max1_0 = (max0_0 > max0_1)
                ? max0_0
                : max0_1;

  assign pmap = max1_0;

  assign pixel_out = r_pmap;

  for (genvar i = 0; i < 4; i++)
    always @(posedge clk)
      if (!xrst)
        r_pixel_feat[i] <= 0;
      else
        r_pixel_feat[i] <= pixel_feat[i];

  always @(posedge clk or negedge xrst)
    if(!xrst)
      r_pmap <= 0;
    else if (out_en)
      r_pmap <= pmap;

endmodule
