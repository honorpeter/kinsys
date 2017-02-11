`include "renkon.svh"
`include "mem_sp.sv"

module renkon
  ( input                     clk
  , input                     xrst
  , input                     req
  , input                     img_we
  , input [IMGSIZE-1:0]       input_addr
  , input [IMGSIZE-1:0]       output_addr
  , input signed [DWIDTH-1:0] write_img
  , input [CORELOG:0]         net_we
  , input [NETSIZE-1:0]       net_addr
  , input signed [DWIDTH-1:0] write_net
  , input [LWIDTH-1:0]        total_out
  , input [LWIDTH-1:0]        total_in
  , input [LWIDTH-1:0]        img_size
  , input [LWIDTH-1:0]        fil_size
  , input [LWIDTH-1:0]        pool_size
`ifdef DIST
  , input signed [DWIDTH-1:0] read_img
`endif
  , output                      ack
`ifdef DIST
  , output                      mem_img_we
  , output [IMGSIZE-1:0]        mem_img_addr
  , output signed [DWIDTH-1:0]  write_mem_img
`else
  , output signed [DWIDTH-1:0]  read_img
`endif
  );

  wire        [CORE-1:0]    mem_net_we;
  wire        [NETSIZE-1:0] mem_net_addr;
  wire signed [DWIDTH-1:0]  read_net [CORE-1:0];
  wire                      buf_pix_en;
  wire        [LWIDTH-1:0]  w_fea_size;
  wire        [LWIDTH-1:0]  w_fil_size;
  wire        [LWIDTH-1:0]  w_img_size;
  wire        [LWIDTH-1:0]  w_pool_size;
  wire signed [DWIDTH-1:0]  pixel [FSIZE**2-1:0];
  wire                      wreg_we;
  wire                      mem_feat_we;
  wire                      mem_feat_rst;
  wire        [FACCUM-1:0]  mem_feat_addr;
  wire        [FACCUM-1:0]  mem_feat_addr_d1;
  wire                      conv_oe;
  wire                      breg_we;
  wire                      bias_oe;
  wire                      relu_oe;
  wire                      buf_feat_en;
  wire                      pool_oe;
  wire                      serial_we;
  wire        [CORELOG:0]   serial_re;
  wire        [OUTSIZE-1:0] serial_addr;
  wire signed [DWIDTH-1:0]  pmap [CORE-1:0];
  wire signed [DWIDTH-1:0]  write_result;
`ifndef DIST
  wire                      mem_img_we;
  wire        [IMGSIZE-1:0] mem_img_addr;
  wire signed [DWIDTH-1:0]  write_mem_img;
`endif

  ctrl ctrl(.*);

`ifndef DIST
  mem_sp #(DWIDTH, IMGSIZE) mem_img(
    .read_data  (read_img),
    .write_data (write_mem_img),
    .mem_we     (mem_img_we),
    .mem_addr   (mem_img_addr),
    .*
  );
`endif

  linebuf #(FSIZE) buf_pix(
    .buf_en     (buf_pix_en),
    .buf_input  (read_img),
    .img_size   (w_img_size),
    .fil_size   (w_fil_size),
    .buf_output (pixel),
    .*
  );

  for (genvar i = 0; i < CORE; i++) begin : pe
    mem_sp #(DWIDTH, NETSIZE) mem_net(
      .read_data  (read_net[i]),
      .write_data (write_net),
      .mem_we     (mem_net_we[i]),
      .mem_addr   (mem_net_addr),
      .*
    );

    core core(
      .read_net     (read_net[i]),
      .pixel        (pixel),
      .pmap         (pmap[i]),
      .*
    );
  end : pe

  serial_mat serial(
    .in_data  (pmap),
    .out_data (write_result),
    .*
  );

endmodule
