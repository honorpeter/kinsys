`include "renkon.svh"

parameter IMAGE = 12;
parameter FILTER = 2;

module test_renkon_pool;

  reg                     clk;
  reg                     xrst;
  reg                     out_en;
  reg                     buf_feat_en;
  reg        [LWIDTH-1:0] w_fea_size;
  reg        [LWIDTH-1:0] w_pool_size;
  reg signed [DWIDTH-1:0] pixel_in;
  reg signed [DWIDTH-1:0] pixel_out;

  reg signed [DWIDTH-1:0] mem_input [IMAGE**2-1:0];

  renkon_pool dut(.*);

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
    #(STEP);

    xrst = 1;
    out_en = 0;
    buf_feat_en = 1;
    w_fea_size = IMAGE;
    w_pool_size = FILTER;
    pixel_in = 0;
    #(STEP);

    buf_feat_en = 0;
    out_en = 1;
    for (int i = 1; i < IMAGE**2; i++) begin
      pixel_in = mem_input[i];
      #(STEP);
    end
    #(STEP*32);

    $finish();
  end

  task read_input;
    $readmemh("../../data/renkon/input_linebuf.dat", mem_input);
  endtask

  //display
  initial begin
    $display("clk: |");
    forever begin
      #(STEP/2-1);
      $display(
        "%d: ", $time/STEP,
        "|i: ",
        "%d ", xrst,
        "%d ", out_en,
        "%d ", buf_feat_en,
        "%d ", w_fea_size,
        "%d ", w_pool_size,
        "%d ", pixel_in,
        "|o: ",
        "%d ", pixel_out,
        "|r: ",
        "%d ", dut.pixel_feat[0],
        "%d ", dut.pixel_feat[1],
        "%d ", dut.pixel_feat[2],
        "%d ", dut.pixel_feat[3],
        "|"
      );
      #(STEP/2+1);
    end
  end

endmodule
