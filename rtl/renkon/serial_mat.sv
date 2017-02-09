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

  for (genvar i = 0; i < CORE; i++) begin
    assign w_serial_addr[i] = serial_re = 0 ? serial_addr
                            : serial_re = i+1 ? serial_addr
                            : 0;

    mem_sp #(DWIDTH, OUTSIZE) mem_serial(
    );
  end

  always @(posedge clk)
    if (!xrst)
      r_serial_re <= 0;
    else
      r_serial_re <= serial_re;

  mux_output select_out(
  );

endmodule
