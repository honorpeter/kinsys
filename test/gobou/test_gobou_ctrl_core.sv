`include "gobou.svh"

module test_gobou_ctrl_core;

  reg clk;
  reg xrst;
  ctrl_bus in_ctrl();
  ctrl_reg in_ctrl$;
  reg                     req;
  reg [GOBOU_CORELOG-1:0] net_sel;
  reg                     net_we;
  reg [GOBOU_NETSIZE-1:0] net_addr;
  reg                     img_we;
  reg signed [DWIDTH-1:0] img_wdata;
  reg [IMGSIZE-1:0]       in_offset;
  reg [IMGSIZE-1:0]       out_offset;
  reg [GOBOU_NETSIZE-1:0] net_offset;
  reg signed [DWIDTH-1:0] out_wdata;
  reg [LWIDTH-1:0]        total_out;
  reg [LWIDTH-1:0]        total_in;
  ctrl_bus out_ctrl();
  ctrl_reg out_ctrl$;
  reg                      ack;
  reg                      mem_img_we;
  reg [IMGSIZE-1:0]        mem_img_addr;
  reg signed [DWIDTH-1:0]  mem_img_wdata;
  reg [GOBOU_CORE-1:0]     mem_net_we;
  reg [GOBOU_NETSIZE-1:0]  mem_net_addr;
  reg                      breg_we;
  reg                      serial_we;

  gobou_ctrl_core dut(.*);

  assign in_ctrl.start  = in_ctrl$.start;
  assign in_ctrl.valid  = in_ctrl$.valid;
  assign in_ctrl.stop   = in_ctrl$.stop;
  assign out_ctrl.start  = out_ctrl$.start;
  assign out_ctrl.valid  = out_ctrl$.valid;
  assign out_ctrl.stop   = out_ctrl$.stop;

  // clock
  initial begin
    clk = 0;
    forever
      #(STEP/2) clk = ~clk;
  end

  //flow
  initial
  begin
    xrst = 0;
    #(STEP);

    xrst = 1;
    req = 0;
    in_ctrl$ = '{0, 0, 0};
    img_we = 0;
    in_offset = 0;
    out_offset = 0;
    net_addr = 0;
    total_out = 0;
    total_in = 0;
    #(STEP);

    req = 1;
    in_offset = 0;
    out_offset = 1000;
    total_out = 500;
    total_in = 800;
    #(STEP);

    req = 0;

    for (int i = 0; i < 16; i++) begin
      #(STEP*1000);
      in_ctrl$.start = 1;
      #(STEP);
      in_ctrl$.start = 0;
      in_ctrl$.valid = 1;
      in_ctrl$.stop  = 1;
      #(STEP);
      in_ctrl$.valid = 0;
      in_ctrl$.stop  = 0;
    end

    // while (!ack) #(STEP);
    #(STEP*5);
    $finish();
  end

  //display
  always
  begin
    #(STEP/2-1);
    $display(
      "%d: ", $time/STEP,
      "%d ", dut.state$,
      "%d ", dut.count_out$,
      "%d ", dut.count_in$,
      "| ",
    );
    #(STEP/2+1);
  end

endmodule
