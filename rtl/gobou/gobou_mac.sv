`include "gobou.svh"

module gobou_mac
  ( input                      clk
  , input                      xrst
  , input  [DWIDTHLOG-1:0]     _qbits
  , input                      out_en
  , input                      accum_we
  , input                      reset
  , input  signed [DWIDTH-1:0] x
  , input  signed [DWIDTH-1:0] w
  , output signed [DWIDTH-1:0] y
  );

  wire signed [2*DWIDTH-1:0] pro;
  wire signed [DWIDTH-1:0]   pro_short;

  reg [DWIDTHLOG-1:0]       qbits$;
  reg signed [DWIDTH-1:0]   x$;
  reg signed [DWIDTH-1:0]   w$;
  reg signed [DWIDTH-1:0]   y$;
  reg signed [DWIDTH-1:0]   accum$;
  reg signed [2*DWIDTH-1:0] pro$;
  reg signed [DWIDTH-1:0]   pro_short$;

  assign pro = x$ * w$;
  // rounder16b rnd(.x(pro$), .qbits(qbits$), .y(pro_short), .*);
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

//==========================================================
//  Function
//==========================================================

  always @(posedge clk)
    if (!xrst)
      qbits$ <= 0;
    else
      qbits$ <= _qbits;

  function signed [DWIDTH-1:0] round
    ( input signed [2*DWIDTH-1:0] data
    );
    if (data[2*DWIDTH-1] == 1)
      round = $signed(data >>> qbits$) - 1;
    else
      round = $signed(data >>> qbits$);
  endfunction

  // function signed [DWIDTH-1:0] round;
  //   input signed [2*DWIDTH-1:0] data;
  //   for (int i = 0; i < DWIDTH; i++) begin
  //     if (qbits$ == i) begin
  //       if (data[2*DWIDTH-1] == 1)
  //         round = $signed(data >>> i) - 1;
  //       else
  //         round = $signed(data >>> i);
  //     end
  //   end
  // endfunction

  // function signed [DWIDTH-1:0] round
  //   ( input signed [2*DWIDTH-1:0] data
  //   );
  //   if (data[2*DWIDTH-1] == 1)
  //     round = shift(data) - 1;
  //   else
  //     round = shift(data);
  // endfunction

  // function signed [DWIDTH-1:0] shift
  //   ( input signed [2*DWIDTH-1:0] data
  //   );
  //   for (int i = 0; i < DWIDTH; i++)
  //     if (qbits$ == i)
  //       shift = data >>> i;
  // endfunction

endmodule
