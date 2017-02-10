`include "renkon.svh"

module mux_output
  ( input clk
  , input xrst
  , input [CORELOG:0] output_re
  , input signed [DWIDTH-1:0] in_data [CORE-1:0]
  , output signed [DWIDTH-1:0] out_data
  );

  reg signed [DWIDTH-1:0] r_data;

  assign out_data = r_data;

  for (genvar i = 0; i <= CORE; i++)
    if (i == CORE) begin
      always @(posedge clk)
        if (!xrst)
          r_data <= 0;
        else if (output_re > CORE)
          r_data <= 0;
    end
    else begin
      always @(posedge clk)
        if (output_re == i+1)
          r_data <= in_data[i];
    end

endmodule
