`include "gobou/gobou.svh"
`include "common/ctrl_bus.sv"

module ctrl_bias
  ( input         clk
  , input         xrst
  , ctrl_bus.in   in_ctrl
  , ctrl_bus.out  out_ctrl
  , output        bias_oe
  );

  ctrl_reg r_out_ctrl [D_BIAS-1:0];

  assign out_ctrl.start = r_out_ctrl[D_BIAS-1].start;
  assign out_ctrl.valid = r_out_ctrl[D_BIAS-1].valid;
  assign out_ctrl.stop  = r_out_ctrl[D_BIAS-1].stop;
  assign bias_oe  = r_out_ctrl[D_BIAS-2].valid;

  for (genvar i = 0; i < D_BIAS; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst)
          r_out_ctrl[0] <= {0, 0, 0};
        else
          r_out_ctrl[0] <= in_ctrl;
    else
      always @(posedge clk)
        if (!xrst)
          r_out_ctrl[0] <= {0, 0, 0};
        else
          r_out_ctrl[i] <= r_out_ctrl[i-1];

endmodule
