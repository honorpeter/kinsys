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
    #(STEP*32);

    $finish();
  end

  task read_input;
    $readmemh("../../data/renkon/input_linebuf.dat", mem_input);
  endtask

  //display
  initial write_output;
  reg [LWIDTH-1:0] r_addr_count_d1, r_addr_count_d2;
  reg [LWIDTH-1:0] r_line_count_d1, r_line_count_d2;
  always @(posedge clk) r_addr_count_d1 <= dut.r_addr_count;
  always @(posedge clk) r_addr_count_d2 <=     r_addr_count_d1;
  always @(posedge clk) r_line_count_d1 <= dut.r_line_count;
  always @(posedge clk) r_line_count_d2 <=     r_line_count_d1;
  task write_output;
    int fd;
    int i, j;
    begin // {{{
      fd = $fopen("../../data/renkon/output_linebuf.dat", "w");
      i = 0; j = 0;
      forever begin
        #(STEP/2-1);
        if (r_line_count_d2 >= FSIZE && r_addr_count_d2 >= FSIZE-1) begin
          $fwrite(fd, "Block %0d:\n", (ISIZE-FSIZE+1)*i+j);
          for (int di = 0; di < FSIZE; di++) begin
            for (int dj = 0; dj < FSIZE; dj++)
              $fwrite(fd, "%5d", buf_output[FSIZE*di+dj]);
            $fwrite(fd, "\n");
          end
          $fwrite(fd, "\n");
          if (j == (ISIZE-FSIZE+1) - 1) begin
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
        "%d ", xrst,
        "%d ", buf_en,
        "%d ", img_size,
        "%d ", fil_size,
        "%d ", buf_input,
        "|o: ",
        "%4d ", buf_output[0],
        "%4d ", buf_output[5],
        "%4d ", buf_output[10],
        "%4d ", buf_output[15],
        "%4d ", buf_output[20],
        "|w: ",
        "%d ", dut.s_charge_end,
        "%d ", dut.s_active_end,
        "%d ", dut.mem_linebuf_we,
        "%d ", dut.mem_linebuf_addr,
        "%d ", dut.read_mem[0],
        "|r: ",
        "%d ", dut.r_select,
        "%2d ", dut.r_addr_count,
        "%2d ", r_addr_count_d2,
        "%2d ", dut.r_mem_count,
        "%2d ", dut.r_line_count,
        "%2d ", r_line_count_d2,
        "%4d ", dut.r_buf_input,
        "%4d ", dut.r_pixel[0],
        "|"
      );
      #(STEP/2+1);
    end
  end

endmodule
