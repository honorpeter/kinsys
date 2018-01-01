`include "renkon.svh"

module test_renkon_ctrl_core;

  reg                      clk;
  reg                      xrst;
  ctrl_bus                 in_ctrl();
  ctrl_reg                 in_ctrl$;
  reg                      req;
  reg signed [DWIDTH-1:0]  out_wdata;
  reg [RENKON_CORELOG-1:0] net_sel;
  reg                      net_we;
  reg [RENKON_NETSIZE-1:0] net_addr;
  reg [IMGSIZE-1:0]        in_offset;
  reg [IMGSIZE-1:0]        out_offset;
  reg [RENKON_NETSIZE-1:0] net_offset;
  reg [LWIDTH-1:0]         total_out;
  reg [LWIDTH-1:0]         total_in;
  reg [LWIDTH-1:0]         img_size;
  reg [LWIDTH-1:0]         conv_kern;

  ctrl_bus                 out_ctrl();
  ctrl_reg                 out_ctrl$;
  wire                      ack;
  wire [2-1:0]              core_state;
  wire                      img_we;
  wire [IMGSIZE-1:0]        img_addr;
  wire signed [DWIDTH-1:0]  img_wdata;
  wire [RENKON_CORE-1:0]    mem_net_we;
  wire [RENKON_NETSIZE-1:0] mem_net_addr;
  wire                      buf_pix_en;
  wire                      first_input;
  wire                      last_input;
  wire                      wreg_we;
  wire                      breg_we;
  wire                      serial_we;
  wire [RENKON_CORELOG:0]   serial_re;
  wire [OUTSIZE-1:0]        serial_addr;
  wire [LWIDTH-1:0]         w_img_size;
  wire [LWIDTH-1:0]         w_conv_kern;

  assign in_ctrl.start = in_ctrl$.start;
  assign in_ctrl.valid = in_ctrl$.valid;
  assign in_ctrl.stop  = in_ctrl$.stop;

  always @(posedge clk)
    if (!xrst)
      out_ctrl$  <= '{0, 0, 0};
    else begin
      out_ctrl$.start <= out_ctrl.start;
      out_ctrl$.valid <= out_ctrl.valid;
      out_ctrl$.stop  <= out_ctrl.stop;
    end

  renkon_ctrl_core dut(.*);

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
    in_ctrl$ = '{0, 0, 0};
    req = 0;
    out_wdata = 0;
    net_sel = 0;
    net_we = 0;
    net_addr = 0;
    in_offset = 0;
    out_offset = 0;
    net_offset = 0;
    total_out = 0;
    total_in = 0;
    img_size = 0;
    conv_kern = 0;
    #(STEP);

    req = 1;
    total_out = 50;
    total_in = 20;
    img_size = 12;
    conv_kern = 5;
    in_offset = 0;
    out_offset = 3000;
    net_offset = 0;
    #(STEP);

    req = 0;

    repeat (7) begin
      #(STEP*4000);
      in_ctrl$.start = 1;
      #(STEP);

      in_ctrl$.start = 0;
      in_ctrl$.valid = 1;
      #(STEP*15);

      in_ctrl$.stop = 1;
      #(STEP);

      in_ctrl$.valid = 0;
      in_ctrl$.stop = 0;
    end

    while (!ack) #(STEP);
    #(STEP*5);

    $finish();
  end

  //display
  initial begin
    $display("clk: |");
    forever begin
      #(STEP/2-1);
      $display(
        "%5d: ", $time/STEP,
        "%p ", dut.state$[0],
        "|i: ",
        "%d ", xrst,
        "%d",  in_ctrl$.start,
        "%d",  in_ctrl$.valid,
        "%d ", in_ctrl$.stop,
        "%d ", req,
        "%d ", out_wdata,
        "%d ", net_sel,
        "%d ", net_we,
        "%d ", net_addr,
        "%d ", in_offset,
        "%d ", out_offset,
        "%d ", net_offset,
        "%2d ", total_out,
        "%2d ", total_in,
        "%2d ", img_size,
        "%2d ", conv_kern,
        "|o: ",
        "%d",  out_ctrl$.start,
        "%d",  out_ctrl$.valid,
        "%d ", out_ctrl$.stop,
        "%d ", ack,
        "%d ", core_state,
        "%d ", img_we,
        "%d ", img_addr,
        "%d ", img_wdata,
        "%d ", mem_net_we,
        "@%d ", mem_net_addr,
        "%d ", buf_pix_en,
        "%d ", first_input,
        "%d ", last_input,
        "%d ", wreg_we,
        "%d ", breg_we,
        "%d ", serial_we,
        "%d ", serial_re,
        "%d ", serial_addr,
        "%2d ", w_img_size,
        "%2d ", w_conv_kern,
        "|r: ",
        "|"
      );
      #(STEP/2+1);
    end
  end

endmodule
