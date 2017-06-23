`include "renkon.svh"

module renkon_relu
  ( input clk
  , input xrst
  , input out_en
  , input signed [DWIDTH-1:0] pixel_in
  , output signed [DWIDTH-1:0] pixel_out
  );

  reg signed [DWIDTH-1:0] pixel_in$;
  reg signed [DWIDTH-1:0] pixel_out$;

  assign pixel_out = pixel_out$;

  always @(posedge clk)
    if (!xrst)
      pixel_in$ <= 0;
    else
      pixel_in$ <= pixel_in;

  always @(posedge clk)
    if (!xrst)
      pixel_out$ <= 0;
    else if (out_en)
      if (pixel_in$ > 0)
        pixel_out$ <= pixel_in$;
      else
        pixel_out$ <= 0;

endmodule
