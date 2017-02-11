`include "renkon.svh"

// semi-auto generation by tree.rb
module conv_tree25
  ( input                      clk
  , input                      xrst
  , input  signed [DWIDTH-1:0] pixel  [25-1:0]
  , input  signed [DWIDTH-1:0] weight [25-1:0]
  , output signed [DWIDTH-1:0] fmap
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

  reg signed [DWIDTH-1:0]   r_pixel     [25-1:0];
  reg signed [DWIDTH-1:0]   r_weight    [25-1:0];
  reg signed [2*DWIDTH-1:0] r_pro       [25-1:0];
  reg signed [DWIDTH-1:0]   r_pro_short [25-1:0];
  reg signed [DWIDTH-1:0]   r_pro_short24_d;
  reg signed [DWIDTH-1:0]   r_sum0_0;
  reg signed [DWIDTH-1:0]   r_sum0_1;
  reg signed [DWIDTH-1:0]   r_sum0_2;
  reg signed [DWIDTH-1:0]   r_sum0_3;
  reg signed [DWIDTH-1:0]   r_sum0_4;
  reg signed [DWIDTH-1:0]   r_sum0_5;
  reg signed [DWIDTH-1:0]   r_sum0_6;
  reg signed [DWIDTH-1:0]   r_sum0_7;
  reg signed [DWIDTH-1:0]   r_sum0_8;
  reg signed [DWIDTH-1:0]   r_sum0_9;
  reg signed [DWIDTH-1:0]   r_sum0_10;
  reg signed [DWIDTH-1:0]   r_sum0_11;
  reg signed [DWIDTH-1:0]   r_sum1_0;
  reg signed [DWIDTH-1:0]   r_sum1_1;
  reg signed [DWIDTH-1:0]   r_sum1_2;
  reg signed [DWIDTH-1:0]   r_sum1_3;
  reg signed [DWIDTH-1:0]   r_sum1_4;
  reg signed [DWIDTH-1:0]   r_sum1_5;
  reg signed [DWIDTH-1:0]   r_sum2_0;
  reg signed [DWIDTH-1:0]   r_sum2_1;
  reg signed [DWIDTH-1:0]   r_sum2_2;
  reg signed [DWIDTH-1:0]   r_sum3_0;
  reg signed [DWIDTH-1:0]   r_sum3_1;
  reg signed [DWIDTH-1:0]   r_sum4_0;
  reg signed [DWIDTH-1:0]   r_fmap;

  for (genvar i = 0; i < 25; i++)
    assign pro[i] = r_pixel[i] * r_weight[i];

  for (genvar i = 0; i < 25; i++)
    assign pro_short[i] = round(r_pro[i]);

  assign sum0_0  = r_pro_short[0]  + r_pro_short[1];
  assign sum0_1  = r_pro_short[2]  + r_pro_short[3];
  assign sum0_2  = r_pro_short[4]  + r_pro_short[5];
  assign sum0_3  = r_pro_short[6]  + r_pro_short[7];
  assign sum0_4  = r_pro_short[8]  + r_pro_short[9];
  assign sum0_5  = r_pro_short[10] + r_pro_short[11];
  assign sum0_6  = r_pro_short[12] + r_pro_short[13];
  assign sum0_7  = r_pro_short[14] + r_pro_short[15];
  assign sum0_8  = r_pro_short[16] + r_pro_short[17];
  assign sum0_9  = r_pro_short[18] + r_pro_short[19];
  assign sum0_10 = r_pro_short[20] + r_pro_short[21];
  assign sum0_11 = r_pro_short[22] + r_pro_short[23];
  assign sum1_0 = sum0_0 + sum0_1;
  assign sum1_1 = sum0_2 + sum0_3;
  assign sum1_2 = sum0_4 + sum0_5;
  assign sum1_3 = sum0_6 + sum0_7;
  assign sum1_4 = sum0_8 + sum0_9;
  assign sum1_5 = sum0_10 + sum0_11;
  assign sum2_0 = sum1_0 + sum1_1;
  assign sum2_1 = sum1_2 + sum1_3;
  assign sum2_2 = sum1_4 + sum1_5;
  assign sum3_0 = r_sum2_0 + r_sum2_1;
  assign sum3_1 = r_sum2_2 + r_pro_short24_d;
  assign sum4_0 = sum3_0 + sum3_1;

  assign fmap = r_fmap;

  for (genvar i = 0; i < 25; i++) begin
    always @(posedge clk)
      if (!xrst)
        r_pixel[i] <= 0;
      else
        r_pixel[i] <= pixel[i];

    always @(posedge clk)
      if (!xrst)
        r_weight[i] <= 0;
      else
        r_weight[i] <= weight[i];

    always @(posedge clk)
      if (!xrst)
        r_pro[i] <= 0;
      else
        r_pro[i] <= pro[i];

    always @(posedge clk)
      if (!xrst)
        r_pro_short[i] <= 0;
      else
        r_pro_short[i] <= pro_short[i];
  end

  always @(posedge clk) begin
    r_sum2_0        <= sum2_0;
    r_sum2_1        <= sum2_1;
    r_sum2_2        <= sum2_2;
    r_pro_short24_d <= r_pro_short[24];
  end

  always @(posedge clk)
    if(!xrst)
      r_fmap <= 0;
    else
      r_fmap <= sum4_0;

////////////////////////////////////////////////////////////
//  Function
////////////////////////////////////////////////////////////

  function signed [DWIDTH-1:0] round;
    input [2*DWIDTH-1:0] data;
    if (data[2*DWIDTH-DWIDTH/2-2] == 1 && data[DWIDTH/2-1:0] == 0)
      round = $signed({
                data[2*DWIDTH-DWIDTH/2-2],
                data[2*DWIDTH-DWIDTH/2-2:DWIDTH/2] - 1
              });
    else
      round = $signed({
                data[2*DWIDTH-DWIDTH/2-2],
                data[2*DWIDTH-DWIDTH/2-2:DWIDTH/2]
              });
  endfunction

endmodule
