`include "renkon.svh"
`include "ctrl_bus.svh"

module renkon_ctrl_conv
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
  , output [FACCUM-1:0] mem_feat_addr_d1
  , output              conv_oe
  , output [LWIDTH-1:0] w_fea_size
  );

  localparam S_CORE_WAIT    = 'd0;
  localparam S_CORE_NETWORK = 'd1;
  localparam S_CORE_INPUT   = 'd2;
  localparam S_CORE_OUTPUT  = 'd3;

  ctrl_bus conv_ctrl();
  ctrl_bus accum_ctrl();

  enum reg {
    S_WAIT, S_ACTIVE
  } r_state;
  reg [2-1:0]       r_core_state;
  reg               r_wait_back;
  reg               r_first_input;
  reg               r_last_input;
  reg [LWIDTH-1:0]  r_img_size;
  reg [LWIDTH-1:0]  r_fil_size;
  reg [LWIDTH-1:0]  r_fea_size;
  reg               r_feat_we   [D_CONV-1:0];
  reg               r_feat_rst  [D_CONV-1:0];
  reg [FACCUM-1:0]  r_feat_addr [D_CONV:0];
  reg [LWIDTH-1:0]  r_conv_x;
  reg [LWIDTH-1:0]  r_conv_y;
  ctrl_reg          r_conv_ctrl;
  ctrl_reg          r_accum_ctrl;
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
          if (in_ctrl.start)
            r_state <= S_ACTIVE;
        S_ACTIVE:
          if (out_ctrl.stop)
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
    else if (r_state == S_WAIT && in_ctrl.start) begin
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
          if (r_core_state == S_CORE_INPUT && in_ctrl.valid)
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
      r_conv_ctrl <= '{0, 0, 0};
    else begin
      r_conv_ctrl.start <= r_state == S_ACTIVE
                            && r_core_state == S_CORE_INPUT
                            && r_conv_x == r_fil_size - 2
                            && r_conv_y == r_fil_size - 1;
      r_conv_ctrl.valid <= r_state == S_ACTIVE
                            && r_core_state == S_CORE_INPUT
                            && r_conv_x >= r_fil_size - 1
                            && r_conv_y >= r_fil_size - 1;
      r_conv_ctrl.stop  <= r_state == S_ACTIVE
                            && r_core_state == S_CORE_INPUT
                            && r_conv_x == r_img_size - 1
                            && r_conv_y == r_img_size - 1;
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
// mem_feat control
//==========================================================

  assign mem_feat_we      = r_feat_we[D_CONV-1];
  assign mem_feat_rst     = r_feat_rst[D_CONV-1];
  assign mem_feat_addr    = r_feat_addr[D_CONV-1];
  assign mem_feat_addr_d1 = r_feat_addr[D_CONV];

  for (genvar i = 0; i < D_CONV; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst)
          r_feat_we[0] <= 0;
        else
          r_feat_we[0] <= conv_ctrl.valid;
    else
      always @(posedge clk)
        if (!xrst)
          r_feat_we[i] <= 0;
        else
          r_feat_we[i] <= r_feat_we[i-1];

  for (genvar i = 0; i < D_CONV; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst)
          r_feat_rst[0] <= 0;
        else
          r_feat_rst[0] <= conv_ctrl.valid && r_first_input;
    else
      always @(posedge clk)
        if (!xrst)
          r_feat_rst[i] <= 0;
        else
          r_feat_rst[i] <= r_feat_rst[i-1];

  for (genvar i = 0; i < D_CONV+1; i++)
    if (i == 0) begin
      always @(posedge clk)
        if (!xrst)
          r_feat_addr[0] <= 0;
        else if (conv_ctrl.stop || r_wait_back)
          r_feat_addr[0] <= 0;
        else if (conv_ctrl.valid
                  || (r_core_state == S_CORE_OUTPUT
                        && r_conv_x <= r_fea_size - 1
                        && r_conv_y <= r_fea_size - 1))
          r_feat_addr[0] <= r_feat_addr[0] + 1;
    end
    else begin
      always @(posedge clk)
        if (!xrst)
          r_feat_addr[i] <= 0;
        else
          r_feat_addr[i] <= r_feat_addr[i-1];
    end

//==========================================================
// accum control
//==========================================================

  assign accum_ctrl.start = r_accum_ctrl.start;
  assign accum_ctrl.valid = r_accum_ctrl.valid;
  assign accum_ctrl.stop  = r_accum_ctrl.stop;

  always @(posedge clk)
    if (!xrst)
      r_accum_ctrl <= '{0, 0, 0};
    else begin
      r_accum_ctrl.start <= r_state == S_ACTIVE
                              && r_core_state == S_CORE_INPUT
                              && r_conv_x == r_img_size - 1
                              && r_conv_y == r_img_size - 1
                              && r_last_input;
      r_accum_ctrl.valid <= r_state == S_ACTIVE
                              && r_core_state == S_CORE_OUTPUT
                              && r_conv_x <= r_fea_size - 1
                              && r_conv_y <= r_fea_size - 1
                              && !r_wait_back;
      r_accum_ctrl.stop  <= r_state == S_ACTIVE
                              && r_core_state == S_CORE_OUTPUT
                              && r_conv_x == r_fea_size - 1
                              && r_conv_y == r_fea_size - 1;
    end

//==========================================================
// output control
//==========================================================

  assign out_ctrl.start = r_out_ctrl[D_CONV+D_ACCUM-1].start;
  assign out_ctrl.valid = r_out_ctrl[D_CONV+D_ACCUM-1].valid;
  assign out_ctrl.stop  = r_out_ctrl[D_CONV+D_ACCUM-1].stop;
  assign conv_oe        = r_out_ctrl[D_CONV+D_ACCUM-2].valid;

  for (genvar i = 0; i < D_CONV+D_ACCUM; i++)
    if (i == 0) begin
      always @(posedge clk)
        if (!xrst)
          r_out_ctrl[0] <= '{0, 0, 0};
        else begin
          r_out_ctrl[0].start <= accum_ctrl.start;
          r_out_ctrl[0].valid <= accum_ctrl.valid;
          r_out_ctrl[0].stop  <= accum_ctrl.stop;
        end
    end
    else begin
      always @(posedge clk)
        if (!xrst)
          r_out_ctrl[i] <= '{0, 0, 0};
        else begin
          r_out_ctrl[i].start <= r_out_ctrl[i-1].start;
          r_out_ctrl[i].valid <= r_out_ctrl[i-1].valid;
          r_out_ctrl[i].stop  <= r_out_ctrl[i-1].stop;
        end
    end

  always @(posedge clk)
    if (!xrst)
      r_wait_back <= 0;
    else if (in_ctrl.start)
      r_wait_back <= 0;
    else if ((r_state == S_ACTIVE)
                && (r_core_state == S_CORE_OUTPUT)
                && r_conv_x == r_fea_size - 1
                && r_conv_y == r_fea_size - 1)
      r_wait_back <= 1;

endmodule
