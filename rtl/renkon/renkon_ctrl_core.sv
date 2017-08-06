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

  , ctrl_bus.master             out_ctrl
  , output                      ack
  , output [2-1:0]              core_state
  , output                      img_we
  , output [IMGSIZE-1:0]        img_addr
  , output signed [DWIDTH-1:0]  img_wdata
  , output [RENKON_CORE-1:0]    mem_net_we
  , output [RENKON_NETSIZE-1:0] mem_net_addr
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
  , output [LWIDTH-1:0]         w_fea_size
  , output                            buf_pix_wcol
  , output                            buf_pix_rrow [FSIZE-1:0]
  , output [$clog2(FSIZE+1):0]        buf_pix_wsel
  , output [$clog2(FSIZE+1):0]        buf_pix_rsel
  , output                            buf_pix_we
  , output [$clog2(D_PIXELBUF+1)-1:0] buf_pix_addr
  );



  wire               s_network_end;
  wire               s_input_end;
  wire               s_output_end;
  wire               s_w_weight_end;
  wire               s_w_bias_end;
  wire               req_edge;
  wire               final_iter;
  wire [LWIDTH-1:0]  conv_pad_both;
  wire [IMGSIZE-1:0] w_img_addr;
  wire [IMGSIZE-1:0] w_img_offset;
  wire               buf_pix_req;
  wire               buf_pix_ack;
  wire               buf_pix_start;
  wire               buf_pix_valid;
  wire               buf_pix_ready;
  wire               buf_pix_stop;



  enum reg [2-1:0] {
    S_WAIT=0, S_NETWORK=1, S_INPUT=2, S_OUTPUT=3
  } state$;
  enum reg {
    S_W_WEIGHT, S_W_BIAS
  } state_weight$;

  reg               req$;
  reg               ack$;

  reg [LWIDTH-1:0]  total_out$;
  reg [LWIDTH-1:0]  total_in$;
  reg [LWIDTH-1:0]  img_size$;
  reg [LWIDTH-1:0]  conv_size$;
  reg [LWIDTH-1:0]  conv_pad$;
  reg [LWIDTH-1:0]  fea_size$;

  reg [LWIDTH-1:0]  count_out$;
  reg [LWIDTH-1:0]  count_in$;
  reg [LWIDTH-1:0]  input_x$;
  reg [LWIDTH-1:0]  input_y$;
  reg [LWIDTH-1:0]  weight_x$;
  reg [LWIDTH-1:0]  weight_y$;

  reg               s_output_end$;
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
  reg               first_input$;
  reg               last_input$;
  reg               wreg_we$;
  reg               breg_we$;



//==========================================================
// core control
//==========================================================

  assign final_iter = count_in$ == total_in$ - 1
                   && count_out$ + RENKON_CORE >= total_out$;

  assign req_edge = req && !req$;

  assign core_state = state$;

  // equals to 2 * pad_size
  assign conv_pad_both = conv_pad << 1;

  always @(posedge clk)
    if (!xrst)
      req$ <= 0;
    else
      req$ <= req;

  //main FSM
  always @(posedge clk)
    if (!xrst) begin
      state$     <= S_WAIT;
      count_in$  <= 0;
      count_out$ <= 0;
    end
    else
      case (state$)
        S_WAIT:
          if (req_edge)
            state$ <= S_NETWORK;
        S_NETWORK:
          if (s_network_end)
            state$ <= S_INPUT;
        S_INPUT:
          if (s_input_end)
            if (count_in$ == total_in$ - 1) begin
              state$     <= S_OUTPUT;
              count_in$  <= 0;
            end
            else begin
              state$     <= S_NETWORK;
              count_in$  <= count_in$ + 1;
            end
        S_OUTPUT:
          if (s_output_end)
            if (count_out$ + RENKON_CORE >= total_out$) begin
              state$     <= S_WAIT;
              count_out$ <= 0;
            end
            else begin
              state$     <= S_NETWORK;
              count_out$ <= count_out$ + RENKON_CORE;
            end
      endcase

  assign w_img_size  = img_size$;
  assign w_conv_size = conv_size$;
  assign w_conv_pad  = conv_pad$;
  assign w_fea_size  = fea_size$;

  //wait exec (initialize)
  always @(posedge clk)
    if (!xrst) begin
      total_in$   <= 0;
      total_out$  <= 0;
      img_size$   <= 0;
      conv_size$  <= 0;
      conv_pad$   <= 0;
      fea_size$   <= 0;
    end
    else if (state$ == S_WAIT && req_edge) begin
      total_in$   <= total_in;
      total_out$  <= total_out;
      img_size$   <= img_size;
      conv_size$  <= conv_size;
      conv_pad$   <= conv_pad;
      fea_size$   <= img_size + conv_pad_both - conv_size + 1;
    end

  assign first_input = first_input$;
  assign last_input  = last_input$;

  always @(posedge clk)
    if (!xrst) begin
      first_input$ <= 0;
      last_input$  <= 0;
    end
    else begin
      first_input$ <= state$ == S_INPUT
                   && count_in$ == 0;
      last_input$  <= state$ == S_INPUT
                   && count_in$ == total_in$ - 1;
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

  assign s_network_end = state$ == S_NETWORK
                      && count_in$ == total_in$ - 1
                       ? s_w_bias_end
                       : s_w_weight_end;

  assign s_w_weight_end = state_weight$ == S_W_WEIGHT
                       && weight_x$ == conv_size$ - 1
                       && weight_y$ == conv_size$ - 1;

  assign s_w_bias_end   = state_weight$ == S_W_BIAS;

  always @(posedge clk)
    if (!xrst)
      state_weight$ <= S_W_WEIGHT;
    else
      case (state_weight$)
        S_W_WEIGHT:
          if (s_w_weight_end && count_in$ == total_in$ - 1)
            state_weight$ <= S_W_BIAS;
        S_W_BIAS:
          if (s_w_bias_end)
            state_weight$ <= S_W_WEIGHT;
        default:
          state_weight$ <= S_W_WEIGHT;
      endcase

  always @(posedge clk)
    if (!xrst)
      net_addr$ <= 0;
    else if (final_iter && state_weight$ == S_W_BIAS)
      net_addr$ <= 0;
    else if (state$ == S_NETWORK)
      case (state_weight$)
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
      case (state$)
        S_NETWORK:
          case (state_weight$)
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

  assign wreg_we = wreg_we$;
  assign breg_we = breg_we$;

  always @(posedge clk)
    if (!xrst) begin
      wreg_we$ <= 0;
      breg_we$ <= 0;
    end
    else if (state$ != S_NETWORK) begin
      wreg_we$ <= 0;
      breg_we$ <= 0;
    end
    else begin
      wreg_we$ <= state_weight$ == S_W_WEIGHT;
      breg_we$ <= state_weight$ == S_W_BIAS;
    end

  // assign buf_pix_req = buf_pix_req$;
  assign buf_pix_req = s_network_end;

  always @(posedge clk)
    if (!xrst)
      buf_pix_req$ <= 0;
    else
      buf_pix_req$ <= s_network_end;

//==========================================================
// input control
//==========================================================

  assign s_input_end = state$ == S_INPUT
                    && input_x$ == img_size$ - conv_size$
                    && input_y$ == img_size$ - conv_size$;

  assign img_we   = img_we$;
  // assign img_addr = w_img_addr + w_img_offset;

  assign img_wdata = state$ == S_OUTPUT
                   ? out_wdata
                   : 0;

  assign w_img_addr = state$ == S_OUTPUT
                    ? out_addr$
                    : in_addr$;

  assign w_img_offset = state$ == S_OUTPUT
                      ? out_offset$
                      : in_offset$;

  always @(posedge clk)
    if (!xrst) begin
      input_x$ <= 0;
      input_y$ <= 0;
    end
    else
      case (state$)
        S_INPUT: if (buf_pix_valid) begin
          if (input_x$ == img_size$ - conv_size$) begin
            input_x$ <= 0;
            if (input_y$ == img_size$ - conv_size$)
              input_y$ <= 0;
            else
              input_y$ <= input_y$ + 1;
          end
          else
            input_x$ <= input_x$ + 1;
        end
        default: begin
          input_x$ <= 0;
          input_y$ <= 0;
        end
      endcase

  always @(posedge clk)
    if (!xrst)
      img_we$ <= 0;
    else
      case (state$)
        S_OUTPUT:
          img_we$ <= out_we$;
        default:
          img_we$ <= 0;
      endcase

  always @(posedge clk)
    if (!xrst)
      in_addr$ <= 0;
    else if (state$ == S_OUTPUT)
      in_addr$ <= 0;
    else if (state$ == S_INPUT)
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

  // TODO: split modes
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
    else if (buf_pix_ready || img_we$)
      img_addr$ <= img_addr$ + 1;

//==========================================================
// output control
//==========================================================

  assign s_output_end = s_output_end$;

  assign ack          = ack$;

  assign serial_we   = serial_we$;
  assign serial_re   = serial_re$;
  assign serial_addr = serial_addr$;

  assign out_ctrl.start = buf_pix_start;
  assign out_ctrl.valid = buf_pix_valid;
  assign out_ctrl.stop  = buf_pix_stop;

  always @(posedge clk)
    if (!xrst)
      serial_end$ <= 0;
    else
      serial_end$ <= serial_re$ == RENKON_CORE
                  && serial_addr$ == serial_cnt$ - 1;

  always @(posedge clk)
    if (!xrst)
      s_output_end$ <= 0;
    else
      s_output_end$ <= state$ == S_OUTPUT
                    && serial_end$;

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
    else if (state$ == S_OUTPUT)
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
    else if (state$ == S_OUTPUT && in_ctrl.valid)
      serial_cnt$ <= serial_cnt$ + 1;

  always @(posedge clk)
    if (!xrst)
      serial_addr$ <= 0;
    else if (s_output_end)
      serial_addr$ <= 0;
    else if (state$ == S_OUTPUT && in_ctrl.valid)
      if (in_ctrl.stop)
        serial_addr$ <= 0;
      else
        serial_addr$ <= serial_addr$ + 1;
    else if (serial_re$ > 0)
      if (serial_addr$ == serial_cnt$ - 1)
        serial_addr$ <= 0;
      else
        serial_addr$ <= serial_addr$ + 1;

  renkon_ctrl_linebuf_pad #(FSIZE, D_PIXELBUF) ctrl_buf_pix(
    .img_size   (img_size$),
    .fil_size   (conv_size$),
    .pad_size   (conv_pad$),

    .buf_req    (buf_pix_req),
    .buf_ack    (buf_pix_ack),
    .buf_start  (buf_pix_start),
    .buf_valid  (buf_pix_valid),
    .buf_ready  (buf_pix_ready),
    .buf_stop   (buf_pix_stop),

    .buf_wcol   (buf_pix_wcol),
    .buf_rrow   (buf_pix_rrow),
    .buf_wsel   (buf_pix_wsel),
    .buf_rsel   (buf_pix_rsel),
    .buf_we     (buf_pix_we),
    .buf_addr   (buf_pix_addr),
    .*
  );

endmodule
