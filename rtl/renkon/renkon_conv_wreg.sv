`include "renkon.svh"

module renkon_conv_wreg
  ( input                           clk
  , input                           xrst
  , input  [$clog2(CONV_KERN+1):0]  wreg_we
  , input  signed [DWIDTH-1:0]      read_weight
  , output signed [DWIDTH-1:0]      weight [CONV_KERN**2-1:0]
  );

  reg signed [DWIDTH-1:0] weight$ [CONV_KERN-1:0][CONV_KERN-1:0];

  for (genvar i = 0; i < CONV_KERN; i++) begin
    for (genvar j = 0; j < CONV_KERN; j++) begin
      assign weight[CONV_KERN*i+j] = weight$[i][j];

      if (j == CONV_KERN - 1) begin
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
