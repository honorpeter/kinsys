`include "renkon.svh"

// semi-auto generation by tree.rb
module renkon_conv_tree9
  ( input                      clk
  , input                      xrst
  , input  [DWIDTHLOG-1:0]     _qbits
  , input  signed [DWIDTH-1:0] pixel  [9-1:0]
  , input  signed [DWIDTH-1:0] weight [9-1:0]
  , output signed [DWIDTH-1:0] fmap
  );

  wire signed [2*DWIDTH-1:0] pro       [9-1:0];
  wire signed [DWIDTH-1:0]   pro_short [9-1:0];
  wire signed [DWIDTH-1:0]   sum0_0;
  wire signed [DWIDTH-1:0]   sum0_1;
  wire signed [DWIDTH-1:0]   sum0_2;
  wire signed [DWIDTH-1:0]   sum0_3;
  wire signed [DWIDTH-1:0]   sum1_0;
  wire signed [DWIDTH-1:0]   sum1_1;
  wire signed [DWIDTH-1:0]   sum2_0;
  wire signed [DWIDTH-1:0]   sum3_0;

  reg [DWIDTHLOG-1:0]       qbits$;
  reg signed [DWIDTH-1:0]   pixel$     [9-1:0];
  reg signed [DWIDTH-1:0]   weight$    [9-1:0];
  reg signed [2*DWIDTH-1:0] pro$       [9-1:0];
  reg signed [DWIDTH-1:0]   pro_short$ [9-1:0];
  reg signed [DWIDTH-1:0]   sum0_0$;
  reg signed [DWIDTH-1:0]   sum0_1$;
  reg signed [DWIDTH-1:0]   sum0_2$;
  reg signed [DWIDTH-1:0]   sum0_3$;
  reg signed [DWIDTH-1:0]   sum1_0$;
  reg signed [DWIDTH-1:0]   sum1_1$;
  reg signed [DWIDTH-1:0]   sum2_0$;
  reg signed [DWIDTH-1:0]   sum3_0$;
  reg signed [DWIDTH-1:0]   fmap$;

  for (genvar i = 0; i < 9; i++)
    assign pro[i] = pixel$[i] * weight$[i];

  for (genvar i = 0; i < 9; i++)
    // rounder16c rnd(.x(pro$[i]), .qbits(qbits$), .y(pro_short[i]), .*);
    assign pro_short[i] = round(pro$[i]);

  assign sum0_0 = pro_short$[0] + pro_short$[1];
  assign sum0_1 = pro_short$[2] + pro_short$[3];
  assign sum0_2 = pro_short$[4] + pro_short$[5];
  assign sum0_3 = pro_short$[6] + pro_short$[7];
  assign sum1_0 = sum0_0 + sum0_1;
  assign sum1_1 = sum0_2 + sum0_3;
  assign sum2_0 = sum1_0 + sum1_1;
  assign sum3_0 = sum2_0 + pro_short$[8];

  assign fmap = fmap$;

  for (genvar i = 0; i < 9; i++) begin
    always @(posedge clk)
      if (!xrst)
        pixel$[i] <= 0;
      else
        pixel$[i] <= pixel[i];

    always @(posedge clk)
      if (!xrst)
        weight$[i] <= 0;
      else
        weight$[i] <= weight[i];

    always @(posedge clk)
      if (!xrst)
        pro$[i] <= 0;
      else
        pro$[i] <= pro[i];

    always @(posedge clk)
      if (!xrst)
        pro_short$[i] <= 0;
      else
        pro_short$[i] <= pro_short[i];
  end

  always @(posedge clk)
    if(!xrst)
      fmap$ <= 0;
    else
      fmap$ <= sum3_0;

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
  //   case (qbits$)
  //     0:  shift = data >>> 0;
  //     1:  shift = data >>> 1;
  //     2:  shift = data >>> 2;
  //     3:  shift = data >>> 3;
  //     4:  shift = data >>> 4;
  //     5:  shift = data >>> 5;
  //     6:  shift = data >>> 6;
  //     7:  shift = data >>> 7;
  //     8:  shift = data >>> 8;
  //     9:  shift = data >>> 9;
  //     10: shift = data >>> 10;
  //     11: shift = data >>> 11;
  //     12: shift = data >>> 12;
  //     13: shift = data >>> 13;
  //     14: shift = data >>> 14;
  //     15: shift = data >>> 15;
  //   endcase
  // endfunction

endmodule
