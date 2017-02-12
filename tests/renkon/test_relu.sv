`include "renkon.svh"

module test_relu;

  reg                     clk;
  reg                     xrst;
  reg                     out_en;
  reg signed [DWIDTH-1:0] pixel_in;
  reg signed [DWIDTH-1:0] pixel_out;

  relu dut(.*);

  // clock
  initial begin
    clk = 0;
    forever
      #(STEP/2) clk = ~clk;
  end

  //flow
  initial begin
    xrst = 0;
    #(STEP);

    xrst = 1;
    out_en = 0;
    pixel_in = 0;
    #(STEP);

    for (int i = 0; i < 30; i++) begin
      pixel_in = i;
      if (i < 10)
        out_en = 0;
      else if (10 <= i && i < 20)
        out_en = 1;
      else if (20 <= i && i < 30)
        out_en = 0;
      #(STEP);
    end

    $finish();
  end

  //display
  initial begin
    $display("clk: xrst | out_en | pixel_in | pixel_out |");
    forever begin
      #(STEP/2-1);
      $display(
        "%d: ", $time/STEP,
        "%d ", xrst,
        "| ",
        "%d ", out_en,
        "| ",
        "%d ", pixel_in,
        "| ",
        "%d ", pixel_out,
        "|"
      );
      #(STEP/2+1);
    end
  end

endmodule
