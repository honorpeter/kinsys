`include "renkon.svh"

module renkon_ctrl_conv
  ( input               clk
  , input               xrst
  , ctrl_bus.slave      in_ctrl
  , input  [2-1:0]      core_state
  , input  [LWIDTH-1:0] w_img_size
  , input  [LWIDTH-1:0] w_conv_size
  , input               first_input
  , input               last_input
  , ctrl_bus.master     out_ctrl
  , output              mem_feat_we
  , output              mem_feat_rst
  , output [FACCUM-1:0] mem_feat_raddr
  , output [FACCUM-1:0] mem_feat_waddr
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
  } state$;
  reg [2-1:0]       core_state$;
  reg               wait_back$;
  reg               first_input$;
  reg               last_input$;
  reg [LWIDTH-1:0]  img_size$;
  reg [LWIDTH-1:0]  conv_size$;
  reg [LWIDTH-1:0]  fea_size$;
  reg               feat_we$   [D_CONV-1:0];
  reg               feat_rst$  [D_CONV-1:0];
  reg [FACCUM-1:0]  feat_addr$ [D_CONV:0];
  reg [LWIDTH-1:0]  conv_x$;
  reg [LWIDTH-1:0]  conv_y$;
  ctrl_reg          conv_ctrl$;
  ctrl_reg          accum_ctrl$;
  ctrl_reg          out_ctrl$    [D_CONV+D_ACCUM-1:0];

//==========================================================
// main FSM
//==========================================================

  always @(posedge clk)
    if (!xrst)
      state$ <= S_WAIT;
    else
      case (state$)
        S_WAIT:
          if (in_ctrl.start)
            state$ <= S_ACTIVE;
        S_ACTIVE:
          if (out_ctrl.stop)
            state$ <= S_WAIT;
      endcase

  always @(posedge clk)
    if (!xrst)
      core_state$ <= S_CORE_WAIT;
    else
      core_state$ <= core_state;

  assign w_fea_size = fea_size$;

  always @(posedge clk)
    if (!xrst) begin
      img_size$   <= 0;
      conv_size$  <= 0;
      fea_size$   <= 0;
    end
    else if (state$ == S_WAIT && in_ctrl.start) begin
      img_size$   <= w_img_size;
      conv_size$  <= w_conv_size;
      fea_size$   <= w_img_size - w_conv_size + 1;
    end

  // always @(posedge clk)
  //   if (!xrst) begin
  //     conv_x$ <= 0;
  //     conv_y$ <= 0;
  //   end
  //   else
  //     case (state$)
  //       S_WAIT: begin
  //         conv_x$ <= 0;
  //         conv_y$ <= 0;
  //       end
  //       S_ACTIVE:
  //         if (core_state$ == S_CORE_INPUT && in_ctrl.valid)
  //           if (conv_x$ == img_size$ - 1) begin
  //             conv_x$ <= 0;
  //             if (conv_y$ == img_size$ - 1)
  //               conv_y$ <= 0;
  //             else
  //               conv_y$ <= conv_y$ + 1;
  //           end
  //           else
  //             conv_x$ <= conv_x$ + 1;
  //         else if (core_state$ == S_CORE_OUTPUT && !wait_back$)
  //           if (conv_x$ == fea_size$ - 1) begin
  //             conv_x$ <= 0;
  //             if (conv_y$ == fea_size$ - 1)
  //               conv_y$ <= 0;
  //             else
  //               conv_y$ <= conv_y$ + 1;
  //           end
  //           else
  //             conv_x$ <= conv_x$ + 1;
  //     endcase

  always @(posedge clk)
    if (!xrst) begin
      conv_x$ <= 0;
      conv_y$ <= 0;
    end
    else
      case (state$)
        S_WAIT: begin
          conv_x$ <= 0;
          conv_y$ <= 0;
        end
        S_ACTIVE:
          if (core_state$ == S_CORE_INPUT) begin
          //   if (conv_x$ == img_size$ - conv_size$ + 1) begin
          //     conv_x$ <= 0;
          //     if (conv_y$ == img_size$ - conv_size$ + 1)
          //       conv_y$ <= 0;
          //     else
          //       conv_y$ <= conv_y$ + 1;
          //   end
          //   else
          //     conv_x$ <= conv_x$ + 1;
            if (conv_x$ == fea_size$ - 1) begin
              conv_x$ <= 0;
              if (conv_y$ == fea_size$ - 1)
                conv_y$ <= 0;
              else
                conv_y$ <= conv_y$ + 1;
            end
            else if (in_ctrl.valid)
              conv_x$ <= conv_x$ + 1;
          end
          else if (core_state$ == S_CORE_OUTPUT && !wait_back$) begin
            if (conv_x$ == fea_size$ - 1) begin
              conv_x$ <= 0;
              if (conv_y$ == fea_size$ - 1)
                conv_y$ <= 0;
              else
                conv_y$ <= conv_y$ + 1;
            end
            else
              conv_x$ <= conv_x$ + 1;
          end
      endcase

//==========================================================
// conv control
//==========================================================

  assign conv_ctrl.start = in_ctrl.start;
  assign conv_ctrl.valid = in_ctrl.valid;
  assign conv_ctrl.stop  = in_ctrl.stop;
  // assign conv_ctrl.start = conv_ctrl$.start;
  // assign conv_ctrl.valid = conv_ctrl$.valid;
  // assign conv_ctrl.stop  = conv_ctrl$.stop;

  always @(posedge clk)
    if (!xrst) begin
      conv_ctrl$.start <= 0;
      conv_ctrl$.valid <= 0;
      conv_ctrl$.stop  <= 0;
    end
    else begin
      conv_ctrl$.start <= state$ == S_ACTIVE
                       && core_state$ == S_CORE_INPUT
                       && conv_x$ == conv_size$ - 2
                       && conv_y$ == conv_size$ - 1;

      conv_ctrl$.valid <= state$ == S_ACTIVE
                       && core_state$ == S_CORE_INPUT
                       && conv_x$ >= conv_size$ - 1
                       && conv_y$ >= conv_size$ - 1;

      conv_ctrl$.stop  <= state$ == S_ACTIVE
                       && core_state$ == S_CORE_INPUT
                       && conv_x$ == img_size$ - 1
                       && conv_y$ == img_size$ - 1;
    end

  always @(posedge clk)
    if (!xrst) begin
      first_input$ <= 0;
      last_input$  <= 0;
    end
    else begin
      first_input$ <= first_input;
      last_input$  <= last_input;
    end

//==========================================================
// mem_feat control
//==========================================================

  assign mem_feat_we      = feat_we$[D_CONV-1];
  assign mem_feat_rst     = feat_rst$[D_CONV-1];
  assign mem_feat_raddr   = feat_addr$[D_CONV-1];
  assign mem_feat_waddr   = feat_addr$[D_CONV];

  for (genvar i = 0; i < D_CONV; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst)
          feat_we$[0] <= 0;
        else
          feat_we$[0] <= conv_ctrl.valid;
    else
      always @(posedge clk)
        if (!xrst)
          feat_we$[i] <= 0;
        else
          feat_we$[i] <= feat_we$[i-1];

  for (genvar i = 0; i < D_CONV; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst)
          feat_rst$[0] <= 0;
        else
          feat_rst$[0] <= conv_ctrl.valid && first_input$;
    else
      always @(posedge clk)
        if (!xrst)
          feat_rst$[i] <= 0;
        else
          feat_rst$[i] <= feat_rst$[i-1];

  for (genvar i = 0; i < D_CONV+1; i++)
    if (i == 0) begin
      always @(posedge clk)
        if (!xrst)
          feat_addr$[0] <= 0;
        else if (conv_ctrl.stop || wait_back$)
          feat_addr$[0] <= 0;
        else if (
          conv_ctrl.valid || (core_state$ == S_CORE_OUTPUT
            && conv_x$ <= fea_size$ - 1 && conv_y$ <= fea_size$ - 1)
        )
          feat_addr$[0] <= feat_addr$[0] + 1;
    end
    else begin
      always @(posedge clk)
        if (!xrst)
          feat_addr$[i] <= 0;
        else
          feat_addr$[i] <= feat_addr$[i-1];
    end

//==========================================================
// accum control
//==========================================================

  assign accum_ctrl.start = accum_ctrl$.start;
  assign accum_ctrl.valid = accum_ctrl$.valid;
  assign accum_ctrl.stop  = accum_ctrl$.stop;

  always @(posedge clk)
    if (!xrst) begin
      accum_ctrl$.start <= 0;
      accum_ctrl$.valid <= 0;
      accum_ctrl$.stop  <= 0;
    end
    else begin
      accum_ctrl$.start <= state$ == S_ACTIVE
                        && core_state$ == S_CORE_INPUT
                        && conv_x$ == fea_size$ - 1
                        && conv_y$ == fea_size$ - 1
                        // && conv_x$ == img_size$ - 1
                        // && conv_y$ == img_size$ - 1
                        && last_input$;

      accum_ctrl$.valid <= state$ == S_ACTIVE
                        && core_state$ == S_CORE_OUTPUT
                        && conv_x$ <= fea_size$ - 1
                        && conv_y$ <= fea_size$ - 1
                        && !wait_back$;

      accum_ctrl$.stop  <= state$ == S_ACTIVE
                        && core_state$ == S_CORE_OUTPUT
                        && conv_x$ == fea_size$ - 1
                        && conv_y$ == fea_size$ - 1;
    end

//==========================================================
// output control
//==========================================================

  assign out_ctrl.start = out_ctrl$[D_CONV+D_ACCUM-1].start;
  assign out_ctrl.valid = out_ctrl$[D_CONV+D_ACCUM-1].valid;
  assign out_ctrl.stop  = out_ctrl$[D_CONV+D_ACCUM-1].stop;
  assign conv_oe        = out_ctrl$[D_CONV+D_ACCUM-2].valid;

  for (genvar i = 0; i < D_CONV+D_ACCUM; i++)
    if (i == 0) begin
      always @(posedge clk)
        if (!xrst) begin
          out_ctrl$[0].start <= 0;
          out_ctrl$[0].valid <= 0;
          out_ctrl$[0].stop  <= 0;
        end
        else begin
          // out_ctrl$[0].start <= accum_ctrl.start;
          // out_ctrl$[0].valid <= accum_ctrl.valid;
          // out_ctrl$[0].stop  <= accum_ctrl.stop;
          out_ctrl$[0].start <= state$ == S_ACTIVE
                            && core_state$ == S_CORE_INPUT
                            && conv_x$ == fea_size$ - 1
                            && conv_y$ == fea_size$ - 1
                            // && conv_x$ == img_size$ - 1
                            // && conv_y$ == img_size$ - 1
                            && last_input$;

          out_ctrl$[0].valid <= state$ == S_ACTIVE
                            && core_state$ == S_CORE_OUTPUT
                            && conv_x$ <= fea_size$ - 1
                            && conv_y$ <= fea_size$ - 1
                            && !wait_back$;

          out_ctrl$[0].stop  <= state$ == S_ACTIVE
                            && core_state$ == S_CORE_OUTPUT
                            && conv_x$ == fea_size$ - 1
                            && conv_y$ == fea_size$ - 1;
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

  always @(posedge clk)
    if (!xrst)
      wait_back$ <= 0;
    else if (in_ctrl.start)
      wait_back$ <= 0;
    else if (
      state$ == S_ACTIVE && core_state$ == S_CORE_OUTPUT
      && conv_x$ == fea_size$ - 1 && conv_y$ == fea_size$ - 1
    )
      wait_back$ <= 1;

endmodule
