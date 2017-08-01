`include "renkon.svh"

parameter IMAGE = 32;
parameter FILTER = 3;

module test_renkon_linebuf;

  reg                     clk;
  reg                     xrst;
  reg                     buf_req;
  reg        [LWIDTH-1:0] img_size;
  reg        [LWIDTH-1:0] fil_size;
  reg signed [DWIDTH-1:0] buf_input;

  wire                      buf_ack;
  wire                      buf_valid;
  wire signed [DWIDTH-1:0]  buf_output [FILTER**2-1:0];

  reg signed [DWIDTH-1:0] mem_input [IMAGE**2-1:0];

  renkon_linebuf #(FILTER, IMAGE) dut(.*);

  // clock
  initial begin
    clk = 0;
    forever
      #(STEP/2) clk = ~clk;
  end

  //flow
  int addr = 0;
  initial begin
    xrst = 0;
    read_input;
    #(STEP);

    xrst      = 1;
    buf_req   = 0;
    img_size  = IMAGE;
    fil_size  = FILTER;
    buf_input = mem_input[0];
    #(STEP*5);

    buf_req = 1;
    #(STEP/2-1);
    while (buf_req || !buf_ack) begin
      addr++;
      #(STEP);
      buf_input = mem_input[addr];

      if (buf_req) buf_req = 0;
    end
    #(STEP/2+1);

    #(STEP*10);

    $finish();
  end

  task read_input;
    $readmemh("../../data/renkon/input_renkon_linebuf.dat", mem_input);
  endtask

  //display
  initial write_output;
  task write_output;
    int fd;
    int i, j;
    begin // {{{
      fd = $fopen("../../data/renkon/output_renkon_linebuf.dat", "w");
      i = 0; j = 0;
      forever begin
        #(STEP/2-1);
        if (buf_valid) begin
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
    $display("clk: ", "state$ ", "|");
    forever begin
      #(STEP/2-1);
      $display(
        "%5d: ", $time/STEP,
        "%b ", buf_req,
        "%b ", buf_ack,
        "%d ", dut.state$,
        "|i: ",
        "%1d ", xrst,
        "%1d ", buf_req,
        "%2d ", img_size,
        "%1d ", fil_size,
        "%4d ", buf_input,
        "|o: ",
        "%b ", buf_valid,
        "; ",
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
        "|r: ",
        "%b ", dut.select$,
        "%2d ", dut.col_count$,
        "%1d ", dut.mem_count$,
        "%2d ", dut.row_count$,
        ";mem ",
        "%b ", dut.mem_linebuf_we,
        "%d ", dut.mem_linebuf_addr,
        "%4d ", dut.buf_input$,
        "{",
        "%4d, ", dut.read_mem[3],
        "%4d, ", dut.read_mem[2],
        "%4d, ", dut.read_mem[1],
        "%4d, ", dut.read_mem[0],
        "}",
        "|"
      );
      #(STEP/2+1);
    end
  end

endmodule
