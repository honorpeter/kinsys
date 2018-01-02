`include "gobou.svh"

module gobou_ctrl_core
  ( input                       clk
  , input                       xrst
  , ctrl_bus.slave              in_ctrl
  , input                       req
  , input  [GOBOU_CORELOG-1:0]  net_sel
  , input                       net_we
  , input  [GOBOU_NETSIZE-1:0]  net_addr
  , input  [MEMSIZE-1:0]        in_offset
  , input  [MEMSIZE-1:0]        out_offset
  , input  [GOBOU_NETSIZE-1:0]  net_offset
  , input  [LWIDTH-1:0]         total_out
  , input  [LWIDTH-1:0]         total_in
  , input                       bias_en
  , input                       relu_en
  , input  signed [DWIDTH-1:0]  out_wdata
  , ctrl_bus.master             out_ctrl
  , output                      ack
  , output                      img_we
  , output [MEMSIZE-1:0]        img_addr
  , output signed [DWIDTH-1:0]  img_wdata
  , output [GOBOU_CORE-1:0]     mem_net_we
  , output [GOBOU_NETSIZE-1:0]  mem_net_addr
  , output                      w_bias_en
  , output                      breg_we
  , output                      w_relu_en
  , output                      serial_we
  );

  localparam SETUP_TIME = 4;

  wire                s_setup_end;
  wire                s_input_end;
  wire                s_bias_end;
  wire                s_output_end;
  wire                req_edge;
  wire                final_iter;
  wire [MEMSIZE-1:0]  w_img_addr;
  wire [MEMSIZE-1:0]  w_img_offset;

  enum reg [3-1:0] {
    S_WAIT, S_SETUP, S_INPUT, S_BIAS, S_OUTPUT
  } state$;
  ctrl_reg                out_ctrl$;
  reg                     req$;
  reg                     ack$;
  reg [2-1:0]             setup$;
  reg [LWIDTH-1:0]        total_out$;
  reg [LWIDTH-1:0]        total_in$;
  reg [LWIDTH-1:0]        count_out$;
  reg [LWIDTH-1:0]        count_in$;
  reg                     img_we$;
  reg [MEMSIZE-1:0]       in_offset$;
  reg [MEMSIZE-1:0]       out_offset$;
  reg [MEMSIZE-1:0]       in_addr$;
  reg [MEMSIZE-1:0]       out_addr$;
  reg [GOBOU_CORE-1:0]    net_we$;
  reg [GOBOU_NETSIZE-1:0] net_addr$;
  reg [GOBOU_NETSIZE-1:0] net_offset$;
  reg                     bias_en$;
  reg                     breg_we$;
  reg                     relu_en$;
  reg                     serial_we$;
  reg [LWIDTH-1:0]        serial_cnt$;

//==========================================================
// core control
//==========================================================

  assign final_iter = state$ == S_OUTPUT
                   && count_out$ + GOBOU_CORE >= total_out$;

  assign s_setup_end = state$ == S_SETUP
                    && setup$ == SETUP_TIME - 1;

  assign req_edge = req && !req$;

  always @(posedge clk)
    if (!xrst)
      req$ <= 0;
    else
      req$ <= req;

  always @(posedge clk)
    if (!xrst) begin
      state$     <= S_WAIT;
      count_out$ <= 0;
      count_in$  <= 0;
    end
    else
      case (state$)
        S_WAIT:
          if (req_edge)
            state$ <= S_INPUT;
        S_SETUP:
          if (s_setup_end)
            state$ <= S_INPUT;
        S_INPUT:
          if (s_input_end) begin
            state$     <= S_BIAS;
            count_in$  <= 0;
          end
          else
            count_in$ <= count_in$ + 1;
        S_BIAS:
          if (s_bias_end)
            state$ <= S_OUTPUT;
        S_OUTPUT:
          if (s_output_end)
            if (count_out$ + GOBOU_CORE >= total_out$) begin
              state$     <= S_WAIT;
              count_out$ <= 0;
            end
            else begin
              state$     <= S_SETUP;
              count_out$ <= count_out$ + GOBOU_CORE;
            end
        default:
          state$ <= S_WAIT;
      endcase

  always @(posedge clk)
    if (!xrst)
      setup$ <= 0;
    else if (state$ == S_SETUP)
      if (setup$ == SETUP_TIME - 1)
        setup$ <= 0;
      else
        setup$ <= setup$ + 1;

//==========================================================
// params control
//==========================================================

  assign w_bias_en = bias_en$;
  assign w_relu_en = relu_en$;

  always @(posedge clk)
    if (!xrst) begin
      total_in$   <= 0;
      total_out$  <= 0;
      bias_en$    <= 0;
      relu_en$    <= 0;
    end
    else if (state$ == S_WAIT && req_edge) begin
      total_in$   <= total_in;
      total_out$  <= total_out;
      bias_en$    <= bias_en;
      relu_en$    <= relu_en;
    end

//==========================================================
// input control
//==========================================================

  assign s_input_end = state$ == S_INPUT && count_in$ == total_in$ - 1;

  assign img_we = img_we$;

  always @(posedge clk)
    if (!xrst)
      img_we$ <= 0;
    else
      case (state$)
        S_OUTPUT:
          img_we$ <= serial_we$
                   || (0 < serial_cnt$ && serial_cnt$ < GOBOU_CORE);
        default:
          img_we$ <= 0;
      endcase

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
    if (!xrst)
      in_addr$ <= 0;
    else if (state$ == S_BIAS)
      in_addr$ <= 0;
    else if (state$ == S_INPUT && !s_input_end)
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

  reg [MEMSIZE-1:0] img_addr$;
  assign img_addr = img_addr$;
  always @(posedge clk)
    if (!xrst)
      img_addr$ <= 0;
    else if (req_edge || ack)
      img_addr$ <= in_offset;
    else if (s_output_end)
      if (count_out$ + GOBOU_CORE >= total_out$)
        img_addr$ <= 0;
      else
        img_addr$ <= in_offset$;
    else if (s_input_end && count_in$ == total_in$ - 1)
      img_addr$ <= out_addr$ + out_offset$;
    else if (state$ == S_INPUT || img_we$)
      img_addr$ <= img_addr$ + 1;

//==========================================================
// network control
//==========================================================

  assign s_bias_end  = state$ == S_BIAS;

  // assign mem_net_we   = net_we$;
  // assign mem_net_addr = net_addr$ + net_offset$;
  for (genvar i = 0; i < GOBOU_CORE; i++)
    assign mem_net_we[i] = net_we & net_sel == i;
  assign mem_net_addr = net_we
                      ? net_addr
                      : net_addr$ + net_offset$;
  assign breg_we      = breg_we$;

  // for (genvar i = 0; i < GOBOU_CORE; i++)
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
    else if (final_iter)
      net_addr$ <= 0;
    else if (state$ == S_INPUT)
      net_addr$ <= net_addr$ + 1;
    else if (state$ == S_BIAS)
      net_addr$ <= net_addr$ + 1;

  always @(posedge clk)
    if (!xrst)
      net_offset$ <= 0;
    else if (req_edge || ack)
      net_offset$ <= net_offset;

  always @(posedge clk)
    if (!xrst)
      breg_we$ <= 0;
    else
      breg_we$ <= state$ == S_BIAS;

//==========================================================
// output control
//==========================================================

  assign s_output_end = state$ == S_OUTPUT && serial_cnt$ == GOBOU_CORE;

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
      out_ctrl$.start <= req_edge
                       || s_output_end && (count_out$ + GOBOU_CORE < total_out$);
      out_ctrl$.valid <= state$ == S_INPUT || state$ == S_BIAS;
      out_ctrl$.stop  <= s_bias_end;
    end

  assign ack = ack$;

  always @(posedge clk)
    if (!xrst)
      ack$ <= 1;
    else if (req_edge)
      ack$ <= 0;
    else if (s_output_end && count_out$ + GOBOU_CORE >= total_out$)
      ack$ <= 1;

  assign serial_we = serial_we$;

  always @(posedge clk)
    if (!xrst)
      serial_we$ <= 0;
    else
      serial_we$ <= in_ctrl.start;

  always @(posedge clk)
    if (!xrst)
      serial_cnt$ <= 0;
    else if (serial_we)
      serial_cnt$ <= 1;
    else if (serial_cnt$ > 0)
      if (serial_cnt$ == GOBOU_CORE)
        serial_cnt$ <= 0;
      else
        serial_cnt$ <= serial_cnt$ + 1;

endmodule
