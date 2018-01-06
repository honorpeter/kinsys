`include "renkon.svh"

module renkon_conv_wreg
  ( input                       clk
  , input                       xrst
  , input  [CONV_MAX-1:0]       wreg_we
  , input  signed [DWIDTH-1:0]  read_weight
  , output signed [DWIDTH-1:0]  weight [CONV_MAX**2-1:0]
  );

  reg signed [DWIDTH-1:0] weight$ [CONV_MAX-1:0][CONV_MAX-1:0];

  for (genvar i = 0; i < CONV_MAX; i++) begin
    for (genvar j = 0; j < CONV_MAX; j++) begin
      assign weight[CONV_MAX*i+j] = weight$[i][j];

      if (j == CONV_MAX - 1) begin
        always @(posedge clk)
          if (!xrst)
            weight$[i][j] <= 0;
          else if (wreg_we[i])
            weight$[i][j] <= read_weight;
      end
      else begin
        always @(posedge clk)
          if (!xrst)
            weight$[i][j] <= 0;
          else if (wreg_we[i])
            weight$[i][j] <= weight$[i][j+1];
      end
    end
  end

endmodule
