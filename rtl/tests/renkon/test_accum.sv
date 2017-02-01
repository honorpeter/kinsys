`include "renkon.svh"

module test_accum;

  reg clk;

  accum dut(.*);

  // clock
  initial begin
    clk = 0;
    forever
      #(STEP/2) clk = ~clk;
  end

  //flow
  initial
  begin
    $display("reset out_en | result sum_old | total sum_new");
    #(STEP);

    //xrst = 0;
    out_en = 0;
    result = 0;
    sum_old = 0;
    #(STEP);

    reset = 1;
    result = 5;
    sum_old = 170;
    #(STEP);

    reset = 0;
    #(STEP*2);

    out_en = 1;
    #(STEP*2);

    result = 7;
    #(STEP*2);

    out_en = 0;
    result = 0;
    #(STEP*2);

    $finish();
  end

  //display
  always
  begin
    #(STEP/2-1);
    $display(
      "%d: ", $time/STEP,
      "| ",
      "%5d ", reset,
      "%4d | ", out_en,
      "%6d ", result,
      "%7d | ", sum_old,
      "%5d ", total,
      "%6d ", sum_new
    );
    #(STEP/2+1);
  end

endmodule
