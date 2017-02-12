`include "renkon.svh"

parameter ISIZE = 28;

module test_linebuf;

  reg                     clk;
  reg                     xrst;
  reg                     buf_en;
  reg        [LWIDTH-1:0] img_size;
  reg        [LWIDTH-1:0] fil_size;
  reg signed [DWIDTH-1:0] buf_input;
  reg signed [DWIDTH-1:0] buf_output [FSIZE**2-1:0];

  reg signed [DWIDTH-1:0] mem_input [ISIZE**2-1:0];

  linebuf #(5, 32) dut(.*);

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

    xrst      = 1;
    buf_en    = 1;
    img_size  = ISIZE;
    fil_size  = FSIZE;
    buf_input = mem_input[0];
    #(STEP);

    buf_en = 0;
    for (int i = 1; i < ISIZE**2; i++) begin
      buf_input = mem_input[i];
      #(STEP);
    end
    #(STEP*30);

    $finish();
  end

  task read_input;
    $readmemh("test/input_linebuf.dat", mem_input);
  endtask

  //display
  initial show_format;

  task show_format;
    begin
      forever begin
        #(STEP/2-1);
        $display("clk: %5d", $time/STEP);
        for (int i = 0; i < FSIZE; i++) begin
          for (int j = 0; j < FSIZE; j++)
            $write("%d", buf_output[FSIZE*i+j]);
          $write("\n");
        end
        #(STEP/2+1);
      end
    end
  endtask

  task show_signal;
    begin
      $display("clk: |");
      forever begin
        #(STEP/2-1);
        $display(
          "%5d: ", $time/STEP,
          "%d ", dut.r_state,
          "|i: ",
          "%d ", xrst,
          "%d ", buf_en,
          "%d ", img_size,
          "%d ", fil_size,
          "%d ", buf_input,
          "|o: ",
          "%d ", buf_output[0],
          "|"
        );
        #(STEP/2+1);
      end
    end
  endtask

endmodule
