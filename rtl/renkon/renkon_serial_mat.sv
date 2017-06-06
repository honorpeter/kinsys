`include "renkon.svh"

module renkon_serial_mat
  ( input                       clk
  , input                       xrst
  , input                       serial_we
  , input  [OUTSIZE-1:0]        serial_addr
  , input  [RENKON_CORELOG:0]   serial_re
  , input  signed [DWIDTH-1:0]  in_data [RENKON_CORE-1:0]
  , output signed [DWIDTH-1:0]  out_data
  );

  wire signed [OUTSIZE-1:0] mem_addr [RENKON_CORE-1:0];
  wire signed [DWIDTH-1:0]  mem_data [RENKON_CORE-1:0];

  reg [RENKON_CORELOG:0] r_serial_re;

  for (genvar i = 0; i < RENKON_CORE; i++) begin
    assign mem_addr[i] = serial_re == 0 ? serial_addr
                       : serial_re == i+1 ? serial_addr
                       : 0;

    mem_sp #(DWIDTH, OUTSIZE) mem_serial(
      .mem_we     (serial_we),
      .mem_addr   (mem_addr[i]),
      .mem_wdata  (in_data[i]),
      .mem_rdata  (mem_data[i]),
      .*
    );
  end

  always @(posedge clk)
    if (!xrst)
      r_serial_re <= 0;
    else
      r_serial_re <= serial_re;

  renkon_mux_output select_out(
    .output_re  (r_serial_re),
    .in_data    (mem_data),
    .out_data   (out_data),
    .*
  );

endmodule
