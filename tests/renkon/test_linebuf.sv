`include "renkon.svh"

parameter IMAGE = 32;
parameter FILTER = 3;

module test_linebuf;

  reg                     clk;
  reg                     xrst;
  reg                     buf_en;
  reg        [LWIDTH-1:0] img_size;
  reg        [LWIDTH-1:0] fil_size;
  reg signed [DWIDTH-1:0] buf_input;
  reg signed [DWIDTH-1:0] buf_output [FILTER**2-1:0];

  reg signed [DWIDTH-1:0] mem_input [IMAGE**2-1:0];

  linebuf #(FILTER, IMAGE) dut(.*);

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
    img_size  = IMAGE;
    fil_size  = FILTER;
    buf_input = mem_input[0];
    #(STEP);

    buf_en = 0;
    for (int i = 1; i < IMAGE**2; i++) begin
      buf_input = mem_input[i];
      #(STEP);
    end
    #(STEP*(IMAGE+FILTER));

    $finish();
  end

  task read_input;
    $readmemh("../../data/renkon/input_linebuf.dat", mem_input);
  endtask

  //display
  initial write_output;
  reg [LWIDTH-1:0] r_addr_count_d [2:1];
  reg [LWIDTH-1:0] r_line_count_d [2:1];
  always @(posedge clk) begin
    r_addr_count_d[1] <= dut.r_addr_count;
    r_line_count_d[1] <= dut.r_line_count;
    r_addr_count_d[2] <= r_addr_count_d[1];
    r_line_count_d[2] <= r_line_count_d[1];
  end
  task write_output;
    int fd;
    int i, j;
    begin // {{{
      fd = $fopen("../../data/renkon/output_linebuf.dat", "w");
      i = 0; j = 0;
      forever begin
        #(STEP/2-1);
        if (r_line_count_d[2] >= FILTER
              && r_addr_count_d[2] >= FILTER-1) begin
          $fwrite(fd, "Block %0d:\n", (IMAGE-FILTER+1)*i+j);
          for (int di = 0; di < FILTER; di++) begin
            for (int dj = 0; dj < FILTER; dj++)
              $fwrite(fd, "%5d", buf_output[FILTER*di+dj]);
            $fwrite(fd, "\n");
          end
          $fwrite(fd, "\n");
          if (j == (IMAGE-FILTER+1) - 1) begin
            i++; j=0;
          end
          else j++;
        end
        #(STEP/2+1);
      end
      $fclose(fd);
    end // }}}
  endtask

  initial begin
    $display("clk: ", "r_state ", "|");
    forever begin
      #(STEP/2-1);
      $display(
        "%5d: ", $time/STEP,
        "%d ", dut.r_state,
        "|i: ",
        "%1d ", xrst,
        "%1d ", buf_en,
        "%2d ", img_size,
        "%1d ", fil_size,
        "%4d ", buf_input,
        "|r: ",
        "%b ", dut.r_select,
        "%2d ", dut.r_addr_count,
        "%1d ", dut.r_mem_count,
        "%2d ", dut.r_line_count,
        "%4d ", dut.r_buf_input,
        "|o: ",
        "%4d ", buf_output[0],
        "%4d ", buf_output[1],
        "%4d ", buf_output[2],
        "; ",
        "%4d ", buf_output[3],
        "%4d ", buf_output[4],
        "%4d ", buf_output[5],
        "; ",
        "%4d ", buf_output[6],
        "%4d ", buf_output[7],
        "%4d ", buf_output[8],
        "|"
      );
      #(STEP/2+1);
    end
  end

endmodule
