`include "gobou.svh"

module gobou_serial_vec
  ( input                       clk
  , input                       xrst
  , input                       serial_we
  , input  signed [DWIDTH-1:0]  in_data [GOBOU_CORE-1:0]
  , output signed [DWIDTH-1:0]  out_data
  );

  reg [LWIDTH-1:0]        cnt$;
  reg signed [DWIDTH-1:0] data$ [GOBOU_CORE-1:0];

  assign out_data = data$[0];

  always @(posedge clk)
    if (!xrst)
      cnt$ <= 0;
    else if (serial_we)
      cnt$ <= 1;
    else if (cnt$ > 0)
      if (cnt$ == GOBOU_CORE)
        cnt$ <= 0;
      else
        cnt$ <= cnt$ + 1;

    for (genvar i = 0; i < GOBOU_CORE; i++)
      if (i == GOBOU_CORE - 1)
        always @(posedge clk)
          if (!xrst)
            data$[i] <= 0;
          else if (serial_we)
            data$[i] <= in_data[i];
          else
            data$[i] <= 0;
      else
        always @(posedge clk)
          if (!xrst)
            data$[i] <= 0;
          else if (serial_we)
            data$[i] <= in_data[i];
          else
            data$[i] <= data$[i+1];

endmodule
