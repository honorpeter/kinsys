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

  reg       last_input$;
  reg       accum_we$   [D_MAC-1:0];
  reg       accum_rst$  [D_MAC-1:0];
  ctrl_reg  out_ctrl$   [D_MAC-1:0];

//==========================================================
// accum control
//==========================================================

  assign accum_we  = accum_we$[D_MAC-1];
  assign accum_rst = accum_rst$[D_MAC-1];

  always @(posedge clk)
    if (!xrst)
      last_input$ <= 0;
    else
      last_input$ <= in_ctrl.stop;

  for (genvar i = 0; i < D_MAC; i++)
    if (i == 0) begin
      always @(posedge clk)
        if (!xrst)
          accum_we$[0] <= 0;
        else
          accum_we$[0] <= in_ctrl.valid && !in_ctrl.stop;
    end
    else begin
      always @(posedge clk)
        if (!xrst)
          accum_we$[i] <= 0;
        else
          accum_we$[i] <= accum_we$[i-1];
    end

  for (genvar i = 0; i < D_MAC; i++)
    if (i == 0) begin
      always @(posedge clk)
        if (!xrst)
          accum_rst$[0] <= 0;
        else
          accum_rst$[0] <= last_input$;
    end
    else begin
      always @(posedge clk)
        if (!xrst)
          accum_rst$[i] <= 0;
        else
          accum_rst$[i] <= accum_rst$[i-1];
    end

//==========================================================
// output control
//==========================================================

  assign out_ctrl.start = out_ctrl$[D_MAC-1].start;
  assign out_ctrl.valid = out_ctrl$[D_MAC-1].valid;
  assign out_ctrl.stop  = out_ctrl$[D_MAC-1].stop;
  assign mac_oe         = out_ctrl$[D_MAC-2].valid;

  for (genvar i = 0; i < D_MAC; i++)
    if (i == 0) begin
      always @(posedge clk)
        if (!xrst) begin
          out_ctrl$[0].start <= 0;
          out_ctrl$[0].valid <= 0;
          out_ctrl$[0].stop  <= 0;
        end
        else begin
          out_ctrl$[0].start <= in_ctrl.stop;
          out_ctrl$[0].valid <= last_input$;
          out_ctrl$[0].stop  <= last_input$;
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
