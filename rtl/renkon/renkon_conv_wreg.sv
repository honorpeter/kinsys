`include "renkon.svh"

module renkon_conv_wreg
  ( input                      clk
  , input                      xrst
  , input                      wreg_we
  , input  signed [DWIDTH-1:0] read_weight
  , output signed [DWIDTH-1:0] weight [FSIZE**2-1:0]
  );

  reg signed [DWIDTH-1:0] r_weight [FSIZE**2-1:0];

  for (genvar i = 0; i < FSIZE**2; i++)
    assign weight[i] = r_weight[i];

  for (genvar i = 0; i < FSIZE**2; i++)
    if (i == FSIZE**2 - 1) begin
      always @(posedge clk)
        if (!xrst)
          r_weight[i] <= 0;
        else if (wreg_we)
          r_weight[i] <= read_weight;
    end
    else begin
      always @(posedge clk)
        if (!xrst)
          r_weight[i] <= 0;
        else if (wreg_we)
          r_weight[i] <= r_weight[i+1];
    end

endmodule
