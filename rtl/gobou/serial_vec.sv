// TODO: Eliminate erb

module serial_vec
  ( input                     clk
  , input                     xrst
  , input                     serial_we;
  <%- $core.times do |i| -%>
  , input signed [DWIDTH-1:0] in_data<%=i%>;
  <%- end -%>
  , output signed [DWIDTH-1:0]  out_data
  );

  reg [LWIDTH-1:0]        r_cnt;
  <%- $core.times do |i| -%>
  reg signed [DWIDTH-1:0] r_data<%=i%>;
  <%- end -%>

  assign out_data = r_data0;

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

  for (genvar i=0; i < CORE; i++)
    always @(posedge clk)
      if (!xrst)
        r_data

endmodule
