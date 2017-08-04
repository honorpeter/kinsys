`include "renkon.svh"

parameter IMAGE = 32;
parameter FILTER = 3;

module test_renkon_linebuf;

  localparam BUFSIZE = IMAGE + 1;
  localparam BUFLINE = FILTER + 1;
  localparam SIZEWIDTH = $clog2(BUFSIZE);
  localparam LINEWIDTH = $clog2(BUFLINE);

  reg                       clk;
  reg                       xrst;
  reg  [LWIDTH-1:0]         img_size;
  reg  [LWIDTH-1:0]         fil_size;
  reg                       buf_req;
  reg  signed [DWIDTH-1:0]  buf_input;

  wire                      buf_ack;
  wire                      buf_start;
  wire                      buf_valid;
  wire                      buf_stop;
  wire [LINEWIDTH:0]        buf_wsel;
  wire [LINEWIDTH:0]        buf_rsel;
  wire                      buf_we;
  wire [SIZEWIDTH-1:0]      buf_addr;
  wire signed [DWIDTH-1:0]  buf_output [FILTER**2-1:0];

  reg signed [DWIDTH-1:0] mem_input [2*IMAGE**2-1:0];

  renkon_linebuf #(FILTER, IMAGE) dut(.*);
  renkon_ctrl_linebuf #(FILTER, IMAGE) ctrl(.*);

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
    #(STEP);
    buf_req = 0;

    #(STEP/2-1);
    while (!buf_ack) begin
      if (addr < img_size ** 2) addr++;
      #(STEP);
      buf_input = mem_input[addr];
    end
    #(STEP/2+1);

    #(STEP*10);

    $finish();
  end

  task read_input;
    $readmemh("../../data/renkon/input_renkon_linebuf.dat", mem_input);
    mem_input[IMAGE**2] = 0;
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
        "%d ", ctrl.state$,
        "|i: ",
        "%b ",  buf_we,
        "%4d ", buf_addr,
        "%4d ", dut.buf_input$,
        "|o: ",
        "%b ", buf_start,
        "%b ", buf_valid,
        "%b ", buf_stop,
        "|r: ",
        "%4d ", addr,
        "; ",
        "%d ", ctrl.buf_wsel,
        "%d ", ctrl.buf_rsel,
        "%2d ", ctrl.col_count$,
        "%1d ", ctrl.mem_count$,
        "%2d ", ctrl.row_count$,
        "; ",
        "%b ", ctrl.buf_start$[0],
        "%b ", ctrl.buf_valid$[0],
        "%b ", ctrl.buf_stop$[0],
        "|"
      );
      #(STEP/2+1);
    end
  end

endmodule
