`include "renkon.svh"

module renkon_mux_output
  ( input clk
  , input xrst
  , input [RENKON_CORELOG:0] output_re
  , input signed [DWIDTH-1:0] in_data [RENKON_CORE-1:0]
  , output signed [DWIDTH-1:0] out_data
  );

  wire signed [DWIDTH-1:0] mux [2**(RENKON_CORELOG+1)-1:0];

  reg signed [DWIDTH-1:0] r_data;

  assign out_data = r_data;

  // for (genvar i = 0; i <= RENKON_CORE; i++)
  //   if (i == RENKON_CORE) begin
  //     always @(posedge clk)
  //       if (!xrst)
  //         r_data <= 0;
  //       else if (output_re > RENKON_CORE)
  //         r_data <= 0;
  //   end
  //   else begin
  //     always @(posedge clk)
  //       if (output_re == i+1)
  //         r_data <= in_data[i];
  //   end

  for (genvar i = -1; i < 2**(RENKON_CORELOG+1)-1; i++)
    if (i == -1)
      assign mux[0] = 0;
    else if (i < RENKON_CORE)
      assign mux[i+1] = in_data[i];
    else
      assign mux[i+1] = 0;

  always @(posedge clk)
    if (!xrst)
      r_data <= 0;
    else
      r_data <= mux[output_re];

endmodule