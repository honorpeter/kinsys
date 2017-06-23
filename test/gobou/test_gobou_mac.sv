`include "gobou.svh"

module test_gobou_mac;

  reg                     clk;
  reg                     xrst;
  reg                     out_en;
  reg                     accum_we;
  reg                     reset;
  reg signed [DWIDTH-1:0] x;
  reg signed [DWIDTH-1:0] w;
  reg signed [DWIDTH-1:0] y;

  gobou_mac dut(.*);

  // clock
  initial begin
    clk = 0;
    forever
      #(STEP/2) clk = ~clk;
  end

  //flow
  initial
  begin
    xrst = 0;
    #(STEP);

    xrst      = 1;
    out_en    = 0;
    accum_we  = 0;
    reset     = 0;
    x         = 0;
    w         = 0;
    #(STEP);

    for (int i = 0; i < 5; i++) begin
      x = i * 256;
      w = i * 256;
      #(STEP);
    end

    x = 5 * 256;
    w = 0 * 256;
    #(STEP);
    accum_we = 1;

    for (int i = 6; i < 10; i++) begin
      x = i * 256;
      w = (i-5) * 256;
      #(STEP);
    end

    x = 10 * 256;
    w = 5 * 256;
    #(STEP);
    accum_we = 0;

    out_en = 1;
    #(STEP);

    out_en = 0;

    reset = 1;
    #(STEP);

    reset = 0;
    #(STEP);

    #(STEP*5);

    $finish();
  end

  //display
  always
  begin
    #(STEP/2-1);
    $display(
      "%d: ", $time/STEP,
      "%d ", xrst,
      "| ",
      "%d ", out_en,
      "%d ", accum_we,
      "%d ", reset,
      "%x ", x,
      "%x ", w,
      "| ",
      "%d ", y,
      "| ",
      "%d ", dut.pro,
      "%d ", dut.pro_short,
      "%d ", dut.pro_short / 256,
      "| ",
      "%d ", dut.x$,
      "%d ", dut.w$,
      "%d ", dut.y$,
      "%d ", dut.accum$,
      "|"
    );
    #(STEP/2+1);
  end

endmodule
