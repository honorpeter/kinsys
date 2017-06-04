`include "renkon.svh"

parameter NUMBER = 1000;

module test_renkon_conv_tree25;

  reg                     clk;
  reg                     xrst;
  reg signed [DWIDTH-1:0] pixel  [25-1:0];
  reg signed [DWIDTH-1:0] weight [25-1:0];
  reg signed [DWIDTH-1:0] fmap;

  reg signed [DWIDTH-1:0] mem_images [NUMBER-1:0][25-1:0];
  reg signed [DWIDTH-1:0] mem_filters [NUMBER-1:0][25-1:0];

  renkon_conv_tree25 dut(.*);

  // clock
  initial begin
    clk = 0;
    forever
      #(STEP/2) clk = ~clk;
  end

  //flow
  initial begin
    xrst = 0;
    read_input;
    read_filter;
    #(STEP);

    xrst = 1;
    for (int i = 0; i < 25; i++) begin
      pixel[i] = 0;
      weight[i] = 0;
    end
    #(STEP);

    for (int n = 0; n < NUMBER; n++) begin
      for (int i = 0; i < 25; i++) begin
        pixel[i] = mem_images[n][i];
        weight[i] = mem_filters[n][i];
      end
      #(STEP);
    end
    #(STEP*10);

    $finish();
  end

  task read_input;
    int fd;
    int r;
    begin // {{{
      fd = $fopen("../../data/renkon/input_conv_tree25.dat", "r");

      for (int n = 0; n < NUMBER; n++)
        for (int i = 0; i < 25; i++)
          r = $fscanf(fd, "%x", mem_images[n][i]);

      $fclose(fd);
    end // }}}
  endtask

  task read_filter;
    int fd;
    int r;
    begin // {{{
      fd = $fopen("../../data/renkon/filter_conv_tree25.dat", "r");

      for (int n = 0; n < NUMBER; n++)
        for (int i = 0; i < 25; i++)
          r = $fscanf(fd, "%x", mem_filters[n][i]);

      $fclose(fd);
    end // }}}
  endtask

  initial write_output;
  task write_output;
    int fd;
    begin // {{{
      fd = $fopen("../../data/renkon/output_conv_tree25.dat", "w");

      #(STEP*2);
      #(STEP*D_CONV);
      for (int i = 0; i < NUMBER; i++) begin
        $fdisplay(fd, "%0d", fmap);
        #(STEP);
      end

      $fclose(fd);
    end // }}}
  endtask

  //display
  initial begin
    $display("clk: | xrst, pixel[0], weight[0], fmap |");
    forever begin
      #(STEP/2-1);
      $display(
        "%5d: ", $time/STEP,
        "| ",
        "%d ", xrst,
        "%d ", pixel[0],
        "%d ", pixel[24],
        "%d ", weight[0],
        "%d ", weight[24],
        "%d ", fmap,
        "|"
      );
      #(STEP/2+1);
    end
  end

endmodule
