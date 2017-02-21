`include "renkon.svh"

module test_renkon_bias;

  reg                     clk;
  reg                     xrst;
  reg                     breg_we;
  reg                     out_en;
  reg signed [DWIDTH-1:0] read_bias;
  reg signed [DWIDTH-1:0] pixel_in;
  reg signed [DWIDTH-1:0] pixel_out;

  renkon_bias dut(.*);

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
    breg_we = 0;
    out_en = 0;
    read_bias = 0;
    pixel_in = 0;
    #(STEP);

    read_bias = 10;
    #(STEP*2);

    breg_we = 1;
    #(STEP);
    breg_we = 0;

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
    $display("clk: xrst | breg_we out_en | read_bias pixel_in | pixel_out |");
    forever begin
      #(STEP/2-1);
      $display(
        "%d: ", $time/STEP,
        "%d ", xrst,
        "| ",
        "%d ", breg_we,
        "%d ", out_en,
        "| ",
        "%d ", read_bias,
        "%d ", pixel_in,
        "| ",
        "%d ", pixel_out,
        "|"
      );
      #(STEP/2+1);
    end
  end

endmodule
