`include "renkon.svh"

module renkon_pool_max9
  ( input                      clk
  , input                      xrst
  , input  signed [DWIDTH-1:0] pixel [9-1:0]
  , output signed [DWIDTH-1:0] pmap
  );

  wire signed [DWIDTH-1:0] max0_0;
  wire signed [DWIDTH-1:0] max0_1;
  wire signed [DWIDTH-1:0] max0_2;
  wire signed [DWIDTH-1:0] max0_3;
  wire signed [DWIDTH-1:0] max1_0;
  wire signed [DWIDTH-1:0] max1_1;
  wire signed [DWIDTH-1:0] max2_0;
  wire signed [DWIDTH-1:0] max3_0;

  reg signed [DWIDTH-1:0] pixel$ [9-1:0];

  assign max0_0 = (pixel$[0] > pixel$[1]) ? pixel$[0] : pixel$[1];
  assign max0_1 = (pixel$[2] > pixel$[3]) ? pixel$[2] : pixel$[3];
  assign max0_2 = (pixel$[4] > pixel$[5]) ? pixel$[4] : pixel$[5];
  assign max0_3 = (pixel$[6] > pixel$[7]) ? pixel$[6] : pixel$[7];
  assign max1_0 = (max0_0 > max0_1) ? max0_0 : max0_1;
  assign max1_1 = (max0_2 > max0_3) ? max0_2 : max0_3;
  assign max2_0 = (max1_0 > max1_1) ? max1_0 : max1_1;
  assign max3_0 = (max2_0 > pixel$[8]) ? max2_0 : pixel$[8];
  assign pmap = max3_0;

  for (genvar i = 0; i < 9; i++)
    always @(posedge clk)
      if (!xrst)
        pixel$[i] <= 0;
      else
        pixel$[i] <= pixel[i];

endmodule
