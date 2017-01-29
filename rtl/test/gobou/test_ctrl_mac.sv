`include "gobou.svh"
`include "ctrl_bus.svh"

module test_ctrl_mac;

  reg clk;
  reg xrst;
  ctrl_bus in_ctrl();
  ctrl_reg r_in_ctrl;
  ctrl_bus out_ctrl();
  ctrl_reg r_out_ctrl;
  reg mac_oe;
  reg accum_we;
  reg accum_rst;

  ctrl_mac dut(.*);

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
    r_in_ctrl.start  = 0;
    r_in_ctrl.valid  = 0;
    r_in_ctrl.stop   = 0;
    #(STEP);

    r_in_ctrl.start = 1;
    #(STEP);

    r_in_ctrl.start = 0;
    r_in_ctrl.valid = 1;
    #(STEP*800);

    r_in_ctrl.stop  = 1;
    #(STEP);

    r_in_ctrl.valid = 0;
    r_in_ctrl.stop  = 0;
    #(STEP*5);

    $finish();
  end

  //display
  always
  begin
    #(STEP/2-1);
    $display(
      "%d: ", $time/STEP,
      "%d ", xrst,
      "| ",
    );
    #(STEP/2+1);
  end

endmodule
