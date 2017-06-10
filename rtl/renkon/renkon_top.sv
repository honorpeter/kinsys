`include "renkon.svh"

module renkon_top
  ( input                       clk
  , input                       xrst
  , input                       req
  , input  [RENKON_CORELOG-1:0] net_sel
  , input                       net_we
  , input  [RENKON_NETSIZE-1:0] net_addr
  , input  signed [DWIDTH-1:0]  net_wdata
  , input  [IMGSIZE-1:0]        in_offset
  , input  [IMGSIZE-1:0]        out_offset
  , input  [RENKON_NETSIZE-1:0] net_offset
  , input  [LWIDTH-1:0]         total_out
  , input  [LWIDTH-1:0]         total_in
  , input  [LWIDTH-1:0]         img_size
  , input  [LWIDTH-1:0]         fil_size
  , input  [LWIDTH-1:0]         pool_size
  , input  signed [DWIDTH-1:0]  img_rdata
  , output                      ack
  , output                      img_we
  , output [IMGSIZE-1:0]        img_addr
  , output signed [DWIDTH-1:0]  img_wdata
  );

  wire [RENKON_CORE-1:0]    mem_net_we;
  wire [RENKON_NETSIZE-1:0] mem_net_addr;
  wire signed [DWIDTH-1:0]  net_rdata [RENKON_CORE-1:0];
  wire                      buf_pix_en;
  wire [LWIDTH-1:0]         w_fea_size;
  wire [LWIDTH-1:0]         w_fil_size;
  wire [LWIDTH-1:0]         w_img_size;
  wire [LWIDTH-1:0]         w_pool_size;
  wire signed [DWIDTH-1:0]  pixel [FSIZE**2-1:0];
  wire                      wreg_we;
  wire                      mem_feat_we;
  wire                      mem_feat_rst;
  wire [FACCUM-1:0]         mem_feat_addr;
  wire [FACCUM-1:0]         mem_feat_addr_d1;
  wire                      conv_oe;
  wire                      breg_we;
  wire                      bias_oe;
  wire                      relu_oe;
  wire                      buf_feat_en;
  wire                      pool_oe;
  wire                      serial_we;
  wire [RENKON_CORELOG:0]   serial_re;
  wire [OUTSIZE-1:0]        serial_addr;
  wire signed [DWIDTH-1:0]  result [RENKON_CORE-1:0];
  wire signed [DWIDTH-1:0]  out_wdata;

  renkon_ctrl ctrl(.*);

  renkon_linebuf #(FSIZE, D_PIXELBUF) buf_pix(
    .buf_en     (buf_pix_en),
    .buf_input  (img_rdata),
    .img_size   (w_img_size),
    .fil_size   (w_fil_size),
    .buf_output (pixel),
    .*
  );

  for (genvar i = 0; i < RENKON_CORE; i++) begin : pe
    mem_sp #(DWIDTH, RENKON_NETSIZE) mem_net(
      .mem_we     (mem_net_we[i]),
      .mem_addr   (mem_net_addr),
      .mem_wdata  (net_wdata),
      .mem_rdata  (net_rdata[i]),
      .*
    );

    renkon_core core(
      .net_rdata    (net_rdata[i]),
      .pixel        (pixel),
      .pmap         (result[i]),
      .*
    );
  end : pe

  renkon_serial_mat serial(
    .in_data  (result),
    .out_data (out_wdata),
    .*
  );

endmodule
