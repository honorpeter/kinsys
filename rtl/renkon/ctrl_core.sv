`include "renkon.svh"
`include "ctrl_bus.svh"

module ctrl_core
  ( input                       clk
  , input                       xrst
  , input                       req
  , input                       in_begin
  , input                       in_valid
  , input                       in_end
  , input                       img_we
  , input         [IMGSIZE-1:0] input_addr
  , input         [IMGSIZE-1:0] output_addr
  , input  signed [DWIDTH-1:0]  write_img
  , input  signed [DWIDTH-1:0]  write_result
  , input         [CORELOG:0]   net_we
  , input         [NETSIZE-1:0] net_addr
  , input         [LWIDTH-1:0]  total_out
  , input         [LWIDTH-1:0]  total_in
  , input         [LWIDTH-1:0]  img_size
  , input         [LWIDTH-1:0]  fil_size
  , output                      ack
  , output        [2-1:0]       core_state
  , output                      out_begin
  , output                      out_valid
  , output                      out_end
  , output                      mem_img_we
  , output        [IMGSIZE-1:0] mem_img_addr
  , output signed [DWIDTH-1:0]  write_mem_img
  , output        [CORE-1:0]    mem_net_we
  , output        [NETSIZE-1:0] mem_net_addr
  , output                      buf_pix_en
  , output                      first_input
  , output                      last_input
  , output                      wreg_we
  , output                      breg_we
  , output                      serial_we
  , output        [CORELOG:0]   serial_re
  , output        [OUTSIZE-1:0] serial_addr
  , output        [LWIDTH-1:0]  w_img_size
  , output        [LWIDTH-1:0]  w_fil_size
  );

  wire                s_network_end;
  wire                s_input_end;
  wire                s_output_end;
  wire                s_w_weight_end;
  wire                s_w_bias_end;
  wire                final_iter;
  wire [IMGSIZE-1:0]  w_img_addr;
  wire [IMGSIZE-1:0]  w_img_offset;

  reg [2-1:0]       r_state;
  reg               r_state_weight;
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
  reg [IMGSIZE-1:0] r_output_offset;
  reg [IMGSIZE-1:0] r_input_addr;
  reg [IMGSIZE-1:0] r_output_addr;
  reg [CORE-1:0]    r_net_we;
  reg [NETSIZE-1:0] r_net_addr;
  reg [NETSIZE-1:0] r_net_offset;
  reg               r_serial_we;
  reg [CORELOG:0]   r_serial_re;
  reg [LWIDTH-1:0]  r_serial_cnt;
  reg [OUTSIZE-1:0] r_serial_addr;
  reg               r_serial_end;
  reg               r_output_end;
  reg [2-1:0]       r_state_d         [D_PIXELBUF:0];
  reg               r_state_weight_d  [D_PIXELBUF:0];
  reg               r_wreg_we_d       [D_PIXELBUF-1:0];
  reg               r_first_input_d   [D_PIXELBUF-1:0];
  reg               r_last_input_d    [D_PIXELBUF-1:0];
  reg               r_out_begin_d     [D_PIXELBUF-1:0];
  reg               r_out_valid_d     [D_PIXELBUF-1:0];
  reg               r_out_end_d       [D_PIXELBUF-1:0];

endmodule
