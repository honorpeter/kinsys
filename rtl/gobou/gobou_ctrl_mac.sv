`include "gobou.svh"

module gobou_ctrl_mac
  ( input           clk
  , input           xrst
  , ctrl_bus.slave  in_ctrl
  , ctrl_bus.master out_ctrl
  , output          mac_oe
  , output          accum_we
  , output          accum_rst
  );

  ctrl_reg  r_out_ctrl;
  reg       r_mac_oe;
  reg       r_accum_we;
  reg       r_accum_rst;

  assign mac_oe     = r_mac_oe;
  assign accum_we   = r_accum_we;
  assign accum_rst  = r_accum_rst;

  always @(posedge clk)
    if (!xrst)
      r_mac_oe <= 0;
    else
      r_mac_oe <= in_ctrl.stop;

  always @(posedge clk)
    if (!xrst)
      r_accum_we <= 0;
    else
      r_accum_we <= in_ctrl.valid && !in_ctrl.stop;

  always @(posedge clk)
    if (!xrst)
      r_accum_rst <= 0;
    else
      r_accum_rst <= mac_oe;

  assign out_ctrl.start = r_out_ctrl.start;
  assign out_ctrl.valid = r_out_ctrl.valid;
  assign out_ctrl.stop  = r_out_ctrl.stop;

  always @(posedge clk)
    if (!xrst) begin
      // r_out_ctrl <= '{0, 0, 0};
      r_out_ctrl.start <= 0;
      r_out_ctrl.valid <= 0;
      r_out_ctrl.stop  <= 0;
    end
    else begin
      r_out_ctrl.start <= in_ctrl.stop;
      r_out_ctrl.valid <= r_mac_oe;
      r_out_ctrl.stop  <= r_mac_oe;
    end

endmodule
