`include "gobou.svh"

module serial_vec
  ( input                       clk
  , input                       xrst
  , input                       serial_we
  , input  signed [DWIDTH-1:0]  in_data [CORE-1:0]
  , output signed [DWIDTH-1:0]  out_data
  );

  reg [LWIDTH-1:0]        r_cnt;
  reg signed [DWIDTH-1:0] r_data [CORE-1:0];

  assign out_data = r_data[0];

  always @(posedge clk or negedge xrst)
    if (!xrst)
      r_cnt <= 0;
    else if (serial_we)
      r_cnt <= 1;
    else if (r_cnt > 0)
      if (r_cnt == CORE)
        r_cnt <= 0;
      else
        r_cnt <= r_cnt + 1;

    for (genvar i = 0; i < CORE; i++)
      always @(posedge clk)
        if (!xrst)
          r_data[i] <= 0;
        else if (serial_we)
          r_data[i] <= in_data[i];
        else
          if (i == CORE - 1)
            r_data[i] <= 0;
          else
            r_data[i] <= r_data[i+1];

endmodule
