`include "gobou.svh"

module gobou_ctrl_bias
  ( input           clk
  , input           xrst
  , ctrl_bus.slave  in_ctrl
  , ctrl_bus.master out_ctrl
  , output          bias_oe
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
          r_out_ctrl[0] <= '{0, 0, 0};
        else begin
          r_out_ctrl[0].start <= in_ctrl.start;
          r_out_ctrl[0].valid <= in_ctrl.valid;
          r_out_ctrl[0].stop  <= in_ctrl.stop;
        end
    else
      always @(posedge clk)
        if (!xrst)
          r_out_ctrl[i] <= '{0, 0, 0};
        else begin
          r_out_ctrl[i].start <= r_out_ctrl[i-1].start;
          r_out_ctrl[i].valid <= r_out_ctrl[i-1].valid;
          r_out_ctrl[i].stop  <= r_out_ctrl[i-1].stop;
        end

endmodule
