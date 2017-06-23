`include "gobou.svh"

module gobou_ctrl_bias
  ( input           clk
  , input           xrst
  , ctrl_bus.slave  in_ctrl
  , ctrl_bus.master out_ctrl
  , output          bias_oe
  );

  ctrl_reg out_ctrl$ [D_BIAS-1:0];

  assign out_ctrl.start = out_ctrl$[D_BIAS-1].start;
  assign out_ctrl.valid = out_ctrl$[D_BIAS-1].valid;
  assign out_ctrl.stop  = out_ctrl$[D_BIAS-1].stop;
  assign bias_oe  = out_ctrl$[D_BIAS-2].valid;

  for (genvar i = 0; i < D_BIAS; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst) begin
          out_ctrl$[0].start <= 0;
          out_ctrl$[0].valid <= 0;
          out_ctrl$[0].stop  <= 0;
        end
        else begin
          out_ctrl$[0].start <= in_ctrl.start;
          out_ctrl$[0].valid <= in_ctrl.valid;
          out_ctrl$[0].stop  <= in_ctrl.stop;
        end
    else
      always @(posedge clk)
        if (!xrst) begin
          out_ctrl$[i].start <= 0;
          out_ctrl$[i].valid <= 0;
          out_ctrl$[i].stop  <= 0;
        end
        else begin
          out_ctrl$[i].start <= out_ctrl$[i-1].start;
          out_ctrl$[i].valid <= out_ctrl$[i-1].valid;
          out_ctrl$[i].stop  <= out_ctrl$[i-1].stop;
        end

endmodule
