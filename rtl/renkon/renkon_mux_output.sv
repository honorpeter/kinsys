`include "renkon.svh"

module renkon_mux_output
  ( input                      clk
  , input                      xrst
  , input  [RENKON_CORELOG:0]  output_re
  , input  signed [DWIDTH-1:0] in_data [RENKON_CORE-1:0]
  , output signed [DWIDTH-1:0] out_data
  );

  wire signed [DWIDTH-1:0] mux [2**(RENKON_CORELOG+1)-1:0];

  reg signed [DWIDTH-1:0] data$;

  assign out_data = data$;

  for (genvar i = -1; i < 2**(RENKON_CORELOG+1)-1; i++)
    if (i == -1)
      assign mux[0] = 0;
    else if (i < RENKON_CORE)
      assign mux[i+1] = in_data[i];
    else
      assign mux[i+1] = 0;

  always @(posedge clk)
    if (!xrst)
      data$ <= 0;
    else
      data$ <= mux[output_re];

endmodule
