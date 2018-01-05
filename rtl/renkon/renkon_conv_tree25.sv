`include "renkon.svh"

// semi-auto generation by tree.rb
module renkon_conv_tree25
  ( input                       clk
  , input                       xrst
  , input  [LWIDTH-1:0]         _qbits
  , input  signed [DWIDTH-1:0]  pixel  [25-1:0]
  , input  signed [DWIDTH-1:0]  weight [25-1:0]
  , output signed [DWIDTH-1:0]  fmap
  );

  wire signed [2*DWIDTH-1:0] pro       [25-1:0];
  wire signed [DWIDTH-1:0]   pro_short [25-1:0];
  wire signed [DWIDTH-1:0]   sum0_0;
  wire signed [DWIDTH-1:0]   sum0_1;
  wire signed [DWIDTH-1:0]   sum0_2;
  wire signed [DWIDTH-1:0]   sum0_3;
  wire signed [DWIDTH-1:0]   sum0_4;
  wire signed [DWIDTH-1:0]   sum0_5;
  wire signed [DWIDTH-1:0]   sum0_6;
  wire signed [DWIDTH-1:0]   sum0_7;
  wire signed [DWIDTH-1:0]   sum0_8;
  wire signed [DWIDTH-1:0]   sum0_9;
  wire signed [DWIDTH-1:0]   sum0_10;
  wire signed [DWIDTH-1:0]   sum0_11;
  wire signed [DWIDTH-1:0]   sum1_0;
  wire signed [DWIDTH-1:0]   sum1_1;
  wire signed [DWIDTH-1:0]   sum1_2;
  wire signed [DWIDTH-1:0]   sum1_3;
  wire signed [DWIDTH-1:0]   sum1_4;
  wire signed [DWIDTH-1:0]   sum1_5;
  wire signed [DWIDTH-1:0]   sum2_0;
  wire signed [DWIDTH-1:0]   sum2_1;
  wire signed [DWIDTH-1:0]   sum2_2;
  wire signed [DWIDTH-1:0]   sum3_0;
  wire signed [DWIDTH-1:0]   sum3_1;
  wire signed [DWIDTH-1:0]   sum4_0;

  reg signed [DWIDTH-1:0]   pixel$     [25-1:0];
  reg signed [DWIDTH-1:0]   weight$    [25-1:0];
  reg signed [2*DWIDTH-1:0] pro$       [25-1:0];
  reg signed [DWIDTH-1:0]   pro_short$ [25-1:0];
  reg signed [DWIDTH-1:0]   pro_short24_d1$;
  reg signed [DWIDTH-1:0]   sum0_0$;
  reg signed [DWIDTH-1:0]   sum0_1$;
  reg signed [DWIDTH-1:0]   sum0_2$;
  reg signed [DWIDTH-1:0]   sum0_3$;
  reg signed [DWIDTH-1:0]   sum0_4$;
  reg signed [DWIDTH-1:0]   sum0_5$;
  reg signed [DWIDTH-1:0]   sum0_6$;
  reg signed [DWIDTH-1:0]   sum0_7$;
  reg signed [DWIDTH-1:0]   sum0_8$;
  reg signed [DWIDTH-1:0]   sum0_9$;
  reg signed [DWIDTH-1:0]   sum0_10$;
  reg signed [DWIDTH-1:0]   sum0_11$;
  reg signed [DWIDTH-1:0]   sum1_0$;
  reg signed [DWIDTH-1:0]   sum1_1$;
  reg signed [DWIDTH-1:0]   sum1_2$;
  reg signed [DWIDTH-1:0]   sum1_3$;
  reg signed [DWIDTH-1:0]   sum1_4$;
  reg signed [DWIDTH-1:0]   sum1_5$;
  reg signed [DWIDTH-1:0]   sum2_0$;
  reg signed [DWIDTH-1:0]   sum2_1$;
  reg signed [DWIDTH-1:0]   sum2_2$;
  reg signed [DWIDTH-1:0]   sum3_0$;
  reg signed [DWIDTH-1:0]   sum3_1$;
  reg signed [DWIDTH-1:0]   sum4_0$;
  reg signed [DWIDTH-1:0]   fmap$;

  for (genvar i = 0; i < 25; i++)
    assign pro[i] = pixel$[i] * weight$[i];

  for (genvar i = 0; i < 25; i++)
    assign pro_short[i] = round(pro$[i]);

  assign sum0_0  = pro_short$[0]  + pro_short$[1];
  assign sum0_1  = pro_short$[2]  + pro_short$[3];
  assign sum0_2  = pro_short$[4]  + pro_short$[5];
  assign sum0_3  = pro_short$[6]  + pro_short$[7];
  assign sum0_4  = pro_short$[8]  + pro_short$[9];
  assign sum0_5  = pro_short$[10] + pro_short$[11];
  assign sum0_6  = pro_short$[12] + pro_short$[13];
  assign sum0_7  = pro_short$[14] + pro_short$[15];
  assign sum0_8  = pro_short$[16] + pro_short$[17];
  assign sum0_9  = pro_short$[18] + pro_short$[19];
  assign sum0_10 = pro_short$[20] + pro_short$[21];
  assign sum0_11 = pro_short$[22] + pro_short$[23];
  assign sum1_0 = sum0_0 + sum0_1;
  assign sum1_1 = sum0_2 + sum0_3;
  assign sum1_2 = sum0_4 + sum0_5;
  assign sum1_3 = sum0_6 + sum0_7;
  assign sum1_4 = sum0_8 + sum0_9;
  assign sum1_5 = sum0_10 + sum0_11;
  assign sum2_0 = sum1_0 + sum1_1;
  assign sum2_1 = sum1_2 + sum1_3;
  assign sum2_2 = sum1_4 + sum1_5;
  assign sum3_0 = sum2_0$ + sum2_1$;
  assign sum3_1 = sum2_2$ + pro_short24_d1$;
  assign sum4_0 = sum3_0 + sum3_1;

  assign fmap = fmap$;

  for (genvar i = 0; i < 25; i++) begin
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
    if (!xrst) begin
      sum2_0$         <= 0;
      sum2_1$         <= 0;
      sum2_2$         <= 0;
      pro_short24_d1$ <= 0;
    end
    else begin
      sum2_0$         <= sum2_0;
      sum2_1$         <= sum2_1;
      sum2_2$         <= sum2_2;
      pro_short24_d1$ <= pro_short$[24];
    end

  always @(posedge clk)
    if(!xrst)
      fmap$ <= 0;
    else
      fmap$ <= sum4_0;

//==========================================================
//  Function
//==========================================================

  reg [LWIDTH-1:0] qbits$;
  always @(posedge clk)
    if (!xrst)
      qbits$ <= 0;
    else
      qbits$ <= _qbits;

  // parameter QBITS=DWIDTH/2;
  function signed [DWIDTH-1:0] round;
    input signed [2*DWIDTH-1:0] data;
    // if (data[DWIDTH+QBITS-1-1] == 1 && data[QBITS-1:0] == 0)
    //   round = $signed({
    //             data[DWIDTH+QBITS-1-1],
    //             data[DWIDTH+QBITS-1-1:QBITS] - 1'b1
    //           });
    // else
    //   round = $signed({
    //             data[DWIDTH+QBITS-1-1],
    //             data[DWIDTH+QBITS-1-1:QBITS]
    //           });
    if (data[2*DWIDTH-1] == 1)
      round = $signed(data >> qbits$) - 1;
    else
      round = $signed(data >> qbits$);
  endfunction

endmodule
