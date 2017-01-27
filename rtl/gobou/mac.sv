`include "gobou.vh"

module mac
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

  reg signed [DWIDTH-1:0] r_x;
  reg signed [DWIDTH-1:0] r_w;
  reg signed [DWIDTH-1:0] r_y;
  reg signed [DWIDTH-1:0] r_accum;

  // TODO: adjust the bitwidth of multiplication results.
  assign pro = r_x * r_w;
  assign pro_short  = $signed({
                        pro[2*DWIDTH-2-DWIDTH/2],
                        round(pro[2*DWIDTH-2-DWIDTH/2:0])
                      });
  assign y = r_y;

  always @(posedge clk)
    if (!xrst)
      r_x <= 0;
    else
      r_x <= x;

  always @(posedge clk)
    if (!xrst)
      r_w <= 0;
    else
      r_w <= w;

  always @(posedge clk)
    if (!xrst)
      r_y <= 0;
    else if (out_en)
      r_y <= r_accum;

  always @(posedge clk)
    if (!xrst)
      r_accum <= 0;
    else if (reset)
      r_accum <= 0;
    else if (accum_we)
      r_accum <= r_accum + pro_short;

  function signed [DWIDTH-2:0] round;
    input [2*DWIDTH-2-DWIDTH/2:0] data;
    if (
      data[2*DWIDTH-2-DWIDTH/2] == 1'b1
      && data[DWIDTH/2-1:0] == {DWIDTH/2{1'b0}}
    )
      round = data[2*DWIDTH-2-DWIDTH/2:DWIDTH/2] - 1;
    else
      round = data[2*DWIDTH-2-DWIDTH/2:DWIDTH/2];
  endfunction

endmodule
