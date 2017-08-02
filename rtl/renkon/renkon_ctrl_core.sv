`include "renkon.svh"

module renkon_ctrl_core
  ( input                       clk
  , input                       xrst
  , ctrl_bus.slave              in_ctrl
  , input                       req
  , input  signed [DWIDTH-1:0]  out_wdata
  , input  [RENKON_CORELOG-1:0] net_sel
  , input                       net_we
  , input  [RENKON_NETSIZE-1:0] net_addr
  , input  [IMGSIZE-1:0]        in_offset
  , input  [IMGSIZE-1:0]        out_offset
  , input  [RENKON_NETSIZE-1:0] net_offset
  , input  [LWIDTH-1:0]         total_out
  , input  [LWIDTH-1:0]         total_in
  , input  [LWIDTH-1:0]         img_size
  , input  [LWIDTH-1:0]         conv_size
  , input  [LWIDTH-1:0]         conv_pad
  , input                       buf_pix_ack
  , input                       buf_pix_valid
  , input                       buf_pix_ready

  , ctrl_bus.master             out_ctrl
  , output                      ack
  , output [2-1:0]              core_state
  , output                      img_we
  , output [IMGSIZE-1:0]        img_addr
  , output signed [DWIDTH-1:0]  img_wdata
  , output [RENKON_CORE-1:0]    mem_net_we
  , output [RENKON_NETSIZE-1:0] mem_net_addr
  , output                      buf_pix_req
  , output                      first_input
  , output                      last_input
  , output                      wreg_we
  , output                      breg_we
  , output                      serial_we
  , output [RENKON_CORELOG:0]   serial_re
  , output [OUTSIZE-1:0]        serial_addr
  , output [LWIDTH-1:0]         w_img_size
  , output [LWIDTH-1:0]         w_conv_size
  , output [LWIDTH-1:0]         w_conv_pad
  );

  wire               s_network_end;
  wire               s_input_end;
  wire               s_output_end;
  wire               s_w_weight_end;
  wire               s_w_bias_end;
  wire               req_edge;
  wire               final_iter;
  wire [IMGSIZE-1:0] w_img_addr;
  wire [IMGSIZE-1:0] w_img_offset;

  enum reg [2-1:0] {
    S_WAIT=0, S_NETWORK=1, S_INPUT=2, S_OUTPUT=3
  } state$ [D_PIXELBUF:0];
  enum reg {
    S_W_WEIGHT, S_W_BIAS
  } state_weight$ [D_PIXELBUF:0];
  reg               req$;
  reg               ack$;
  reg [LWIDTH-1:0]  total_out$;
  reg [LWIDTH-1:0]  total_in$;
  reg [LWIDTH-1:0]  img_size$;
  reg [LWIDTH-1:0]  conv_size$;
  reg [LWIDTH-1:0]  conv_pad$;
  reg [LWIDTH-1:0]  count_out$;
  reg [LWIDTH-1:0]  count_in$;
  reg [LWIDTH-1:0]  input_x$;
  reg [LWIDTH-1:0]  input_y$;
  reg [LWIDTH-1:0]  weight_x$;
  reg [LWIDTH-1:0]  weight_y$;
  reg [LWIDTH-1:0]  d_pixelbuf$;
  reg               buf_pix_req$;
  reg               img_we$;
  reg               out_we$;
  reg [IMGSIZE-1:0] in_offset$;
  reg [IMGSIZE-1:0] out_offset$;
  reg [IMGSIZE-1:0] in_addr$;
  reg [IMGSIZE-1:0] out_addr$;
  // reg [RENKON_CORE-1:0]    net_we$;
  reg [RENKON_NETSIZE-1:0] net_addr$;
  reg [RENKON_NETSIZE-1:0] net_offset$;
  reg               serial_we$;
  reg [RENKON_CORELOG:0]   serial_re$;
  reg [LWIDTH-1:0]  serial_cnt$;
  reg [OUTSIZE-1:0] serial_addr$;
  reg               serial_end$;
  reg               output_end$;
  reg               wreg_we$     [D_PIXELBUF-1:0];
  reg               first_input$ [D_PIXELBUF-1:0];
  reg               last_input$  [D_PIXELBUF-1:0];
  ctrl_reg          out_ctrl$    [D_PIXELBUF-1:0];

  // To avoid below:
  //   > Index xxxxxxxxxx into array dimension [32:0] is out of bounds.
  initial d_pixelbuf$ = 0;

//==========================================================
// core control
//==========================================================

  assign final_iter = count_in$ == total_in$ - 1
                   && count_out$ + RENKON_CORE >= total_out$;

  assign req_edge = req && !req$;

  always @(posedge clk)
    if (!xrst)
      req$ <= 0;
    else
      req$ <= req;

  //main FSM
  always @(posedge clk)
    if (!xrst) begin
      state$[0]  <= S_WAIT;
      count_in$  <= 0;
      count_out$ <= 0;
    end
    else
      case (state$[0])
        S_WAIT:
          if (req_edge)
            state$[0] <= S_NETWORK;
        S_NETWORK:
          if (s_network_end)
            state$[0] <= S_INPUT;
        S_INPUT:
          if (s_input_end)
            if (count_in$ == total_in$ - 1) begin
              state$[0]  <= S_OUTPUT;
              count_in$  <= 0;
            end
            else begin
              state$[0]  <= S_NETWORK;
              count_in$  <= count_in$ + 1;
            end
        S_OUTPUT:
          if (s_output_end)
            if (count_out$ + RENKON_CORE >= total_out$) begin
              state$[0]  <= S_WAIT;
              count_out$ <= 0;
            end
            else begin
              state$[0]  <= S_NETWORK;
              count_out$ <= count_out$ + RENKON_CORE;
            end
      endcase

  assign core_state = state$[d_pixelbuf$];

  for (genvar i = 1; i < D_PIXELBUF+1; i++)
    always @(posedge clk)
      if (!xrst)
        state$[i] <= S_WAIT;
      else
        state$[i] <= state$[i-1];

  assign w_img_size  = img_size$;
  assign w_conv_size = conv_size$;
  assign w_conv_pad  = conv_pad$;

  //wait exec (initialize)
  always @(posedge clk)
    if (!xrst) begin
      total_in$   <= 0;
      total_out$  <= 0;
      img_size$   <= 0;
      conv_size$  <= 0;
      d_pixelbuf$ <= 0;
    end
    else if (state$[0] == S_WAIT && req_edge) begin
      total_in$   <= total_in;
      total_out$  <= total_out;
      img_size$   <= img_size;
      conv_size$  <= conv_size;
      conv_pad$   <= conv_pad;
      d_pixelbuf$ <= img_size + 2;
    end

  assign first_input = first_input$[d_pixelbuf$];
  assign last_input  = last_input$[d_pixelbuf$];

  for (genvar i = 0; i < D_PIXELBUF; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst) begin
          first_input$[0] <= 0;
          last_input$[0]  <= 0;
        end
        else begin
          first_input$[0] <= state$[0] == S_INPUT
                          && count_in$ == 0;
          last_input$[0]  <= state$[0] == S_INPUT
                          && count_in$ == total_in$ - 1;
        end
    else
      always @(posedge clk)
        if (!xrst) begin
          first_input$[i] <= 0;
          last_input$[i]  <= 0;
        end
        else begin
          first_input$[i] <= first_input$[i-1];
          last_input$[i]  <= last_input$[i-1];
        end

//==========================================================
// network control
//==========================================================

  // assign mem_net_we   = net_we$;
  // assign mem_net_addr = net_addr$ + net_offset$;
  for (genvar i = 0; i < RENKON_CORE; i++)
    assign mem_net_we[i] = net_we & net_sel == i;
  assign mem_net_addr = net_we
                      ? net_addr
                      : net_addr$ + net_offset$;

  assign s_network_end = state$[0] == S_NETWORK
                      && count_in$ == total_in$ - 1
                       ? s_w_bias_end
                       : s_w_weight_end;

  assign s_w_weight_end = state_weight$[0] == S_W_WEIGHT
                       && weight_x$ == conv_size$ - 1
                       && weight_y$ == conv_size$ - 1;

  assign s_w_bias_end   = state_weight$[0] == S_W_BIAS;

  always @(posedge clk)
    if (!xrst)
      state_weight$[0] <= S_W_WEIGHT;
    else
      case (state_weight$[0])
        S_W_WEIGHT:
          if (s_w_weight_end && count_in$ == total_in$ - 1)
            state_weight$[0] <= S_W_BIAS;
        S_W_BIAS:
          if (s_w_bias_end)
            state_weight$[0] <= S_W_WEIGHT;
        default:
          state_weight$[0] <= S_W_WEIGHT;
      endcase

  for (genvar i = 1; i < D_PIXELBUF+1; i++)
    always @(posedge clk)
      if (!xrst)
        state_weight$[i] <= S_W_WEIGHT;
      else
        state_weight$[i] <= state_weight$[i-1];

  // for (genvar i = 0; i < RENKON_CORE; i++)
  //   always @(posedge clk)
  //     if (!xrst)
  //       net_we$[i] <= 0;
  //     else if (net_we == i+1)
  //       net_we$[i] <= 1;
  //     else
  //       net_we$[i] <= 0;

  always @(posedge clk)
    if (!xrst)
      net_addr$ <= 0;
    else if (final_iter && state_weight$[d_pixelbuf$] == S_W_BIAS)
      net_addr$ <= 0;
    else if (state$[d_pixelbuf$] == S_NETWORK)
      case (state_weight$[d_pixelbuf$])
        S_W_WEIGHT:
          net_addr$ <= net_addr$ + 1;
        S_W_BIAS:
          net_addr$ <= net_addr$ + 1;
        default:
          net_addr$ <= net_addr$;
      endcase

  always @(posedge clk)
    if (!xrst)
      net_offset$ <= 0;
    else if (req_edge || ack)
      net_offset$ <= net_offset;

  always @(posedge clk)
    if (!xrst) begin
      weight_x$ <= 0;
      weight_y$ <= 0;
    end
    else
      case (state$[0])
        S_NETWORK:
          case (state_weight$[0])
            S_W_WEIGHT:
              if (weight_x$ == conv_size$ - 1) begin
                weight_x$ <= 0;
                if (weight_y$ == conv_size$ - 1)
                  weight_y$ <= 0;
                else
                  weight_y$ <= weight_y$ + 1;
              end
              else
                weight_x$ <= weight_x$ + 1;
            default: begin
              weight_x$ <= 0;
              weight_y$ <= 0;
            end
          endcase
        default: begin
          weight_x$ <= 0;
          weight_y$ <= 0;
        end
      endcase

//==========================================================
// params control
//==========================================================

  assign wreg_we  = state$[d_pixelbuf$+1] == S_NETWORK
                 && state_weight$[d_pixelbuf$+1] == S_W_WEIGHT;

  assign breg_we  = state$[d_pixelbuf$+1] == S_NETWORK
                 && state_weight$[d_pixelbuf$+1] == S_W_BIAS;

  // assign buf_pix_req = buf_pix_req$;
  assign buf_pix_req = state$[0] == S_INPUT && out_ctrl$[0].start;

  always @(posedge clk)
    if (!xrst)
      buf_pix_req$ <= 0;
    else
      buf_pix_req$ <= state$[0] == S_INPUT
                   && out_ctrl$[0].start;

//==========================================================
// input control
//==========================================================

  assign s_input_end = state$[0] == S_INPUT
                    && input_x$ == img_size$ - 1
                    && input_y$ == img_size$ - 1;

  assign img_we   = img_we$;
  // assign img_addr = w_img_addr + w_img_offset;

  assign img_wdata = state$[0] == S_OUTPUT
                   ? out_wdata
                   : 0;

  assign w_img_addr = state$[0] == S_OUTPUT
                    ? out_addr$
                    : in_addr$;

  assign w_img_offset = state$[0] == S_OUTPUT
                      ? out_offset$
                      : in_offset$;

  always @(posedge clk)
    if (!xrst) begin
      input_x$ <= 0;
      input_y$ <= 0;
    end
    else
      case (state$[0])
        S_INPUT:
          if (input_x$ == img_size$ - 1) begin
            input_x$ <= 0;
            if (input_y$ == img_size$ - 1)
              input_y$ <= 0;
            else
              input_y$ <= input_y$ + 1;
          end
          else
            input_x$ <= input_x$ + 1;
        default: begin
          input_x$ <= 0;
          input_y$ <= 0;
        end
    endcase

  always @(posedge clk)
    if (!xrst)
      img_we$ <= 0;
    else
      case (state$[0])
        S_OUTPUT:
          img_we$ <= out_we$;
        default:
          img_we$ <= 0;
      endcase

  always @(posedge clk)
    if (!xrst)
      in_addr$ <= 0;
    else if (state$[0] == S_OUTPUT)
      in_addr$ <= 0;
    else if (state$[0] == S_INPUT)
      in_addr$ <= in_addr$ + 1;

  always @(posedge clk)
    if (!xrst)
      out_addr$ <= 0;
    else if (ack)
      out_addr$ <= 0;
    else if (img_we$)
      out_addr$ <= out_addr$ + 1;

  always @(posedge clk)
    if (!xrst) begin
      in_offset$ <= 0;
      out_offset$ <= 0;
    end
    else if (req_edge || ack) begin
      in_offset$ <= in_offset;
      out_offset$ <= out_offset;
    end

  reg [IMGSIZE-1:0] img_addr$;
  assign img_addr = img_addr$;
  always @(posedge clk)
    if (!xrst)
      img_addr$ <= 0;
    else if (req_edge || ack)
      img_addr$ <= in_offset;
    else if (s_output_end)
      if (count_out$ + RENKON_CORE >= total_out$)
        img_addr$ <= 0;
      else
        img_addr$ <= in_offset$;
    else if (s_input_end && count_in$ == total_in$ - 1)
      img_addr$ <= out_addr$ + out_offset$;
    else if (state$[0] == S_INPUT || img_we$)
      img_addr$ <= img_addr$ + 1;

//==========================================================
// output control
//==========================================================

  assign ack          = ack$;

  assign serial_we    = serial_we$;
  assign serial_re    = serial_re$;
  assign serial_addr  = serial_addr$;

  assign out_ctrl.start = out_ctrl$[d_pixelbuf$].start;
  assign out_ctrl.valid = out_ctrl$[d_pixelbuf$].valid;
  assign out_ctrl.stop  = out_ctrl$[d_pixelbuf$].stop;

  assign s_output_end = output_end$;

  always @(posedge clk)
    if (!xrst)
      serial_end$ <= 0;
    else
      serial_end$ <= serial_re$ == RENKON_CORE
                  && serial_addr$ == serial_cnt$ - 1;

  always @(posedge clk)
    if (!xrst)
      output_end$ <= 0;
    else
      output_end$ <= state$[0] == S_OUTPUT && serial_end$;

  always @(posedge clk)
    if (!xrst)
      out_we$ <= 0;
    else
      out_we$ <= serial_re$ > 0;

  always @(posedge clk)
    if (!xrst)
      ack$ <= 1;
    else if (req_edge)
      ack$ <= 0;
    else if (s_output_end && count_out$ + RENKON_CORE >= total_out$)
      ack$ <= 1;

  always @(posedge clk)
    if (!xrst)
      serial_we$ <= 0;
    else if (state$[0] == S_OUTPUT)
      if (in_ctrl.start)
        serial_we$ <= 1;
      else if (in_ctrl.stop)
        serial_we$ <= 0;

  always @(posedge clk)
    if (!xrst)
      serial_re$ <= 0;
    else if (in_ctrl.stop)
      serial_re$ <= 1;
    else if (serial_re$ > 0 && serial_addr$ == serial_cnt$ - 1)
      if (serial_re$ == RENKON_CORE)
        serial_re$ <= 0;
      else
        serial_re$ <= serial_re$ + 1;

  always @(posedge clk)
    if (!xrst)
      serial_cnt$ <= 0;
    else if (s_output_end)
      serial_cnt$ <= 0;
    else if (state$[0] == S_OUTPUT && in_ctrl.valid)
      serial_cnt$ <= serial_cnt$ + 1;

  always @(posedge clk)
    if (!xrst)
      serial_addr$ <= 0;
    else if (s_output_end)
      serial_addr$ <= 0;
    else if (state$[0] == S_OUTPUT && in_ctrl.valid)
      if (in_ctrl.stop)
        serial_addr$ <= 0;
      else
        serial_addr$ <= serial_addr$ + 1;
    else if (serial_re$ > 0)
      if (serial_addr$ == serial_cnt$ - 1)
        serial_addr$ <= 0;
      else
        serial_addr$ <= serial_addr$ + 1;

  for (genvar i = 0; i < D_PIXELBUF; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst) begin
          out_ctrl$[0].start <= 0;
          out_ctrl$[0].valid <= 0;
          out_ctrl$[0].stop  <= 0;
        end
        else begin
          out_ctrl$[0].start <= req_edge
                             || s_network_end
                             || s_input_end
                                && count_in$ != total_in$ - 1;

          out_ctrl$[0].valid <= state$[0] == S_NETWORK
                             || state$[0] == S_INPUT;

          out_ctrl$[0].stop  <= s_network_end || s_input_end;
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
