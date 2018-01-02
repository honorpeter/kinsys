`include "renkon.svh"

// 5, 1, 0
// 5, 1, 2
// 3, 1, 0
// 3, 1, 1
// 2, 2, 0
// 3, 2, 1
parameter SIZE    = 12;
parameter KERN    = 2;
parameter STRID   = 2;
parameter PADDING = 0;
parameter COVER_ALL = 1'b0;
parameter DELAY = 1;

module test_renkon_linebuf_pad;

  localparam BUFSIZE = SIZE + 1;
  localparam BUFLINE = KERN + 1;
  localparam SIZEWIDTH = $clog2(BUFSIZE);
  localparam LINEWIDTH = $clog2(BUFLINE);

  reg                       clk;
  reg                       xrst;
  reg  [LWIDTH-1:0]         size;
  reg  [LWIDTH-1:0]         kern;
  reg  [LWIDTH-1:0]         strid;
  reg  [LWIDTH-1:0]         pad;
  reg                       buf_req;
  reg  signed [DWIDTH-1:0]  buf_input;

  integer                   buf_delay = DELAY;

  wire                      buf_ack;
  wire                      buf_start;
  wire                      buf_valid;
  wire                      buf_stop;
  wire                      buf_ready;
  wire                      buf_wcol;
  wire                      buf_rrow [KERN-1:0];
  wire [LINEWIDTH:0]        buf_wsel;
  wire [LINEWIDTH:0]        buf_rsel;
  wire                      buf_we;
  wire [SIZEWIDTH-1:0]      buf_addr;
  wire signed [DWIDTH-1:0]  buf_output [KERN**2-1:0];

  reg signed [DWIDTH-1:0] mem_input [SIZE**2+1-1:0];

  renkon_linebuf_pad #(KERN, SIZE) dut(.*);
  renkon_ctrl_linebuf_pad #(KERN, SIZE, COVER_ALL) ctrl(.*);

  // clock
  initial begin
    clk = 0;
    forever
      #(STEP/2) clk = ~clk;
  end

  // memory
  reg [LWIDTH-1:0] addr [DELAY-1:0];
  for (genvar i = 0; i < DELAY; i++)
    if (i == 0) begin
      always @(posedge clk)
        if (!xrst)
          addr[0] <= 0;
        else if (buf_ack)
          addr[0] <= 0;
        else if (buf_ready)
          addr[0] <= addr[0] + 1;
    end
    else begin
      always @(posedge clk)
        if (!xrst)
          addr[i] <= 0;
        else
          addr[i] <= addr[i-1];
    end

  always @(posedge clk)
    if (!xrst)
      buf_input <= 0;
    else
      buf_input <= mem_input[addr[DELAY-1]];

  //flow
  initial begin
    xrst = 0;
    read_input;
    #(STEP);

    xrst    = 1;
    buf_req = 0;
    size    = SIZE;
    kern    = KERN;
    strid   = STRID;
    pad     = PADDING;
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
    mem_input[SIZE**2] = 0;
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
          $fwrite(fd, "Block %0d:\n", (SIZE+2*PADDING-KERN+1)*i+j);
          for (int di = 0; di < KERN; di++) begin
            for (int dj = 0; dj < KERN; dj++)
              $fwrite(fd, "%5d", buf_output[KERN*di+dj]);
            $fwrite(fd, "\n");
          end
          $fwrite(fd, "\n");
          if (j == (SIZE+2*PADDING-KERN+1) - 1) begin
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
        "*%d ", ctrl.state$,
        ": ",
        "%b ", ctrl.s_charge_end,
        "%b ", ctrl.s_active_end,
        "| ",
        "%1d ", buf_wcol,
        "%1b",  buf_rrow[0],
        "%1b",  buf_rrow[1],
        "%1b ",  buf_rrow[2],
        "%1d ", buf_wsel,
        "%1d ", buf_rsel,
        "%b ",  buf_we,
        "%2d ", buf_addr,
        "%4d ", buf_input,
        "| ",
        "%1d ", ctrl.mem_count,
        ": ",
        "%2d ", ctrl.col_count,
        "%2d ", ctrl.row_count,
        // "%2d ", ctrl.buf_valid$[0],
        ": ",
        "%2d ", ctrl.str_x_count,
        "%2d ", ctrl.str_y_count,
        "| ",
        "%b ", ctrl.buf_start$[0],
        "%b ", ctrl.buf_valid$[0],
        // "%b ", ctrl.buf_ready$[0],
        "%b ", ctrl.buf_stop$[0],
        ": ",
        "%b ", buf_start,
        "%b ", buf_valid,
        "%b ", buf_ready,
        "%b ", buf_stop,
        ": ",
        "%b ",  buf_ready,
        "%4d ", addr[0],
        "%4d ", ctrl.own_size,
        // "; ",
        // "%1d ", dut.mem_linebuf_we[0],
        // "%2d ", dut.mem_linebuf_addr,
        // "%4d ", dut.mem_linebuf_wdata,
        "| ",
        "%4d ", dut.mem_linebuf_rdata[0],
        ": ",
        "%4d ", dut.buf_output[0],
        "%4d ", dut.buf_output[1],
        "%4d ", dut.buf_output[2],
        "%4d ", dut.buf_output[3],
        "%4d ", dut.buf_output[4],
        "%4d ", dut.buf_output[5],
        "%4d ", dut.buf_output[6],
        "%4d ", dut.buf_output[7],
        "%4d ", dut.buf_output[8],
        "%4d ", dut.buf_output[24],
        "|"
      );
      #(STEP/2+1);
    end
  end

endmodule
