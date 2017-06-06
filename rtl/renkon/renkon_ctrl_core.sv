`include "renkon.svh"

module renkon_ctrl_core
  ( input                       clk
  , input                       xrst
  , ctrl_bus.slave              in_ctrl
  , input                       req
  , input  [RENKON_CORELOG-1:0] net_sel
  , input                       net_we
  , input  [RENKON_NETSIZE-1:0] net_addr
  , input  [IMGSIZE-1:0]        in_offset
  , input  [IMGSIZE-1:0]        out_offset
  , input  [RENKON_NETSIZE-1:0] net_offset
  , input  [LWIDTH-1:0]         total_out
  , input  [LWIDTH-1:0]         total_in
  , input  [LWIDTH-1:0]         img_size
  , input  [LWIDTH-1:0]         fil_size
  , input  signed [DWIDTH-1:0]  out_wdata
`ifdef DIST
`else
  , input                       img_we
  , input  signed [DWIDTH-1:0]  img_wdata
`endif
  , ctrl_bus.master             out_ctrl
  , output                      ack
  , output [2-1:0]              core_state
  , output                      mem_img_we
  , output [IMGSIZE-1:0]        mem_img_addr
  , output signed [DWIDTH-1:0]  mem_img_wdata
  , output [RENKON_CORE-1:0]    mem_net_we
  , output [RENKON_NETSIZE-1:0] mem_net_addr
  , output                      buf_pix_en
  , output                      first_input
  , output                      last_input
  , output                      wreg_we
  , output                      breg_we
  , output                      serial_we
  , output [RENKON_CORELOG:0]   serial_re
  , output [OUTSIZE-1:0]        serial_addr
  , output [LWIDTH-1:0]         w_img_size
  , output [LWIDTH-1:0]         w_fil_size
  );

  wire               s_network_end;
  wire               s_input_end;
  wire               s_output_end;
  wire               s_w_weight_end;
  wire               s_w_bias_end;
  wire               final_iter;
  wire [IMGSIZE-1:0] w_img_addr;
  wire [IMGSIZE-1:0] w_img_offset;

  enum reg [2-1:0] {
    S_WAIT=0, S_NETWORK=1, S_INPUT=2, S_OUTPUT=3
  } r_state [D_PIXELBUF:0];
  enum reg {
    S_W_WEIGHT, S_W_BIAS
  } r_state_weight [D_PIXELBUF:0];
  reg               r_ack;
  reg [LWIDTH-1:0]  r_total_out;
  reg [LWIDTH-1:0]  r_total_in;
  reg [LWIDTH-1:0]  r_img_size;
  reg [LWIDTH-1:0]  r_fil_size;
  reg [LWIDTH-1:0]  r_pool_size;
  reg [LWIDTH-1:0]  r_count_out;
  reg [LWIDTH-1:0]  r_count_in;
  reg [LWIDTH-1:0]  r_input_x;
  reg [LWIDTH-1:0]  r_input_y;
  reg [LWIDTH-1:0]  r_weight_x;
  reg [LWIDTH-1:0]  r_weight_y;
  reg [LWIDTH-1:0]  r_d_pixelbuf;
  reg               r_buf_pix_en;
  reg               r_img_we;
  reg               r_out_we;
  reg [IMGSIZE-1:0] r_input_offset;
  reg [IMGSIZE-1:0] r_input_addr;
  reg [IMGSIZE-1:0] r_output_offset;
  reg [IMGSIZE-1:0] r_output_addr;
  reg [RENKON_CORE-1:0]    r_net_we;
  reg [RENKON_NETSIZE-1:0] r_net_addr;
  reg [RENKON_NETSIZE-1:0] r_net_offset;
  reg               r_serial_we;
  reg [RENKON_CORELOG:0]   r_serial_re;
  reg [LWIDTH-1:0]  r_serial_cnt;
  reg [OUTSIZE-1:0] r_serial_addr;
  reg               r_serial_end;
  reg               r_output_end;
  reg               r_wreg_we     [D_PIXELBUF-1:0];
  reg               r_first_input [D_PIXELBUF-1:0];
  reg               r_last_input  [D_PIXELBUF-1:0];
  ctrl_reg          r_out_ctrl    [D_PIXELBUF-1:0];

//==========================================================
// core control
//==========================================================

  assign final_iter = r_count_in == r_total_in - 1
                   && r_count_out + RENKON_CORE >= r_total_out;

  //main FSM
  always @(posedge clk)
    if (!xrst) begin
      r_state[0]  <= S_WAIT;
      r_count_in  <= 0;
      r_count_out <= 0;
    end
    else
      case (r_state[0])
        S_WAIT:
          if (req)
            r_state[0] <= S_NETWORK;
        S_NETWORK:
          if (s_network_end)
            r_state[0] <= S_INPUT;
        S_INPUT:
          if (s_input_end)
            if (r_count_in == r_total_in - 1) begin
              r_state[0]  <= S_OUTPUT;
              r_count_in  <= 0;
            end
            else begin
              r_state[0]  <= S_NETWORK;
              r_count_in  <= r_count_in + 1;
            end
        S_OUTPUT:
          if (s_output_end)
            if (r_count_out + RENKON_CORE >= r_total_out) begin
              r_state[0]  <= S_WAIT;
              r_count_out <= 0;
            end
            else begin
              r_state[0]  <= S_NETWORK;
              r_count_out <= r_count_out + RENKON_CORE;
            end
      endcase

  for (genvar i = 1; i < D_PIXELBUF+1; i++)
    always @(posedge clk)
      if (!xrst)
        r_state[i] <= S_WAIT;
      else
        r_state[i] <= r_state[i-1];

  assign w_img_size = r_img_size;
  assign w_fil_size = r_fil_size;

  //wait exec (initialize)
  initial r_d_pixelbuf = 0;
  always @(posedge clk)
    if (!xrst) begin
      r_total_in    <= 0;
      r_total_out   <= 0;
      r_img_size    <= 0;
      r_fil_size    <= 0;
      r_d_pixelbuf  <= 0;
    end
    else if (r_state[0] == S_WAIT && req) begin
      r_total_in    <= total_in;
      r_total_out   <= total_out;
      r_img_size    <= img_size;
      r_fil_size    <= fil_size;
      r_d_pixelbuf  <= img_size + 2;
    end

  assign first_input = r_first_input[r_d_pixelbuf];
  assign last_input  = r_last_input[r_d_pixelbuf];

  for (genvar i = 0; i < D_PIXELBUF; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst) begin
          r_first_input[0] <= 0;
          r_last_input[0]  <= 0;
        end
        else begin
          r_first_input[0] <= r_state[0] == S_INPUT
                                && r_count_in == 0;
          r_last_input[0]  <= r_state[0] == S_INPUT
                                && r_count_in == r_total_in - 1;
        end
    else
      always @(posedge clk)
        if (!xrst) begin
          r_first_input[i] <= 0;
          r_last_input[i]  <= 0;
        end
        else begin
          r_first_input[i] <= r_first_input[i-1];
          r_last_input[i]  <= r_last_input[i-1];
        end

  assign core_state = r_state[r_d_pixelbuf];

//==========================================================
// network control
//==========================================================

  assign mem_net_we   = r_net_we;
  assign mem_net_addr = r_net_addr + r_net_offset;

  assign s_network_end = r_state[0] == S_NETWORK
                            && r_count_in == r_total_in - 1
                        ? s_w_bias_end
                        : s_w_weight_end;

  assign s_w_weight_end = r_state_weight[0] == S_W_WEIGHT
                        && r_weight_x == r_fil_size - 1
                        && r_weight_y == r_fil_size - 1;

  assign s_w_bias_end   = r_state_weight[0] == S_W_BIAS;

  always @(posedge clk)
    if (!xrst)
      r_state_weight[0] <= S_W_WEIGHT;
    else
      case (r_state_weight[0])
        S_W_WEIGHT:
          if (s_w_weight_end && r_count_in == r_total_in - 1)
            r_state_weight[0] <= S_W_BIAS;
        S_W_BIAS:
          if (s_w_bias_end)
            r_state_weight[0] <= S_W_WEIGHT;
        default:
          r_state_weight[0] <= S_W_WEIGHT;
      endcase

  for (genvar i = 1; i < D_PIXELBUF+1; i++)
    always @(posedge clk)
      if (!xrst)
        r_state_weight[i] <= S_W_WEIGHT;
      else
        r_state_weight[i] <= r_state_weight[i-1];

  for (genvar i = 0; i < RENKON_CORE; i++)
    always @(posedge clk)
      if (!xrst)
        r_net_we[i] <= 0;
      else if (net_we == i+1)
        r_net_we[i] <= 1;
      else
        r_net_we[i] <= 0;

  always @(posedge clk)
    if (!xrst)
      r_net_addr <= 0;
    else if (final_iter && r_state_weight[r_d_pixelbuf] == S_W_BIAS)
      r_net_addr <= 0;
    else if (r_state[r_d_pixelbuf] == S_NETWORK)
      case (r_state_weight[r_d_pixelbuf])
        S_W_WEIGHT:
          r_net_addr <= r_net_addr + 1;
        S_W_BIAS:
          r_net_addr <= r_net_addr + 1;
        default:
          r_net_addr <= r_net_addr;
      endcase

  always @(posedge clk)
    if (!xrst)
      r_net_offset <= 0;
    else if (req || ack)
      r_net_offset <= net_addr;

  always @(posedge clk)
    if (!xrst) begin
      r_weight_x <= 0;
      r_weight_y <= 0;
    end
    else
      case (r_state[0])
        S_NETWORK:
          case (r_state_weight[0])
            S_W_WEIGHT:
              if (r_weight_x == r_fil_size - 1) begin
                r_weight_x <= 0;
                if (r_weight_y == r_fil_size - 1)
                  r_weight_y <= 0;
                else
                  r_weight_y <= r_weight_y + 1;
              end
              else
                r_weight_x <= r_weight_x + 1;
            default: begin
              r_weight_x <= 0;
              r_weight_y <= 0;
            end
          endcase
        default: begin
          r_weight_x <= 0;
          r_weight_y <= 0;
        end
      endcase

//==========================================================
// params control
//==========================================================

  assign wreg_we  = r_state[r_d_pixelbuf+1] == S_NETWORK
                 && r_state_weight[r_d_pixelbuf+1] == S_W_WEIGHT;

  assign breg_we  = r_state[r_d_pixelbuf+1] == S_NETWORK
                 && r_state_weight[r_d_pixelbuf+1] == S_W_BIAS;

  assign buf_pix_en = r_buf_pix_en;

  always @(posedge clk)
    if (!xrst)
      r_buf_pix_en <= 0;
    else
      r_buf_pix_en <= r_state[0] == S_INPUT
                   && r_out_ctrl[0].start;

//==========================================================
// input control
//==========================================================

  assign s_input_end = r_state[0] == S_INPUT
                     && r_input_x == r_img_size - 1
                     && r_input_y == r_img_size - 1;

  assign mem_img_we   = r_img_we;
  assign mem_img_addr = w_img_addr + w_img_offset;

`ifdef DIST
  assign mem_img_wdata = r_state[0] == S_OUTPUT
                       ? out_wdata
                       : 0;
`else
  assign mem_img_wdata = r_state[0] == S_OUTPUT
                       ? out_wdata
                       : img_wdata;
`endif

  assign w_img_addr = r_state[0] == S_OUTPUT
                    ? r_output_addr
                    : r_input_addr;

  assign w_img_offset = r_state[0] == S_OUTPUT
                      ? r_output_offset
                      : r_input_offset;

  always @(posedge clk)
    if (!xrst) begin
      r_input_x <= 0;
      r_input_y <= 0;
    end
    else
      case (r_state[0])
        S_INPUT:
          if (r_input_x == r_img_size - 1) begin
            r_input_x <= 0;
            if (r_input_y == r_img_size - 1)
              r_input_y <= 0;
            else
              r_input_y <= r_input_y + 1;
          end
          else
            r_input_x <= r_input_x + 1;
        default: begin
          r_input_x <= 0;
          r_input_y <= 0;
        end
    endcase

`ifdef DIST
  always @(posedge clk)
    if (!xrst)
      r_img_we <= 0;
    else
      case (r_state[0])
        S_OUTPUT:
          r_img_we <= r_out_we;
        default:
          r_img_we <= 0;
      endcase
`else
  always @(posedge clk)
    if (!xrst)
      r_img_we <= 0;
    else
      case (r_state[0])
        S_WAIT:
          r_img_we <= img_we;
        S_OUTPUT:
          r_img_we <= r_out_we;
        default:
          r_img_we <= 0;
      endcase
`endif

  always @(posedge clk)
    if (!xrst)
      r_input_addr <= 0;
    else if (r_state[0] == S_OUTPUT)
      r_input_addr <= 0;
    else if (r_state[0] == S_INPUT)
      r_input_addr <= r_input_addr + 1;

  always @(posedge clk)
    if (!xrst)
      r_output_addr <= 0;
    else if (ack)
      r_output_addr <= 0;
    else if (r_img_we)
      r_output_addr <= r_output_addr + 1;

  always @(posedge clk)
    if (!xrst) begin
      r_input_offset <= 0;
      r_output_offset <= 0;
    end
    else if (req || ack) begin
      r_input_offset <= in_offset;
      r_output_offset <= out_offset;
    end

//==========================================================
// output control
//==========================================================

  assign ack          = r_ack;

  assign serial_we    = r_serial_we;
  assign serial_re    = r_serial_re;
  assign serial_addr  = r_serial_addr;

  assign out_ctrl.start = r_out_ctrl[r_d_pixelbuf].start;
  assign out_ctrl.valid = r_out_ctrl[r_d_pixelbuf].valid;
  assign out_ctrl.stop  = r_out_ctrl[r_d_pixelbuf].stop;

  assign s_output_end = r_output_end;

  always @(posedge clk)
    if (!xrst)
      r_serial_end <= 0;
    else
      r_serial_end <= r_serial_re == RENKON_CORE
                   && r_serial_addr == r_serial_cnt - 1;

  always @(posedge clk)
    if (!xrst)
      r_output_end <= 0;
    else
      r_output_end <= r_state[0] == S_OUTPUT && r_serial_end;

  always @(posedge clk)
    if (!xrst)
      r_out_we <= 0;
    else
      r_out_we <= r_serial_re > 0;

  always @(posedge clk)
    if (!xrst)
      r_ack <= 1;
    else if (req)
      r_ack <= 0;
    else if (s_output_end && r_count_out + RENKON_CORE >= r_total_out)
      r_ack <= 1;

  always @(posedge clk)
    if (!xrst)
      r_serial_we <= 0;
    else if (r_state[0] == S_OUTPUT)
      if (in_ctrl.start)
        r_serial_we <= 1;
      else if (in_ctrl.stop)
        r_serial_we <= 0;

  always @(posedge clk)
    if (!xrst)
      r_serial_re <= 0;
    else if (in_ctrl.stop)
      r_serial_re <= 1;
    else if (r_serial_re > 0 && r_serial_addr == r_serial_cnt - 1)
      if (r_serial_re == RENKON_CORE)
        r_serial_re <= 0;
      else
        r_serial_re <= r_serial_re + 1;

  always @(posedge clk)
    if (!xrst)
      r_serial_cnt <= 0;
    else if (s_output_end)
      r_serial_cnt <= 0;
    else if (r_state[0] == S_OUTPUT && in_ctrl.valid)
      r_serial_cnt <= r_serial_cnt + 1;

  always @(posedge clk)
    if (!xrst)
      r_serial_addr <= 0;
    else if (s_output_end)
      r_serial_addr <= 0;
    else if (r_state[0] == S_OUTPUT && in_ctrl.valid)
      if (in_ctrl.stop)
        r_serial_addr <= 0;
        else
        r_serial_addr <= r_serial_addr + 1;
    else if (r_serial_re > 0)
      if (r_serial_addr == r_serial_cnt - 1)
        r_serial_addr <= 0;
      else
        r_serial_addr <= r_serial_addr + 1;

  for (genvar i = 0; i < D_PIXELBUF; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst) begin
          r_out_ctrl[0].start <= 0;
          r_out_ctrl[0].valid <= 0;
          r_out_ctrl[0].stop  <= 0;
        end
        else begin
          r_out_ctrl[0].start <= req
                              || s_network_end
                              || s_input_end
                                  && r_count_in != r_total_in - 1;
          r_out_ctrl[0].valid <= r_state[0] == S_NETWORK
                              || r_state[0] == S_INPUT;
          r_out_ctrl[0].stop  <= s_network_end || s_input_end;
        end
    else
      always @(posedge clk)
        if (!xrst) begin
          r_out_ctrl[i].start <= 0;
          r_out_ctrl[i].valid <= 0;
          r_out_ctrl[i].stop  <= 0;
        end
        else begin
          r_out_ctrl[i].start <= r_out_ctrl[i-1].start;
          r_out_ctrl[i].valid <= r_out_ctrl[i-1].valid;
          r_out_ctrl[i].stop  <= r_out_ctrl[i-1].stop;
        end

endmodule
