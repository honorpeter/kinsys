`include "renkon.svh"

module accum
  ( input                      clk
  , input                      xrst
  , input                      reset
  , input                      out_en
  , input  signed [DWIDTH-1:0] pixel_in
  , input  signed [DWIDTH-1:0] sum_old
  , output signed [DWIDTH-1:0] pixel_out
  , output signed [DWIDTH-1:0] sum_new
  );

  wire signed [DWIDTH-1:0] sum;

  reg signed [DWIDTH-1:0] r_total;

  assign pixel_out  = r_total;
  assign sum_new    = sum;

  assign sum = reset
             ? pixel_in
             : pixel_in + sum_old;

  always @(posedge clk)
    if (!xrst)
      r_total <= 0;
    else if(out_en)
      r_total <= sum;

endmodule
