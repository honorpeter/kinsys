`include "gobou.svh"

module gobou_bias
  ( input clk
  , input xrst
  , input enable
  , input breg_we
  , input out_en
  , input  signed [DWIDTH-1:0] read_bias
  , input  signed [DWIDTH-1:0] pixel_in
  , output signed [DWIDTH-1:0] pixel_out
  );

  reg signed [DWIDTH-1:0] bias$;
  reg signed [DWIDTH-1:0] pixel_in$;
  reg signed [DWIDTH-1:0] pixel_out$;

  assign pixel_out = pixel_out$;

  always @(posedge clk)
    if (!xrst)
      bias$ <= 0;
    else if (breg_we)
      bias$ <= read_bias;

  always @(posedge clk)
    if (!xrst)
      pixel_in$ <= 0;
    else
      pixel_in$ <= pixel_in;

  always @(posedge clk)
    if (!xrst)
      pixel_out$ <= 0;
    else if (!enable)
      pixel_out$ <= pixel_in;
    else if (out_en)
      pixel_out$ <= pixel_in$ + bias$;

endmodule
