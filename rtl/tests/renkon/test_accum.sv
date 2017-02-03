`include "renkon.svh"

module test_accum;

  reg                     clk;
  reg                     xrst;
  reg                     reset;
  reg                     out_en;
  reg signed [DWIDTH-1:0] pixel_in;
  reg signed [DWIDTH-1:0] sum_old;
  reg signed [DWIDTH-1:0] pixel_out;
  reg signed [DWIDTH-1:0] sum_new;

  accum dut(.*);

  // clock
  initial begin
    clk = 0;
    forever
      #(STEP/2) clk = ~clk;
  end

  //flow
  initial begin
    $display("reset out_en | pixel_in sum_old | total sum_new");
    #(STEP);

    //xrst = 0;
    out_en = 0;
    pixel_in = 0;
    sum_old = 0;
    #(STEP);

    reset = 1;
    pixel_in = 5;
    sum_old = 170;
    #(STEP);

    reset = 0;
    #(STEP*2);

    out_en = 1;
    #(STEP*2);

    pixel_in = 7;
    #(STEP*2);

    out_en = 0;
    pixel_in = 0;
    #(STEP*2);

    $finish();
  end

  //display
  always begin
    #(STEP/2-1);
    $display(
      "%d: ", $time/STEP,
      "| ",
      "%5d ", reset,
      "%4d ", out_en,
      "| ",
      "%6d ", pixel_in,
      "%7d ", sum_old,
      "| ",
      "%5d ", pixel_out,
      "%6d ", sum_new
    );
    #(STEP/2+1);
  end

endmodule
