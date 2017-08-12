`include "renkon.svh"

parameter IMAGE = 12;
parameter FILTER = 5;
parameter PADDING = (FILTER-1)/2;
// parameter PADDING = 0;

module test_renkon_linebuf_pad;

  localparam BUFSIZE = IMAGE + 1;
  localparam BUFLINE = FILTER + 1;
  localparam SIZEWIDTH = $clog2(BUFSIZE);
  localparam LINEWIDTH = $clog2(BUFLINE);

  reg                       clk;
  reg                       xrst;
  reg                       buf_req;
  reg  [LWIDTH-1:0]         img_size;
  reg  [LWIDTH-1:0]         fil_size;
  reg  [LWIDTH-1:0]         pad_size;
  reg  signed [DWIDTH-1:0]  buf_input;

  wire                      buf_ack;
  wire                      buf_start;
  wire                      buf_valid;
  wire                      buf_stop;
  wire                      buf_ready;
  wire                      buf_wcol;
  wire                      buf_rrow [FILTER-1:0];
  wire [LINEWIDTH:0]        buf_wsel;
  wire [LINEWIDTH:0]        buf_rsel;
  wire                      buf_we;
  wire [SIZEWIDTH-1:0]      buf_addr;
  wire signed [DWIDTH-1:0]  buf_output [FILTER**2-1:0];

  reg signed [DWIDTH-1:0] mem_input [IMAGE**2+1-1:0];

  renkon_linebuf_pad #(FILTER, IMAGE) dut(.*);
  renkon_ctrl_linebuf_pad #(FILTER, IMAGE) ctrl(.*);

  // clock
  initial begin
    clk = 0;
    forever
      #(STEP/2) clk = ~clk;
  end

  //flow
  reg [LWIDTH-1:0] addr = 0;
  always@(posedge clk) begin
    if (!xrst)
      addr <= 0;
    else if (buf_ack)
      addr <= 0;
    else if (buf_ready)
      addr <= addr + 1;
    buf_input <= mem_input[addr];
  end

  initial begin
    xrst = 0;
    read_input;
    #(STEP);

    xrst      = 1;
    buf_req   = 0;
    img_size  = IMAGE;
    fil_size  = FILTER;
    pad_size  = PADDING;
    #(STEP*5);

    buf_req = 1;
    #(STEP);
    buf_req = 0;

    while (!buf_ack) #(STEP);

    #(STEP*10);

    $finish();
  end

  task read_input;
    $readmemh("../../data/renkon/input_renkon_linebuf_pad.dat", mem_input);
    mem_input[IMAGE**2] = 0;
  endtask

  //display
  initial write_output;
  int i, j;
  task write_output;
    int fd;
    begin // {{{
      fd = $fopen("../../data/renkon/output_renkon_linebuf_pad.dat", "w");
      i = 0; j = 0;
      forever begin
        #(STEP/2-1);
        if (buf_valid) begin
          $fwrite(fd, "Block %0d:\n", (IMAGE+2*PADDING-FILTER+1)*i+j);
          for (int di = 0; di < FILTER; di++) begin
            for (int dj = 0; dj < FILTER; dj++)
              $fwrite(fd, "%5d", buf_output[FILTER*di+dj]);
            $fwrite(fd, "\n");
          end
          $fwrite(fd, "\n");
          if (j == (IMAGE+2*PADDING-FILTER+1) - 1) begin
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
    $display(" clk: ", "state$ ", "|");
    forever begin
      #(STEP/2-1);
      $display(
        "%4d: ", $time/STEP,
        "%b ", buf_req,
        "%b ", buf_ack,
        "%d ", ctrl.state$,
        "| ",
        "%1d ", buf_wcol,
        "%1b",  buf_rrow[0],
        "%1b",  buf_rrow[1],
        "%1b",  buf_rrow[2],
        "%1b",  buf_rrow[3],
        "%1b ", buf_rrow[4],
        "%1d ", buf_wsel,
        "%1d ", buf_rsel,
        "%b ",  buf_we,
        "%2d ", buf_addr,
        "%4d ", buf_input,
        "| ",
        "%b ", buf_start,
        "%b ", buf_valid,
        "%b ", buf_ready,
        "%b ", buf_stop,
        ": ",
        "%4d ", dut.buf_output[0],
        "%4d ", dut.buf_output[5],
        "%4d ", dut.buf_output[10],
        "%4d ", dut.buf_output[15],
        "%4d ", dut.buf_output[20],
        ": ",
        "%4d ", dut.buf_output[4],
        "%4d ", dut.buf_output[9],
        "%4d ", dut.buf_output[14],
        "%4d ", dut.buf_output[19],
        "%4d ", dut.buf_output[24],
        "| ",
        "%b ",  buf_ready,
        "%4d ", addr,
        "; ",
        "%2d ", ctrl.col_count$,
        "%1d ", ctrl.mem_count$,
        "%2d ", ctrl.row_count$,
        // "; ",
        // "%1d ", dut.mem_linebuf_we[0],
        // "%2d ", dut.mem_linebuf_addr,
        // "%4d ", dut.mem_linebuf_wdata,
        "|"
      );
      #(STEP/2+1);
    end
  end

endmodule