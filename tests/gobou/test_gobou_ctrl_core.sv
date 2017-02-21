`include "gobou.svh"
`include "ctrl_bus.svh"

module test_gobou_ctrl_core;

  reg clk;
  reg xrst;
  ctrl_bus in_ctrl();
  ctrl_reg r_in_ctrl;
  reg                     req;
  reg                     img_we;
  reg [IMGSIZE-1:0]       input_addr;
  reg [IMGSIZE-1:0]       output_addr;
  reg signed [DWIDTH-1:0] write_img;
  reg signed [DWIDTH-1:0] write_result;
  reg [CORELOG:0]         net_we;
  reg [NETSIZE-1:0]       net_addr;
  reg [LWIDTH-1:0]        total_out;
  reg [LWIDTH-1:0]        total_in;
  ctrl_bus out_ctrl();
  ctrl_reg r_out_ctrl;
  reg                      ack;
  reg                      mem_img_we;
  reg [IMGSIZE-1:0]        mem_img_addr;
  reg signed [DWIDTH-1:0]  write_mem_img;
  reg [CORE-1:0]           mem_net_we;
  reg [NETSIZE-1:0]        mem_net_addr;
  reg                      breg_we;
  reg                      serial_we;

  gobou_ctrl_core dut(.*);

  assign in_ctrl.start  = r_in_ctrl.start;
  assign in_ctrl.valid  = r_in_ctrl.valid;
  assign in_ctrl.stop   = r_in_ctrl.stop;
  assign out_ctrl.start  = r_out_ctrl.start;
  assign out_ctrl.valid  = r_out_ctrl.valid;
  assign out_ctrl.stop   = r_out_ctrl.stop;

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
    r_in_ctrl = '{0, 0, 0};
    img_we = 0;
    input_addr = 0;
    output_addr = 0;
    net_addr = 0;
    total_out = 0;
    total_in = 0;
    #(STEP);

    req = 1;
    input_addr = 0;
    output_addr = 1000;
    total_out = 500;
    total_in = 800;
    #(STEP);

    req = 0;

    for (int i = 0; i < 16; i++) begin
      #(STEP*1000);
      r_in_ctrl.start = 1;
      #(STEP);
      r_in_ctrl.start = 0;
      r_in_ctrl.valid = 1;
      r_in_ctrl.stop  = 1;
      #(STEP);
      r_in_ctrl.valid = 0;
      r_in_ctrl.stop  = 0;
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
      "%d ", dut.r_state,
      "%d ", dut.r_count_out,
      "%d ", dut.r_count_in,
      "| ",
    );
    #(STEP/2+1);
  end

endmodule
