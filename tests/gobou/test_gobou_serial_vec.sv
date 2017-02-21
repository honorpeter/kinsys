`include "gobou.svh"

module test_gobou_serial_vec;

  reg                      clk;
  reg                      xrst;
  reg                      serial_we;
  reg signed [DWIDTH-1:0]  in_data [CORE-1:0];
  reg signed [DWIDTH-1:0]  out_data;

  gobou_serial_vec dut(.*);

  // clock
  initial begin
    clk = 0;
    forever
      #(STEP/2) clk = ~clk;
  end

  // flow
  initial begin
    xrst = 0;
    #(STEP);
    xrst = 1;
    #(STEP);
    serial_we = 1;
    for (int i = 0; i < CORE; i++)
      in_data[i] = i;
    #(STEP);
    serial_we = 0;
    #(STEP*10);
    $finish();
  end

  // display
  always @(posedge clk) begin
    #(STEP/2-1);
    $display(
      "%2d: ", $time/STEP,
      "%d ", xrst,
      "%d ", serial_we,
      "| ",
      "%2d ", in_data[0],
      "%2d ", in_data[1],
      "%2d ", in_data[2],
      "%2d ", in_data[3],
      "%2d ", in_data[4],
      "%2d ", in_data[5],
      "%2d ", in_data[6],
      "%2d ", in_data[7],
      "| ",
      "%2d ", out_data,
      "|"
    );
    #(STEP/2+1);
  end

endmodule

