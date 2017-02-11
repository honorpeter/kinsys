`include "renkon.svh"

module serial_mat
  ( input                       clk
  , input                       xrst
  , input                       serial_we
  , input         [OUTSIZE-1:0] serial_addr
  , input         [CORELOG:0]   serial_re
  , input  signed [DWIDTH-1:0]  in_data [CORE-1:0]
  , output signed [DWIDTH-1:0]  out_data
  );

  wire signed [OUTSIZE-1:0] mem_addr [CORE-1:0];
  wire signed [DWIDTH-1:0]  mem_data [CORE-1:0];

  reg [CORELOG:0] r_serial_re;

  for (genvar i = 0; i < CORE; i++) begin
    assign mem_addr[i] = serial_re == 0 ? serial_addr
                       : serial_re == i+1 ? serial_addr
                       : 0;

    mem_sp #(DWIDTH, OUTSIZE) mem_serial(
      .read_data  (mem_data[i]),
      .write_data (in_data[i]),
      .mem_we     (serial_we),
      .mem_addr   (mem_addr[i]),
      .*
    );
  end

  always @(posedge clk)
    if (!xrst)
      r_serial_re <= 0;
    else
      r_serial_re <= serial_re;

  mux_output select_out(
    .output_re  (r_serial_re),
    .in_data    (mem_data),
    .out_data   (out_data),
    .*
  );

endmodule
