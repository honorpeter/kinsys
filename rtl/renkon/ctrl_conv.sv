`include "renkon.svh"

module ctrl_conv
  ( input               clk
  , input               xrst
  , ctrl_bus.in         in_ctrl
  , input  [2-1:0]      core_state
  , input  [LWIDTH-1:0] w_img_size
  , input  [LWIDTH-1:0] w_fil_size
  , input               first_input
  , input               last_input
  , ctrl_bus.out        out_ctrl
  , output              mem_feat_we
  , output              mem_feat_rst
  , output [FACCUM-1:0] mem_feat_addr
  , output [FACCUM-1:0] mem_feat_addr_d
  , output              conv_oe
  , output [LWIDTH-1:0] w_fea_size
  );

  ctrl_bus conv_ctrl;
  wire conv_start;
  wire conv_vaild;
  wire conv_stop;

  enum reg {
    S_WAIT, S_ACTIVE
  } r_state;
  enum reg [2-1:0] {
    S_CORE_WAIT, S_CORE_NETWORK, S_CORE_INPUT, S_CORE_OUTPUT
  } r_core_state;
  reg               r_wait_back;
  reg               r_first_input;
  reg               r_last_input;
  reg [LWIDTH-1:0]  r_img_size;
  reg [LWIDTH-1:0]  r_fil_size;
  reg [LWIDTH-1:0]  r_fea_size;
  reg               r_feat_we_d   [D_CONV-1:0];
  reg               r_feat_rst_d  [D_CONV-1:0];
  reg [FACCUM-1:0]  r_feat_addr_d [D_CONV:0];
  reg [LWIDTH-1:0]  r_conv_x;
  reg [LWIDTH-1:0]  r_conv_y;
  ctrl_reg          r_conv_ctrl;
  reg               r_conv_start;
  reg               r_conv_valid;
  reg               r_conv_stop;
  ctrl_reg          r_out_ctrl    [D_CONV+D_ACCUM-1:0];

//==========================================================
// main FSM
//==========================================================

  always @(posedge clk)
    if (!xrst)
      r_state <= S_WAIT;
    else
      case (r_state)
        S_WAIT:
          if (in_start)
            r_state <= S_ACTIVE;
        S_ACTIVE:
          if (out_stop)
            r_state <= S_WAIT;
      endcase

  always @(posedge clk)
    if (!xrst)
      r_core_state <= S_CORE_WAIT;
    else
      r_core_state <= core_state;

  assign w_fea_size = r_fea_size;

  always @(posedge clk)
    if (!xrst) begin
      r_img_size <= 0;
      r_fil_size <= 0;
      r_fea_size <= 0;
    end
    else if (r_state == S_WAIT && in_start) begin
      r_img_size <= w_img_size;
      r_fil_size <= w_fil_size;
      r_fea_size <= w_img_size - w_fil_size + 1;
    end

  always @(posedge clk)
    if (!xrst) begin
      r_conv_x <= 0;
      r_conv_y <= 0;
    end
    else
      case (r_state)
        S_WAIT: begin
          r_conv_x <= 0;
          r_conv_y <= 0;
        end
        S_ACTIVE:
          if (r_core_state == S_CORE_INPUT && in_valid)
            if (r_conv_x == r_img_size - 1) begin
              r_conv_x <= 0;
              if (r_conv_y == r_img_size - 1)
                r_conv_y <= 0;
              else
                r_conv_y <= r_conv_y + 1;
            end
            else
              r_conv_x <= r_conv_x + 1;
          else if (r_core_state == S_CORE_OUTPUT && !r_wait_back)
            if (r_conv_x == r_fea_size - 1) begin
              r_conv_x <= 0;
              if (r_conv_y == r_fea_size - 1)
                r_conv_y <= 0;
              else
                r_conv_y <= r_conv_y + 1;
            end
            else
              r_conv_x <= r_conv_x + 1;
      endcase

//==========================================================
// conv control
//==========================================================

  assign conv_ctrl.start = r_conv_ctrl.start;
  assign conv_ctrl.valid = r_conv_ctrl.valid;
  assign conv_ctrl.stop  = r_conv_ctrl.stop;

  always @(posedge clk)
    if (!xrst)
      r_conv_ctrl[0] <= '{0, 0, 0};
    else begin
      r_conv_ctrl.start <= r_state == S_ACTIVE
                            && r_core_state == S_CORE_INPUT
                            && r_last_input
                            && r_conv_x == r_img_size - 1
                            && r_conv_y == r_img_size - 1;
      r_conv_ctrl.valid <= r_state == S_ACTIVE
                            && r_core_state == S_CORE_OUTPUT
                            && r_conv_x <= r_fea_size - 1
                            && r_conv_y <= r_fea_size - 1
                            && !r_wait_back;
      r_conv_ctrl.stop  <= r_state == S_ACTIVE
                            && r_core_state == S_CORE_OUTPUT
                            && r_conv_x == r_fea_size - 1
                            && r_conv_y == r_fea_size - 1;
    end

  always @(posedge clk)
    if (!xrst) begin
      r_first_input <= 0;
      r_last_input  <= 0;
    end
    else begin
      r_first_input <= first_input;
      r_last_input  <= last_input;
    end

//==========================================================
// feat-accum control
//==========================================================

  assign mem_feat_we      = r_feat_we_d[D_CONV-1];
  assign mem_feat_rst     = r_feat_rst_d[D_CONV-1];
  assign mem_feat_addr    = r_feat_addr_d[D_CONV-1];
  assign mem_feat_addr_d1 = r_feat_addr_d[D_CONV];

  for (genvar i = 0; i < D_CONV; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst)
        else
    else
      always @(posedge clk)
        if (!xrst)
        else

  <%- for i in 0...$d_conv -%>
  always @(posedge clk)
    <%- if i == 0 -%>
    if (!xrst)
      r_feat_we_d0 <= 0;
    else
      r_feat_we_d0 <= conv_valid;
    <%- else -%>
    if (!xrst)
      r_feat_we_d<%=i%> <= 0;
    else
      r_feat_we_d<%=i%> <= r_feat_we_d<%=i-1%>;
    <%- end -%>
  <%- end -%>

  for (genvar i = 0; i < D_CONV; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst)
        else
    else
      always @(posedge clk)
        if (!xrst)
        else

  <%- for i in 0...$d_conv -%>
  always @(posedge clk)
    <%- if i == 0 -%>
    if (!xrst)
      r_feat_rst_d0 <= 0;
    else
      r_feat_rst_d0 <= conv_valid && r_first_input;
    <%- else -%>
    if (!xrst)
      r_feat_rst_d<%=i%> <= 0;
    else
      r_feat_rst_d<%=i%> <= r_feat_rst_d<%=i-1%>;
    <%- end -%>
  <%- end -%>

  for (genvar i = 0; i < D_CONV+1; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xsrt)
        else if ()
        else if ()
    else
      always @(posedge clk)
        if (!xrst)
        else

  <%- for i in 0..$d_conv -%>
  always @(posedge clk)
    <%- if i == 0 -%>
    if (!xrst)
      r_feat_addr_d0 <= 0;
    else if (conv_stop || r_wait_back)
      r_feat_addr_d0 <= 0;
    else if (conv_valid
              || (r_core_state == S_CORE_OUTPUT
                    && r_conv_x <= r_fea_size - 1
                    && r_conv_y <= r_fea_size - 1))
      r_feat_addr_d0 <= r_feat_addr_d0 + 1;
    <%- else -%>
    if (!xrst)
      r_feat_addr_d<%=i%> <= 0;
    else
      r_feat_addr_d<%=i%> <= r_feat_addr_d<%=i-1%>;
    <%- end -%>
  <%- end -%>

//==========================================================
// output control
//==========================================================

  assign out_start = r_out_start_d[D_CONV+D_ACCUM-1];
  assign out_valid = r_out_valid_d[D_CONV+D_ACCUM-1];
  assign out_stop   = r_out_stop_d[D_CONV+D_ACCUM-1];
  assign conv_oe   = r_out_valid_d[D_CONV+D_ACCUM-2];

  for (genvar i = 0; i < D_CONV+D_ACCUM; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst)
        else
    else
      always @(posedge clk)
        if (!xrst)
        else

  <%- for n in ["begin", "valid", "end"] -%>
  <%-   for i in 0...$d_conv+$d_accum -%>
  always @(posedge clk)
    <%- if i == 0 -%>
    if (!xrst)
      r_out_<%=n%>_d0 <= 0;
    else
      r_out_<%=n%>_d0 <= r_out_<%=n%>;
    <%- else -%>
    if (!xrst)
      r_out_<%=n%>_d<%=i%> <= 0;
    else
      r_out_<%=n%>_d<%=i%> <= r_out_<%=n%>_d<%=i-1%>;
    <%- end -%>
  <%-   end -%>
  <%- end -%>

  always @(posedge clk)
    if (!xrst)
      r_wait_back <= 0;
    else if (in_start)
      r_wait_back <= 0;
    else if ((r_state == S_ACTIVE)
                && (r_core_state == S_CORE_OUTPUT)
                && r_conv_x == r_fea_size - 1
                && r_conv_y == r_fea_size - 1)
      r_wait_back <= 1;

endmodule
