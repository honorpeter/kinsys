`include "renkon.svh"

module test_conv_tree9;

  localparam DATA_NUM = FSIZE**2;

  reg clk;
  reg signed [DWIDTH-1:0] mem_x [NUM-1:0][DATA_NUM-1:0];
  reg signed [DWIDTH-1:0] mem_w [NUM-1:0][DATA_NUM-1:0];
  reg signed [DWIDTH-1:0] mem_o [NUM-1:0];

  conv_tree9 dut(.*);

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
    for (int i = 0; i < FSIZE**2; i++) begin
      pixel[i]  = 0;
      weight[i] = 0;
    end

    read_x;
    read_w;
    #(STEP);

    for (int n = 0; n < NUM; n++) begin
      for (int i = 0; i < FSIZE**2; i++) begin
        pixel[i]  = mem_x[n][i];
        weight[i] = mem_w[n][i];
      end
      #(STEP*10);

      mem_o[n] = fmap;
      #(STEP);
    end

    save_o;
    $finish();
  end

  task read_x;
    begin // {{{
    end // }}}
  endtask

  task read_w;
    begin // {{{
    end // }}}
  endtask

  task save_o;
    begin // {{{
    end // }}}
  endtask

  //display
  always begin
    #(STEP/2-1);
    $display(
      "%d: ", $time/STEP,
      "| ",
    );
    #(STEP/2+1);
  end

endmodule
