`include "gobou.svh"

module gobou_bias
  ( input clk
  , input xrst
  , input breg_we
  , input out_en
  , input  signed [DWIDTH-1:0] read_bias
  , input  signed [DWIDTH-1:0] pixel_in
  , output signed [DWIDTH-1:0] pixel_out
  );

  reg signed [DWIDTH-1:0] r_bias;
  reg signed [DWIDTH-1:0] r_pixel_in;
  reg signed [DWIDTH-1:0] r_pixel_out;

  assign pixel_out = r_pixel_out;

  always @(posedge clk)
    if (!xrst)
      r_bias <= 0;
    else if (breg_we)
      r_bias <= read_bias;

  always @(posedge clk)
    if (!xrst)
      r_pixel_in <= 0;
    else
      r_pixel_in <= pixel_in;

  always @(posedge clk)
    if (!xrst)
      r_pixel_out <= 0;
    else if (out_en)
      r_pixel_out <= r_pixel_in + r_bias;

endmodule
