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

  ctrl_reg  out_ctrl$;
  reg       mac_oe$;
  reg       accum_we$;
  reg       accum_rst$;

  assign mac_oe     = mac_oe$;
  assign accum_we   = accum_we$;
  assign accum_rst  = accum_rst$;

  always @(posedge clk)
    if (!xrst)
      mac_oe$ <= 0;
    else
      mac_oe$ <= in_ctrl.stop;

  always @(posedge clk)
    if (!xrst)
      accum_we$ <= 0;
    else
      accum_we$ <= in_ctrl.valid && !in_ctrl.stop;

  always @(posedge clk)
    if (!xrst)
      accum_rst$ <= 0;
    else
      accum_rst$ <= mac_oe;

  assign out_ctrl.start = out_ctrl$.start;
  assign out_ctrl.valid = out_ctrl$.valid;
  assign out_ctrl.stop  = out_ctrl$.stop;

  always @(posedge clk)
    if (!xrst) begin
      out_ctrl$.start <= 0;
      out_ctrl$.valid <= 0;
      out_ctrl$.stop  <= 0;
    end
    else begin
      out_ctrl$.start <= in_ctrl.stop;
      out_ctrl$.valid <= mac_oe$;
      out_ctrl$.stop  <= mac_oe$;
    end

endmodule
