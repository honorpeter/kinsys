`include "renkon.svh"

// semi-auto generation by tree.rb
module renkon_conv_tree9
  ( input                      clk
  , input                      xrst
  , input  [LWIDTH-1:0]        _qbits
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

  reg [LWIDTH-1:0] qbits$;
  always @(posedge clk)
    if (!xrst)
      qbits$ <= 0;
    else
      qbits$ <= _qbits;
  parameter QBITS=DWIDTH/2;
  function signed [DWIDTH-1:0] round;
    input signed [2*DWIDTH-1:0] data;
    `ifdef NODEF
    if (data[DWIDTH+QBITS-1-1] == 1 && data[QBITS-1:0] == 0)
      round = $signed({
                data[DWIDTH+QBITS-1-1],
                data[DWIDTH+QBITS-1-1:QBITS]
              }) - 1'b1;
    else
      round = $signed({
                data[DWIDTH+QBITS-1-1],
                data[DWIDTH+QBITS-1-1:QBITS]
              });
    `else
    if (data[2*DWIDTH-1] == 1)
      round = $signed(data >> qbits$) - 1;
    else
      round = $signed(data >> qbits$);
    `endif
  endfunction

endmodule
