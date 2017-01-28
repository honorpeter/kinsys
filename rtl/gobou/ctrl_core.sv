`include "gobou/gobou.svh"
`include "common/ctrl_bus.sv"

module ctrl_core
  ( input                     clk
  , input                     xrst
  , ctrl_bus.in               in_ctrl
  , input                     req
  , input                     img_we
  , input [IMGSIZE-1:0]       input_addr
  , input [IMGSIZE-1:0]       output_addr
  , input signed [DWIDTH-1:0] write_img
  , input signed [DWIDTH-1:0] write_result
  , input [CORELOG:0]         net_we
  , input [NETSIZE-1:0]       net_addr
  , input [LWIDTH-1:0]        total_out
  , input [LWIDTH-1:0]        total_in
  , ctrl_bus.out                out_ctrl
  , output                      ack
  , output                      mem_img_we
  , output [IMGSIZE-1:0]        mem_img_addr
  , output signed [DWIDTH-1:0]  write_mem_img
  , output [CORE-1:0]           mem_net_we
  , output [NETSIZE-1:0]        mem_net_addr
  , output                      breg_we
  , output                      serial_we
  );

  enum {S_WAIT, S_WEIGHT, S_BIAS, S_OUTPUT} state;

  wire                s_weight_end;
  wire                s_bias_end;
  wire                s_output_end;
  wire                final_iter;
  wire [IMGSIZE-1:0]  w_img_addr;
  wire [IMGSIZE-1:0]  w_img_offset;

  reg [2-1:0]       r_state;
  ctrl_reg          r_out_ctrl;
  reg               r_ack;
  reg [LWIDTH-1:0]  r_total_out;
  reg [LWIDTH-1:0]  r_total_in;
  reg [LWIDTH-1:0]  r_count_out;
  reg [LWIDTH-1:0]  r_count_in;
  reg               r_img_we;
  reg [IMGSIZE-1:0] r_input_offset;
  reg [IMGSIZE-1:0] r_output_offset;
  reg [IMGSIZE-1:0] r_input_addr;
  reg [IMGSIZE-1:0] r_output_addr;
  reg [CORE-1:0]    r_net_we;
  reg [NETSIZE-1:0] r_net_addr;
  reg [NETSIZE-1:0] r_net_offset;
  reg               r_breg_we;
  reg               r_serial_we;
  reg [LWIDTH-1:0]  r_serial_cnt;

  assign final_iter = r_count_in == r_total_in - 1
                   && r_count_out + CORE >= r_total_out;

  always @(posedge clk)
    if (!xrst) begin
      r_state     <= S_WAIT;
      r_count_out <= 0;
      r_count_in  <= 0;
    end
    else
      case (r_state)
        S_WAIT:
          if (req)
            r_state <= S_WEIGHT;
        S_WEIGHT:
          if (s_weight_end) begin
            r_state     <= S_BIAS;
            r_count_in  <= 0;
          end
          else
            r_count_in <= r_count_in + 1;
        S_BIAS:
          if (s_bias_end)
            r_state <= S_OUTPUT;
        S_OUTPUT:
          if (s_output_end)
            if (r_count_out + CORE >= r_total_out) begin
              r_state     <= S_WAIT;
              r_count_out <= 0;
            end
            else begin
              r_state     <= S_WEIGHT;
              r_count_out <= r_count_out + CORE;
            end
        default:
          r_state <= S_WAIT;
      endcase

  always @(posedge clk)
    if (!xrst) begin
      r_total_in    <= 0;
      r_total_out   <= 0;
    end
    else if (r_state == S_WAIT && req) begin
      r_total_in    <= total_in;
      r_total_out   <= total_out;
    end

//==========================================================
// image control
//==========================================================

  assign mem_img_we = r_img_we;

  always @(posedge clk)
    if (!xrst)
      r_img_we <= 0;
    else
      case (r_state)
        S_WAIT:
          r_img_we <= img_we;
        S_OUTPUT:
          r_img_we <= r_serial_we
                   || (0 < r_serial_cnt && r_serial_cnt < CORE);
        default:
          r_img_we <= 0;
      endcase

  assign mem_img_addr = w_img_addr + w_img_offset;

  assign write_mem_img = r_state == S_OUTPUT
                       ? write_result
                       : write_img;

  assign w_img_addr = r_state == S_OUTPUT
                    ? r_output_addr
                    : r_input_addr;

  assign w_img_offset = r_state == S_OUTPUT
                      ? r_output_offset
                      : r_input_offset;

  always @(posedge clk)
    if (!xrst)
      r_input_addr <= 0;
    else if (r_state == S_BIAS)
      r_input_addr <= 0;
    else if (r_state == S_WEIGHT && !s_weight_end)
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
      r_input_offset <= input_addr;
      r_output_offset <= output_addr;
    end

//==========================================================
// network control
//==========================================================

  assign s_weight_end = r_state == S_WEIGHT && r_count_in == r_total_in - 1;
  assign s_bias_end   = r_state == S_BIAS;

  assign mem_net_we   = r_net_we;
  assign mem_net_addr = r_net_addr + r_net_offset;
  assign breg_we      = r_breg_we;

  for (genvar i = -1; i <= CORE+1; i++)
    if (i == -1) begin
      always @(posedge clk)
        if (!xrst)
          r_net_we <= 0;
    end
    else if (i == 0) begin
      always @(posedge clk)
        if (net_we == 0)
          r_net_we <= 0;
    end
    else if (0 < i && i < CORE+1) begin
      always @(posedge clk)
        if (net_we == i)
          r_net_we <= 2 ** (i-1);
    end
    else if (i == CORE+1) begin
      always @(posedge clk)
        if (net_we >= CORE+1)
          r_net_we <= 0;
    end

  always @(posedge clk)
    if (!xrst)
      r_net_addr <= 0;
    else if (final_iter)
      r_net_addr <= 0;
    else if (r_state == S_WEIGHT)
      r_net_addr <= r_net_addr + 1;
    else if (r_state == S_BIAS)
      r_net_addr <= r_net_addr + 1;

  always @(posedge clk)
    if (!xrst)
      r_net_offset <= 0;
    else if (req || ack)
      r_net_offset <= net_addr;

  always @(posedge clk)
    if (!xrst)
      r_breg_we <= 0;
    else
      r_breg_we <= r_state == S_BIAS;

//==========================================================
// output control
//==========================================================

  assign s_output_end = r_state == S_OUTPUT && r_serial_cnt == CORE;

  assign out_ctrl.start = r_out_ctrl.start;
  assign out_ctrl.valid = r_out_ctrl.valid;
  assign out_ctrl.stop  = r_out_ctrl.stop;

  always @(posedge clk)
    if (!xrst)
      r_out_ctrl <= {0, 0, 0};
    else begin
      r_out_ctrl.start <= req
                       || s_output_end && (r_count_out + CORE < r_total_out);
      r_out_ctrl.valid <= r_state == S_BIAS || r_state == S_WEIGHT;
      r_out_ctrl.stop  <= s_bias_end;
    end

  assign ack = r_ack;

  always @(posedge clk)
    if (!xrst)
      r_ack <= 1;
    else if (req)
      r_ack <= 0;
    else if (s_output_end && r_count_out + CORE >= r_total_out)
      r_ack <= 1;

  assign serial_we = r_serial_we;

  always @(posedge clk)
    if (!xrst)
      r_serial_we <= 0;
    else
      r_serial_we <= in_ctrl.start;

  always @(posedge clk)
    if (!xrst)
      r_serial_cnt <= 0;
    else if (serial_we)
      r_serial_cnt <= 1;
    else if (r_serial_cnt > 0)
      if (r_serial_cnt == CORE)
        r_serial_cnt <= 0;
      else
        r_serial_cnt <= r_serial_cnt + 1;

endmodule
