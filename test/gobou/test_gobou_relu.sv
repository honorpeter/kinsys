`include "gobou.svh"

module test_gobou_relu;

  reg clk;

  gobou_relu dut(.*);

  // clock
  initial begin
    clk = 0;
    forever
      #(STEP/2) clk = ~clk;
  end

  //flow
  initial begin

    $finish();
  end

  //display
  initial begin
    $display("clk: |");
    forever begin
      #(STEP/2-1);
      $display(
        "%d: ", $time/STEP,
        "| ",

        "|"
      );
      #(STEP/2+1);
    end
  end

endmodule
