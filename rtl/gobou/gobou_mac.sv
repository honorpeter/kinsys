`include "gobou.svh"

module gobou_mac
  ( input                      clk
  , input                      xrst
  , input                      out_en
  , input                      accum_we
  , input                      reset
  , input  signed [DWIDTH-1:0] x
  , input  signed [DWIDTH-1:0] w
  , output signed [DWIDTH-1:0] y
  );

  wire signed [2*DWIDTH-1:0] pro;
  wire signed [DWIDTH-1:0]   pro_short;

  reg signed [DWIDTH-1:0] x$;
  reg signed [DWIDTH-1:0] w$;
  reg signed [DWIDTH-1:0] y$;
  reg signed [DWIDTH-1:0] accum$;
  reg signed [2*DWIDTH-1:0] pro$;
  reg signed [DWIDTH-1:0] pro_short$;

  assign pro = x$ * w$;
  assign pro_short = round(pro$);
  assign y = y$;

  always @(posedge clk)
    if (!xrst)
      x$ <= 0;
    else
      x$ <= x;

  always @(posedge clk)
    if (!xrst)
      w$ <= 0;
    else
      w$ <= w;

  always @(posedge clk)
    if (!xrst)
      y$ <= 0;
    else if (out_en)
      y$ <= accum$;

  always @(posedge clk)
    if (!xrst)
      accum$ <= 0;
    else if (reset)
      accum$ <= 0;
    else if (accum_we)
      accum$ <= accum$ + pro_short$;

  always @(posedge clk)
    if (!xrst)
      pro$ <= 0;
    else
      pro$ <= pro;

  always @(posedge clk)
    if (!xrst)
      pro_short$ <= 0;
    else
      pro_short$ <= pro_short;

////////////////////////////////////////////////////////////
//  Function
////////////////////////////////////////////////////////////

  function signed [DWIDTH-1:0] round;
    input signed [2*DWIDTH-1:0] data;
    if (data[2*DWIDTH-DWIDTH/2-2] == 1 && data[DWIDTH/2-1:0] == 0)
      round = $signed({
                data[2*DWIDTH-DWIDTH/2-2],
                data[2*DWIDTH-DWIDTH/2-2:DWIDTH/2] - 1'b1
              });
    else
      round = $signed({
                data[2*DWIDTH-DWIDTH/2-2],
                data[2*DWIDTH-DWIDTH/2-2:DWIDTH/2]
              });
  endfunction

endmodule
