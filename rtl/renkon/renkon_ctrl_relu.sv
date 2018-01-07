`include "renkon.svh"

module renkon_ctrl_relu
  ( input           clk
  , input           xrst
  , input           _relu_en
  , ctrl_bus.slave  in_ctrl
  , ctrl_bus.master out_ctrl
  , output          relu_oe
  );

  ctrl_reg out_ctrl$ [D_RELU-1:0];

  assign in_ctrl.ready  = out_ctrl.ready;
  assign out_ctrl.delay = in_ctrl.delay + (_relu_en ? D_RELU : 1);

  assign out_ctrl.start = _relu_en
                        ? out_ctrl$[D_RELU-1].start
                        : out_ctrl$[0].start;
  assign out_ctrl.valid = _relu_en
                        ? out_ctrl$[D_RELU-1].valid
                        : out_ctrl$[0].valid;
  assign out_ctrl.stop  = _relu_en
                        ? out_ctrl$[D_RELU-1].stop
                        : out_ctrl$[0].stop;

  assign relu_oe        = out_ctrl$[D_RELU-2].valid;

  for (genvar i = 0; i < D_RELU; i++)
    if (i == 0) begin
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
    end
    else begin
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
    end

endmodule
