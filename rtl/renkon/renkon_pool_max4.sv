`include "renkon.svh"

module renkon_pool_max4
  ( input                      clk
  , input                      xrst
  , input                      out_en
  , input  signed [DWIDTH-1:0] pixel [4-1:0]
  , output signed [DWIDTH-1:0] pmap
  );

  wire signed [DWIDTH-1:0] max0_0;
  wire signed [DWIDTH-1:0] max0_1;
  wire signed [DWIDTH-1:0] max1_0;

  reg signed [DWIDTH-1:0] r_pixel [4-1:0];
  reg signed [DWIDTH-1:0] r_pmap;

  assign max0_0 = (r_pixel[0] > r_pixel[1])
                ? r_pixel[0]
                : r_pixel[1];

  assign max0_1 = (r_pixel[2] > r_pixel[3])
                ? r_pixel[2]
                : r_pixel[3];

  assign max1_0 = (max0_0 > max0_1)
                ? max0_0
                : max0_1;

  assign pmap = r_pmap;

  for (genvar i = 0; i < 4; i++)
    always @(posedge clk)
      if (!xrst)
        r_pixel[i] <= 0;
      else
        r_pixel[i] <= pixel[i];

  always @(posedge clk)
    if(!xrst)
      r_pmap <= 0;
    else if (out_en)
      r_pmap <= max1_0;

endmodule
