`include "renkon.svh"

module renkon_conv_wreg
  ( input                      clk
  , input                      xrst
  , input                      wreg_we
  , input  signed [DWIDTH-1:0] read_weight
  , output signed [DWIDTH-1:0] weight [FSIZE**2-1:0]
  );

  reg signed [DWIDTH-1:0] weight$ [FSIZE**2-1:0];

  for (genvar i = 0; i < FSIZE**2; i++)
    assign weight[i] = weight$[i];

  for (genvar i = 0; i < FSIZE**2; i++)
    if (i == FSIZE**2 - 1) begin
      always @(posedge clk)
        if (!xrst)
          weight$[i] <= 0;
        else if (wreg_we)
          weight$[i] <= read_weight;
    end
    else begin
      always @(posedge clk)
        if (!xrst)
          weight$[i] <= 0;
        else if (wreg_we)
          weight$[i] <= weight$[i+1];
    end

endmodule
