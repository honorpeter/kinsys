`include "ninjin.svh"
`include "renkon.svh"
`include "gobou.svh"

module kinpira
  // Parameters of Axi Slave Bus Interface s_axi_params
 #( parameter C_s_axi_params_DATA_WIDTH = BWIDTH
  , parameter C_s_axi_params_ADDR_WIDTH = REGSIZE + LSB

  // Parameters of Axi Master Bus Interface m_axi_image
  , parameter C_m_axi_image_BURST_MAX     = BURST_MAX
  , parameter C_m_axi_image_ID_WIDTH      = 1
  , parameter C_m_axi_image_DATA_WIDTH    = BWIDTH
  , parameter C_m_axi_image_ADDR_WIDTH    = WORDSIZE + LSB
  , parameter C_m_axi_image_AWUSER_WIDTH  = 0
  , parameter C_m_axi_image_ARUSER_WIDTH  = 0
  , parameter C_m_axi_image_WUSER_WIDTH   = 0
  , parameter C_m_axi_image_RUSER_WIDTH   = 0
  , parameter C_m_axi_image_BUSER_WIDTH   = 0

  // Parameters of Axi Slave Bus Interface s_axi_renkon
  , parameter C_s_axi_renkon_ID_WIDTH     = 12
  , parameter C_s_axi_renkon_DATA_WIDTH   = BWIDTH
  , parameter C_s_axi_renkon_ADDR_WIDTH   = RENKON_CORELOG + RENKON_NETSIZE + LSB
  , parameter C_s_axi_renkon_AWUSER_WIDTH = 0
  , parameter C_s_axi_renkon_ARUSER_WIDTH = 0
  , parameter C_s_axi_renkon_WUSER_WIDTH  = 0
  , parameter C_s_axi_renkon_RUSER_WIDTH  = 0
  , parameter C_s_axi_renkon_BUSER_WIDTH  = 0

  // Parameters of Axi Slave Bus Interface s_axi_gobou
  , parameter C_s_axi_gobou_ID_WIDTH      = 12
  , parameter C_s_axi_gobou_DATA_WIDTH    = BWIDTH
  , parameter C_s_axi_gobou_ADDR_WIDTH    = GOBOU_CORELOG + GOBOU_NETSIZE + LSB
  , parameter C_s_axi_gobou_AWUSER_WIDTH  = 0
  , parameter C_s_axi_gobou_ARUSER_WIDTH  = 0
  , parameter C_s_axi_gobou_WUSER_WIDTH   = 0
  , parameter C_s_axi_gobou_RUSER_WIDTH   = 0
  , parameter C_s_axi_gobou_BUSER_WIDTH   = 0
  )
  // Ports of Axi Slave Bus Interface s_axi_params
  ( input                                     s_axi_params_aclk
  , input                                     s_axi_params_aresetn
  , input  [C_s_axi_params_ADDR_WIDTH-1:0]    s_axi_params_awaddr
  , input  [2:0]                              s_axi_params_awprot
  , input                                     s_axi_params_awvalid
  , output                                    s_axi_params_awready
  , input  [C_s_axi_params_DATA_WIDTH-1:0]    s_axi_params_wdata
  , input  [C_s_axi_params_DATA_WIDTH/8-1:0]  s_axi_params_wstrb
  , input                                     s_axi_params_wvalid
  , output                                    s_axi_params_wready
  , output [1:0]                              s_axi_params_bresp
  , output                                    s_axi_params_bvalid
  , input                                     s_axi_params_bready
  , input  [C_s_axi_params_ADDR_WIDTH-1:0]    s_axi_params_araddr
  , input  [2:0]                              s_axi_params_arprot
  , input                                     s_axi_params_arvalid
  , output                                    s_axi_params_arready
  , output [C_s_axi_params_DATA_WIDTH-1:0]    s_axi_params_rdata
  , output [1:0]                              s_axi_params_rresp
  , output                                    s_axi_params_rvalid
  , input                                     s_axi_params_rready

  // Ports of Axi Master Bus Interface m_axi_image
  , input                                   m_axi_image_aclk
  , input                                   m_axi_image_aresetn
  , output [C_m_axi_image_ID_WIDTH-1:0]     m_axi_image_awid
  , output [C_m_axi_image_ADDR_WIDTH-1:0]   m_axi_image_awaddr
  , output [7:0]                            m_axi_image_awlen
  , output [2:0]                            m_axi_image_awsize
  , output [1:0]                            m_axi_image_awburst
  , output                                  m_axi_image_awlock
  , output [3:0]                            m_axi_image_awcache
  , output [2:0]                            m_axi_image_awprot
  , output [3:0]                            m_axi_image_awqos
  , output [C_m_axi_image_AWUSER_WIDTH-1:0] m_axi_image_awuser
  , output                                  m_axi_image_awvalid
  , input                                   m_axi_image_awready
  , output [C_m_axi_image_DATA_WIDTH-1:0]   m_axi_image_wdata
  , output [C_m_axi_image_DATA_WIDTH/8-1:0] m_axi_image_wstrb
  , output                                  m_axi_image_wlast
  , output [C_m_axi_image_WUSER_WIDTH-1:0]  m_axi_image_wuser
  , output                                  m_axi_image_wvalid
  , input                                   m_axi_image_wready
  , input  [C_m_axi_image_ID_WIDTH-1:0]     m_axi_image_bid
  , input  [1:0]                            m_axi_image_bresp
  , input  [C_m_axi_image_BUSER_WIDTH-1:0]  m_axi_image_buser
  , input                                   m_axi_image_bvalid
  , output                                  m_axi_image_bready
  , output [C_m_axi_image_ID_WIDTH-1:0]     m_axi_image_arid
  , output [C_m_axi_image_ADDR_WIDTH-1:0]   m_axi_image_araddr
  , output [7:0]                            m_axi_image_arlen
  , output [2:0]                            m_axi_image_arsize
  , output [1:0]                            m_axi_image_arburst
  , output                                  m_axi_image_arlock
  , output [3:0]                            m_axi_image_arcache
  , output [2:0]                            m_axi_image_arprot
  , output [3:0]                            m_axi_image_arqos
  , output [C_m_axi_image_ARUSER_WIDTH-1:0] m_axi_image_aruser
  , output                                  m_axi_image_arvalid
  , input                                   m_axi_image_arready
  , input  [C_m_axi_image_ID_WIDTH-1:0]     m_axi_image_rid
  , input  [C_m_axi_image_DATA_WIDTH-1:0]   m_axi_image_rdata
  , input  [1:0]                            m_axi_image_rresp
  , input                                   m_axi_image_rlast
  , input  [C_m_axi_image_RUSER_WIDTH-1:0]  m_axi_image_ruser
  , input                                   m_axi_image_rvalid
  , output                                  m_axi_image_rready

  // Ports of Axi Slave Bus Interface s_axi_renkon
  , input                                     s_axi_renkon_aclk
  , input                                     s_axi_renkon_aresetn
  , input  [C_s_axi_renkon_ID_WIDTH-1:0]      s_axi_renkon_awid
  , input  [C_s_axi_renkon_ADDR_WIDTH-1:0]    s_axi_renkon_awaddr
  , input  [7:0]                              s_axi_renkon_awlen
  , input  [2:0]                              s_axi_renkon_awsize
  , input  [1:0]                              s_axi_renkon_awburst
  , input                                     s_axi_renkon_awlock
  , input  [3:0]                              s_axi_renkon_awcache
  , input  [2:0]                              s_axi_renkon_awprot
  , input  [3:0]                              s_axi_renkon_awqos
  , input  [3:0]                              s_axi_renkon_awregion
  , input  [C_s_axi_renkon_AWUSER_WIDTH-1:0]  s_axi_renkon_awuser
  , input                                     s_axi_renkon_awvalid
  , output                                    s_axi_renkon_awready
  , input  [C_s_axi_renkon_DATA_WIDTH-1:0]    s_axi_renkon_wdata
  , input  [C_s_axi_renkon_DATA_WIDTH/8-1:0]  s_axi_renkon_wstrb
  , input                                     s_axi_renkon_wlast
  , input  [C_s_axi_renkon_WUSER_WIDTH-1:0]   s_axi_renkon_wuser
  , input                                     s_axi_renkon_wvalid
  , output                                    s_axi_renkon_wready
  , output [C_s_axi_renkon_ID_WIDTH-1:0]      s_axi_renkon_bid
  , output [1:0]                              s_axi_renkon_bresp
  , output [C_s_axi_renkon_BUSER_WIDTH-1:0]   s_axi_renkon_buser
  , output                                    s_axi_renkon_bvalid
  , input                                     s_axi_renkon_bready
  , input  [C_s_axi_renkon_ID_WIDTH-1:0]      s_axi_renkon_arid
  , input  [C_s_axi_renkon_ADDR_WIDTH-1:0]    s_axi_renkon_araddr
  , input  [7:0]                              s_axi_renkon_arlen
  , input  [2:0]                              s_axi_renkon_arsize
  , input  [1:0]                              s_axi_renkon_arburst
  , input                                     s_axi_renkon_arlock
  , input  [3:0]                              s_axi_renkon_arcache
  , input  [2:0]                              s_axi_renkon_arprot
  , input  [3:0]                              s_axi_renkon_arqos
  , input  [3:0]                              s_axi_renkon_arregion
  , input  [C_s_axi_renkon_ARUSER_WIDTH-1:0]  s_axi_renkon_aruser
  , input                                     s_axi_renkon_arvalid
  , output                                    s_axi_renkon_arready
  , output [C_s_axi_renkon_ID_WIDTH-1:0]      s_axi_renkon_rid
  , output [C_s_axi_renkon_DATA_WIDTH-1:0]    s_axi_renkon_rdata
  , output [1:0]                              s_axi_renkon_rresp
  , output                                    s_axi_renkon_rlast
  , output [C_s_axi_renkon_RUSER_WIDTH-1:0]   s_axi_renkon_ruser
  , output                                    s_axi_renkon_rvalid
  , input                                     s_axi_renkon_rready

  // Ports of Axi Slave Bus Interface s_axi_gobou
  , input                                   s_axi_gobou_aclk
  , input                                   s_axi_gobou_aresetn
  , input  [C_s_axi_gobou_ID_WIDTH-1:0]     s_axi_gobou_awid
  , input  [C_s_axi_gobou_ADDR_WIDTH-1:0]   s_axi_gobou_awaddr
  , input  [7:0]                            s_axi_gobou_awlen
  , input  [2:0]                            s_axi_gobou_awsize
  , input  [1:0]                            s_axi_gobou_awburst
  , input                                   s_axi_gobou_awlock
  , input  [3:0]                            s_axi_gobou_awcache
  , input  [2:0]                            s_axi_gobou_awprot
  , input  [3:0]                            s_axi_gobou_awqos
  , input  [3:0]                            s_axi_gobou_awregion
  , input  [C_s_axi_gobou_AWUSER_WIDTH-1:0] s_axi_gobou_awuser
  , input                                   s_axi_gobou_awvalid
  , output                                  s_axi_gobou_awready
  , input  [C_s_axi_gobou_DATA_WIDTH-1:0]   s_axi_gobou_wdata
  , input  [C_s_axi_gobou_DATA_WIDTH/8-1:0] s_axi_gobou_wstrb
  , input                                   s_axi_gobou_wlast
  , input  [C_s_axi_gobou_WUSER_WIDTH-1:0]  s_axi_gobou_wuser
  , input                                   s_axi_gobou_wvalid
  , output                                  s_axi_gobou_wready
  , output [C_s_axi_gobou_ID_WIDTH-1:0]     s_axi_gobou_bid
  , output [1:0]                            s_axi_gobou_bresp
  , output [C_s_axi_gobou_BUSER_WIDTH-1:0]  s_axi_gobou_buser
  , output                                  s_axi_gobou_bvalid
  , input                                   s_axi_gobou_bready
  , input  [C_s_axi_gobou_ID_WIDTH-1:0]     s_axi_gobou_arid
  , input  [C_s_axi_gobou_ADDR_WIDTH-1:0]   s_axi_gobou_araddr
  , input  [7:0]                            s_axi_gobou_arlen
  , input  [2:0]                            s_axi_gobou_arsize
  , input  [1:0]                            s_axi_gobou_arburst
  , input                                   s_axi_gobou_arlock
  , input  [3:0]                            s_axi_gobou_arcache
  , input  [2:0]                            s_axi_gobou_arprot
  , input  [3:0]                            s_axi_gobou_arqos
  , input  [3:0]                            s_axi_gobou_arregion
  , input  [C_s_axi_gobou_ARUSER_WIDTH-1:0] s_axi_gobou_aruser
  , input                                   s_axi_gobou_arvalid
  , output                                  s_axi_gobou_arready
  , output [C_s_axi_gobou_ID_WIDTH-1:0]     s_axi_gobou_rid
  , output [C_s_axi_gobou_DATA_WIDTH-1:0]   s_axi_gobou_rdata
  , output [1:0]                            s_axi_gobou_rresp
  , output                                  s_axi_gobou_rlast
  , output [C_s_axi_gobou_RUSER_WIDTH-1:0]  s_axi_gobou_ruser
  , output                                  s_axi_gobou_rvalid
  , input                                   s_axi_gobou_rready
  );

//==========================================================
// definitions
//==========================================================
// {{{

  wire                      clk;
  wire                      xrst;

  wire [C_s_axi_params_DATA_WIDTH-1:0]  in_port [PORT/2-1:0];
  wire [C_s_axi_params_DATA_WIDTH-1:0]  out_port [PORT-1:PORT/2];

  wire                                    mem_gobou_we;
  wire [C_s_axi_gobou_ADDR_WIDTH-LSB-1:0] mem_gobou_addr;
  wire [C_s_axi_gobou_DATA_WIDTH-1:0]     mem_gobou_wdata;
  wire [C_s_axi_gobou_DATA_WIDTH-1:0]     mem_gobou_rdata;

  wire                                      mem_renkon_we;
  wire [C_s_axi_renkon_ADDR_WIDTH-LSB-1:0]  mem_renkon_addr;
  wire [C_s_axi_renkon_DATA_WIDTH-1:0]      mem_renkon_wdata;
  wire [C_s_axi_renkon_DATA_WIDTH-1:0]      mem_renkon_rdata;

  // For ninjin
  wire                      which;
  wire                      req;
  wire [LWIDTH-1:0]         qbits;
  wire [MEMSIZE-1:0]        in_offset;
  wire [MEMSIZE-1:0]        out_offset;
  wire [BWIDTH-1:0]         net_offset;

  wire [BWIDTH-1:0]         base_param [2:0];
  wire [BWIDTH-1:0]         conv_param [1:0];
  wire [BWIDTH-1:0]         bias_param;
  wire [BWIDTH-1:0]         actv_param;
  wire [BWIDTH-1:0]         pool_param [1:0];

  wire [LWIDTH-1:0]         total_out;
  wire [LWIDTH-1:0]         total_in;
  wire [LWIDTH-1:0]         img_height;
  wire [LWIDTH-1:0]         img_width;
  wire [LWIDTH-1:0]         fea_height;
  wire [LWIDTH-1:0]         fea_width;
  wire [LWIDTH-1:0]         conv_kern;
  wire [LWIDTH-1:0]         conv_strid;
  wire [LWIDTH-1:0]         conv_pad;
  wire                      bias_en;
  wire                      relu_en;
  wire                      pool_en;
  wire [LWIDTH-1:0]         pool_kern;
  wire [LWIDTH-1:0]         pool_strid;
  wire [LWIDTH-1:0]         pool_pad;

  wire                      ack;
  // mem_img ports
  wire                      mem_img_we;
  wire [MEMSIZE-1:0]        mem_img_addr;
  wire signed [DWIDTH-1:0]  mem_img_wdata;
  wire signed [DWIDTH-1:0]  mem_img_rdata;
  // meta inputs
  wire                      pre_req;
  wire [WORDSIZE-1:0]       pre_base;
  wire [LWIDTH-1:0]         read_len;
  wire [LWIDTH-1:0]         write_len;
  // m_axi ports (fed back)
  wire                      ddr_we;
  wire [WORDSIZE-1:0]       ddr_waddr;
  wire [BWIDTH-1:0]         ddr_wdata;
  wire [WORDSIZE-1:0]       ddr_raddr;
  // meta outputs
  wire                      pre_ack;
  // m_axi signals
  wire                      ddr_req;
  wire                      ddr_mode;
  wire [WORDSIZE+LSB-1:0]   ddr_base;
  wire [LWIDTH-1:0]         ddr_len;
  wire [BWIDTH-1:0]         ddr_rdata;

  // For renkon
  wire                      renkon_req;
  wire [LWIDTH-1:0]         renkon_qbits;
  wire signed [DWIDTH-1:0]  renkon_img_rdata;
  wire [RENKON_CORELOG-1:0] renkon_net_sel;
  wire                      renkon_net_we;
  wire [RENKON_NETSIZE-1:0] renkon_net_addr;
  wire signed [DWIDTH-1:0]  renkon_net_wdata;
  wire [MEMSIZE-1:0]        renkon_in_offset;
  wire [MEMSIZE-1:0]        renkon_out_offset;
  wire [RENKON_NETSIZE-1:0] renkon_net_offset;
  wire [LWIDTH-1:0]         renkon_total_out;
  wire [LWIDTH-1:0]         renkon_total_in;
  wire [LWIDTH-1:0]         renkon_img_height;
  wire [LWIDTH-1:0]         renkon_img_width;
  wire [LWIDTH-1:0]         renkon_fea_height;
  wire [LWIDTH-1:0]         renkon_fea_width;
  wire [LWIDTH-1:0]         renkon_conv_kern;
  wire [LWIDTH-1:0]         renkon_conv_strid;
  wire [LWIDTH-1:0]         renkon_conv_pad;
  wire                      renkon_bias_en;
  wire                      renkon_relu_en;
  wire                      renkon_pool_en;
  wire [LWIDTH-1:0]         renkon_pool_kern;
  wire [LWIDTH-1:0]         renkon_pool_strid;
  wire [LWIDTH-1:0]         renkon_pool_pad;

  wire                      renkon_ack;
  wire                      renkon_img_we;
  wire [MEMSIZE-1:0]        renkon_img_addr;
  wire signed [DWIDTH-1:0]  renkon_img_wdata;

  // For gobou
  wire                      gobou_req;
  wire [LWIDTH-1:0]         gobou_qbits;
  wire signed [DWIDTH-1:0]  gobou_img_rdata;
  wire [GOBOU_CORELOG-1:0]  gobou_net_sel;
  wire                      gobou_net_we;
  wire [GOBOU_NETSIZE-1:0]  gobou_net_addr;
  wire signed [DWIDTH-1:0]  gobou_net_wdata;
  wire [MEMSIZE-1:0]        gobou_in_offset;
  wire [MEMSIZE-1:0]        gobou_out_offset;
  wire [GOBOU_NETSIZE-1:0]  gobou_net_offset;
  wire [LWIDTH-1:0]         gobou_total_out;
  wire [LWIDTH-1:0]         gobou_total_in;
  wire                      gobou_bias_en;
  wire                      gobou_relu_en;

  wire                      gobou_ack;
  wire                      gobou_img_we;
  wire [MEMSIZE-1:0]        gobou_img_addr;
  wire signed [DWIDTH-1:0]  gobou_img_wdata;

  reg which$;
  wire [3:0] err;


// }}}
//==========================================================
// assignments
//==========================================================
// {{{

  assign clk        = s_axi_params_aclk;
  assign xrst       = s_axi_params_aresetn;
  assign which      = in_port[0][0];
  assign req        = in_port[1][0];
  assign qbits      = in_port[2][LWIDTH-1:0];
  assign in_offset  = in_port[3][MEMSIZE-1+RATELOG:RATELOG];
  assign out_offset = in_port[4][MEMSIZE-1+RATELOG:RATELOG];
  assign net_offset = in_port[5][BWIDTH-1:0];
  assign pre_req    = in_port[6][0];
  assign pre_base   = in_port[7][WORDSIZE-1+LSB:LSB];
  assign read_len   = in_port[8][LWIDTH-1:0];
  assign write_len  = in_port[9][LWIDTH-1:0];

  assign base_param[0] = in_port[10][BWIDTH-1:0];
  assign base_param[1] = in_port[11][BWIDTH-1:0];
  assign base_param[2] = in_port[12][BWIDTH-1:0];
  assign conv_param[0] = in_port[13][BWIDTH-1:0];
  assign conv_param[1] = in_port[14][BWIDTH-1:0];
  assign bias_param    = in_port[15][BWIDTH-1:0];
  assign actv_param    = in_port[16][BWIDTH-1:0];
  assign pool_param[0] = in_port[17][BWIDTH-1:0];
  assign pool_param[1] = in_port[18][BWIDTH-1:0];

  // Network parameters
  assign total_out  = base_param[0][2*LWIDTH-1:LWIDTH];
  assign total_in   = base_param[0][LWIDTH-1:0];
  assign img_height = base_param[1][2*LWIDTH-1:LWIDTH];
  assign img_width  = base_param[1][LWIDTH-1:0];
  assign fea_height = base_param[2][2*LWIDTH-1:LWIDTH];
  assign fea_width  = base_param[2][LWIDTH-1:0];

  assign conv_kern  = conv_param[0][LWIDTH-1:0];
  assign conv_strid = conv_param[1][2*LWIDTH-1:LWIDTH];
  assign conv_pad   = conv_param[1][LWIDTH-1:0];

  assign bias_en    = bias_param[BWIDTH-1];

  assign relu_en    = actv_param[BWIDTH-1];

  assign pool_en    = pool_param[0][BWIDTH-1];
  assign pool_kern  = pool_param[0][LWIDTH-1:0];
  assign pool_strid = pool_param[1][2*LWIDTH-1:LWIDTH];
  assign pool_pad   = pool_param[1][LWIDTH-1:0];



  assign out_port[63] = {31'b0, which$};
  assign out_port[62] = {31'b0, ack};
  assign out_port[61] = {31'd0, pre_ack};
  assign out_port[60] = {28'd0, err};
  assign out_port[59] = 32'd0;
  assign out_port[58] = 32'b0;
  assign out_port[57] = 32'd0;
  assign out_port[56] = 32'd0;
  assign out_port[55] = 32'd0;
  assign out_port[54] = 32'd0;
  assign out_port[53] = 32'd0;
  assign out_port[52] = 32'd0;
  assign out_port[51] = 32'd0;
  assign out_port[50] = 32'd0;
  assign out_port[49] = 32'd0;
  assign out_port[48] = 32'd0;
  assign out_port[47] = 32'd0;
  assign out_port[46] = 32'd0;
  assign out_port[45] = 32'd0;
  assign out_port[44] = 32'd0;
  assign out_port[43] = 32'd0;
  assign out_port[42] = 32'b0;
  assign out_port[41] = 32'd0;
  assign out_port[40] = 32'd0;
  assign out_port[39] = 32'd0;
  assign out_port[38] = 32'd0;
  assign out_port[37] = 32'd0;
  assign out_port[36] = 32'd0;
  assign out_port[35] = 32'd0;
  assign out_port[34] = 32'd0;
  assign out_port[33] = 32'd0;
  assign out_port[32] = 32'd0;



  // For ninjin
  assign ack            = which == WHICH_RENKON ? renkon_ack
                        : which == WHICH_GOBOU  ? gobou_ack
                        : 0;
  assign mem_img_we     = which == WHICH_RENKON ? renkon_img_we
                        : which == WHICH_GOBOU  ? gobou_img_we
                        : 0;
  assign mem_img_addr   = which == WHICH_RENKON ? renkon_img_addr
                        : which == WHICH_GOBOU  ? gobou_img_addr
                        : 0;
  assign mem_img_wdata  = which == WHICH_RENKON ? renkon_img_wdata
                        : which == WHICH_GOBOU  ? gobou_img_wdata
                        : 0;



  // For renkon
  assign renkon_net_sel   = mem_renkon_addr[RENKON_NETSIZE+RENKON_CORELOG-1:RENKON_NETSIZE];
  assign renkon_net_we    = mem_renkon_we;
  assign renkon_net_addr  = mem_renkon_addr[RENKON_NETSIZE-1:0];
  assign renkon_net_wdata = mem_renkon_wdata[DWIDTH-1:0];

  assign renkon_img_rdata  = which == WHICH_RENKON ? mem_img_rdata : 0;

  assign renkon_req        = which == WHICH_RENKON ? req : 0;
  assign renkon_qbits      = which == WHICH_RENKON ? qbits : 0;
  assign renkon_in_offset  = which == WHICH_RENKON ? in_offset : 0;
  assign renkon_out_offset = which == WHICH_RENKON ? out_offset : 0;
  assign renkon_net_offset = which == WHICH_RENKON ? net_offset[RENKON_NETSIZE-1:0] : 0;
  assign renkon_total_out  = which == WHICH_RENKON ? total_out : 0;
  assign renkon_total_in   = which == WHICH_RENKON ? total_in : 0;
  assign renkon_img_height = which == WHICH_RENKON ? img_height : 0;
  assign renkon_img_width  = which == WHICH_RENKON ? img_width : 0;
  assign renkon_fea_height = which == WHICH_RENKON ? fea_height : 0;
  assign renkon_fea_width  = which == WHICH_RENKON ? fea_width : 0;
  assign renkon_conv_kern  = which == WHICH_RENKON ? conv_kern : 0;
  assign renkon_conv_strid = which == WHICH_RENKON ? conv_strid : 0;
  assign renkon_conv_pad   = which == WHICH_RENKON ? conv_pad : 0;
  assign renkon_bias_en    = which == WHICH_RENKON ? bias_en : 0;
  assign renkon_relu_en    = which == WHICH_RENKON ? relu_en : 0;
  assign renkon_pool_en    = which == WHICH_RENKON ? pool_en : 0;
  assign renkon_pool_kern  = which == WHICH_RENKON ? pool_kern : 0;
  assign renkon_pool_strid = which == WHICH_RENKON ? pool_strid : 0;
  assign renkon_pool_pad   = which == WHICH_RENKON ? pool_pad : 0;



  // For gobou
  assign gobou_net_sel    = mem_gobou_addr[GOBOU_NETSIZE+GOBOU_CORELOG-1:GOBOU_NETSIZE];
  assign gobou_net_we     = mem_gobou_we;
  assign gobou_net_addr   = mem_gobou_addr[GOBOU_NETSIZE-1:0];
  assign gobou_net_wdata  = mem_gobou_wdata[DWIDTH-1:0];

  assign gobou_img_rdata   = which == WHICH_GOBOU ? mem_img_rdata : 0;

  assign gobou_req         = which == WHICH_GOBOU ? req : 0;
  assign gobou_qbits       = which == WHICH_GOBOU ? qbits : 0;
  assign gobou_in_offset   = which == WHICH_GOBOU ? in_offset : 0;
  assign gobou_out_offset  = which == WHICH_GOBOU ? out_offset : 0;
  assign gobou_net_offset  = which == WHICH_GOBOU ? net_offset[GOBOU_NETSIZE-1:0] : 0;
  assign gobou_total_out   = which == WHICH_GOBOU ? total_out : 0;
  assign gobou_total_in    = which == WHICH_GOBOU ? total_in : 0;
  assign gobou_bias_en     = which == WHICH_GOBOU ? bias_en : 0;
  assign gobou_relu_en     = which == WHICH_GOBOU ? relu_en : 0;



  always @(posedge clk)
    if (!xrst)
      which$ <= 0;
    else
      which$ <= which;


// }}}
//==========================================================
// axi interfaces
//==========================================================
// {{{

  ninjin_s_axi_params #(
    .DATA_WIDTH (C_s_axi_params_DATA_WIDTH),
    .ADDR_WIDTH (C_s_axi_params_ADDR_WIDTH)
  ) ninjin_s_axi_params_inst(
    .clk      (s_axi_params_aclk),
    .xrst     (s_axi_params_aresetn),
    .awaddr   (s_axi_params_awaddr),
    .awprot   (s_axi_params_awprot),
    .awvalid  (s_axi_params_awvalid),
    .awready  (s_axi_params_awready),
    .wdata    (s_axi_params_wdata),
    .wstrb    (s_axi_params_wstrb),
    .wvalid   (s_axi_params_wvalid),
    .wready   (s_axi_params_wready),
    .bresp    (s_axi_params_bresp),
    .bvalid   (s_axi_params_bvalid),
    .bready   (s_axi_params_bready),
    .araddr   (s_axi_params_araddr),
    .arprot   (s_axi_params_arprot),
    .arvalid  (s_axi_params_arvalid),
    .arready  (s_axi_params_arready),
    .rdata    (s_axi_params_rdata),
    .rresp    (s_axi_params_rresp),
    .rvalid   (s_axi_params_rvalid),
    .rready   (s_axi_params_rready),
    .*
  );

  ninjin_m_axi_image #(
    .BURST_MAX    (C_m_axi_image_BURST_MAX),
    .ID_WIDTH     (C_m_axi_image_ID_WIDTH),
    .ADDR_WIDTH   (C_m_axi_image_ADDR_WIDTH),
    .DATA_WIDTH   (C_m_axi_image_DATA_WIDTH),
    .AWUSER_WIDTH (C_m_axi_image_AWUSER_WIDTH),
    .ARUSER_WIDTH (C_m_axi_image_ARUSER_WIDTH),
    .WUSER_WIDTH  (C_m_axi_image_WUSER_WIDTH),
    .RUSER_WIDTH  (C_m_axi_image_RUSER_WIDTH),
    .BUSER_WIDTH  (C_m_axi_image_BUSER_WIDTH)
  ) ninjin_m_axi_image_inst(
    .clk      (m_axi_image_aclk),
    .xrst     (m_axi_image_aresetn),
    .awid     (m_axi_image_awid),
    .awaddr   (m_axi_image_awaddr),
    .awlen    (m_axi_image_awlen),
    .awsize   (m_axi_image_awsize),
    .awburst  (m_axi_image_awburst),
    .awlock   (m_axi_image_awlock),
    .awcache  (m_axi_image_awcache),
    .awprot   (m_axi_image_awprot),
    .awqos    (m_axi_image_awqos),
    .awuser   (m_axi_image_awuser),
    .awvalid  (m_axi_image_awvalid),
    .awready  (m_axi_image_awready),
    .wdata    (m_axi_image_wdata),
    .wstrb    (m_axi_image_wstrb),
    .wlast    (m_axi_image_wlast),
    .wuser    (m_axi_image_wuser),
    .wvalid   (m_axi_image_wvalid),
    .wready   (m_axi_image_wready),
    .bid      (m_axi_image_bid),
    .bresp    (m_axi_image_bresp),
    .buser    (m_axi_image_buser),
    .bvalid   (m_axi_image_bvalid),
    .bready   (m_axi_image_bready),
    .arid     (m_axi_image_arid),
    .araddr   (m_axi_image_araddr),
    .arlen    (m_axi_image_arlen),
    .arsize   (m_axi_image_arsize),
    .arburst  (m_axi_image_arburst),
    .arlock   (m_axi_image_arlock),
    .arcache  (m_axi_image_arcache),
    .arprot   (m_axi_image_arprot),
    .arqos    (m_axi_image_arqos),
    .aruser   (m_axi_image_aruser),
    .arvalid  (m_axi_image_arvalid),
    .arready  (m_axi_image_arready),
    .rid      (m_axi_image_rid),
    .rdata    (m_axi_image_rdata),
    .rresp    (m_axi_image_rresp),
    .rlast    (m_axi_image_rlast),
    .ruser    (m_axi_image_ruser),
    .rvalid   (m_axi_image_rvalid),
    .rready   (m_axi_image_rready),
    .*
  );

  ninjin_s_axi_renkon #(
    .ID_WIDTH     (C_s_axi_renkon_ID_WIDTH),
    .DATA_WIDTH   (C_s_axi_renkon_DATA_WIDTH),
    .ADDR_WIDTH   (C_s_axi_renkon_ADDR_WIDTH),
    .AWUSER_WIDTH (C_s_axi_renkon_AWUSER_WIDTH),
    .ARUSER_WIDTH (C_s_axi_renkon_ARUSER_WIDTH),
    .WUSER_WIDTH  (C_s_axi_renkon_WUSER_WIDTH),
    .RUSER_WIDTH  (C_s_axi_renkon_RUSER_WIDTH),
    .BUSER_WIDTH  (C_s_axi_renkon_BUSER_WIDTH)
  ) ninjin_s_axi_renkon_inst(
    .clk      (s_axi_renkon_aclk),
    .xrst     (s_axi_renkon_aresetn),
    .awid     (s_axi_renkon_awid),
    .awaddr   (s_axi_renkon_awaddr),
    .awlen    (s_axi_renkon_awlen),
    .awsize   (s_axi_renkon_awsize),
    .awburst  (s_axi_renkon_awburst),
    .awlock   (s_axi_renkon_awlock),
    .awcache  (s_axi_renkon_awcache),
    .awprot   (s_axi_renkon_awprot),
    .awqos    (s_axi_renkon_awqos),
    .awregion (s_axi_renkon_awregion),
    .awuser   (s_axi_renkon_awuser),
    .awvalid  (s_axi_renkon_awvalid),
    .awready  (s_axi_renkon_awready),
    .wdata    (s_axi_renkon_wdata),
    .wstrb    (s_axi_renkon_wstrb),
    .wlast    (s_axi_renkon_wlast),
    .wuser    (s_axi_renkon_wuser),
    .wvalid   (s_axi_renkon_wvalid),
    .wready   (s_axi_renkon_wready),
    .bid      (s_axi_renkon_bid),
    .bresp    (s_axi_renkon_bresp),
    .buser    (s_axi_renkon_buser),
    .bvalid   (s_axi_renkon_bvalid),
    .bready   (s_axi_renkon_bready),
    .arid     (s_axi_renkon_arid),
    .araddr   (s_axi_renkon_araddr),
    .arlen    (s_axi_renkon_arlen),
    .arsize   (s_axi_renkon_arsize),
    .arburst  (s_axi_renkon_arburst),
    .arlock   (s_axi_renkon_arlock),
    .arcache  (s_axi_renkon_arcache),
    .arprot   (s_axi_renkon_arprot),
    .arqos    (s_axi_renkon_arqos),
    .arregion (s_axi_renkon_arregion),
    .aruser   (s_axi_renkon_aruser),
    .arvalid  (s_axi_renkon_arvalid),
    .arready  (s_axi_renkon_arready),
    .rid      (s_axi_renkon_rid),
    .rdata    (s_axi_renkon_rdata),
    .rresp    (s_axi_renkon_rresp),
    .rlast    (s_axi_renkon_rlast),
    .ruser    (s_axi_renkon_ruser),
    .rvalid   (s_axi_renkon_rvalid),
    .rready   (s_axi_renkon_rready),
    .mem_we     (mem_renkon_we),
    .mem_addr   (mem_renkon_addr),
    .mem_wdata  (mem_renkon_wdata),
    .mem_rdata  (mem_renkon_rdata),
    .*
  );

  mem_sp #(DWIDTH, RENKON_CORELOG+RENKON_NETSIZE) mem_renkon_debug(
      .mem_we     (mem_renkon_we),
      .mem_addr   (mem_renkon_addr),
      .mem_wdata  (mem_renkon_wdata[DWIDTH-1:0]),
      .mem_rdata  (mem_renkon_rdata[DWIDTH-1:0]),
      .*
  );

  ninjin_s_axi_gobou #(
    .ID_WIDTH     (C_s_axi_gobou_ID_WIDTH),
    .DATA_WIDTH   (C_s_axi_gobou_DATA_WIDTH),
    .ADDR_WIDTH   (C_s_axi_gobou_ADDR_WIDTH),
    .AWUSER_WIDTH (C_s_axi_gobou_AWUSER_WIDTH),
    .ARUSER_WIDTH (C_s_axi_gobou_ARUSER_WIDTH),
    .WUSER_WIDTH  (C_s_axi_gobou_WUSER_WIDTH),
    .RUSER_WIDTH  (C_s_axi_gobou_RUSER_WIDTH),
    .BUSER_WIDTH  (C_s_axi_gobou_BUSER_WIDTH)
  ) ninjin_s_axi_gobou_inst(
    .clk      (s_axi_gobou_aclk),
    .xrst     (s_axi_gobou_aresetn),
    .awid     (s_axi_gobou_awid),
    .awaddr   (s_axi_gobou_awaddr),
    .awlen    (s_axi_gobou_awlen),
    .awsize   (s_axi_gobou_awsize),
    .awburst  (s_axi_gobou_awburst),
    .awlock   (s_axi_gobou_awlock),
    .awcache  (s_axi_gobou_awcache),
    .awprot   (s_axi_gobou_awprot),
    .awqos    (s_axi_gobou_awqos),
    .awregion (s_axi_gobou_awregion),
    .awuser   (s_axi_gobou_awuser),
    .awvalid  (s_axi_gobou_awvalid),
    .awready  (s_axi_gobou_awready),
    .wdata    (s_axi_gobou_wdata),
    .wstrb    (s_axi_gobou_wstrb),
    .wlast    (s_axi_gobou_wlast),
    .wuser    (s_axi_gobou_wuser),
    .wvalid   (s_axi_gobou_wvalid),
    .wready   (s_axi_gobou_wready),
    .bid      (s_axi_gobou_bid),
    .bresp    (s_axi_gobou_bresp),
    .buser    (s_axi_gobou_buser),
    .bvalid   (s_axi_gobou_bvalid),
    .bready   (s_axi_gobou_bready),
    .arid     (s_axi_gobou_arid),
    .araddr   (s_axi_gobou_araddr),
    .arlen    (s_axi_gobou_arlen),
    .arsize   (s_axi_gobou_arsize),
    .arburst  (s_axi_gobou_arburst),
    .arlock   (s_axi_gobou_arlock),
    .arcache  (s_axi_gobou_arcache),
    .arprot   (s_axi_gobou_arprot),
    .arqos    (s_axi_gobou_arqos),
    .arregion (s_axi_gobou_arregion),
    .aruser   (s_axi_gobou_aruser),
    .arvalid  (s_axi_gobou_arvalid),
    .arready  (s_axi_gobou_arready),
    .rid      (s_axi_gobou_rid),
    .rdata    (s_axi_gobou_rdata),
    .rresp    (s_axi_gobou_rresp),
    .rlast    (s_axi_gobou_rlast),
    .ruser    (s_axi_gobou_ruser),
    .rvalid   (s_axi_gobou_rvalid),
    .rready   (s_axi_gobou_rready),
    .mem_we     (mem_gobou_we),
    .mem_addr   (mem_gobou_addr),
    .mem_wdata  (mem_gobou_wdata),
    .mem_rdata  (mem_gobou_rdata),
    .*
  );

  mem_sp #(DWIDTH, GOBOU_CORELOG+GOBOU_NETSIZE) mem_gobou_debug(
      .mem_we     (mem_gobou_we),
      .mem_addr   (mem_gobou_addr),
      .mem_wdata  (mem_gobou_wdata[DWIDTH-1:0]),
      .mem_rdata  (mem_gobou_rdata[DWIDTH-1:0]),
      .*
  );

// }}}
//==========================================================
// main modules
//==========================================================
// {{{

  ninjin_ddr_buf mem_img(
    // Outputs
    .mem_rdata  (mem_img_rdata[DWIDTH-1:0]),
    // Inputs
    .clk        (clk),
    .mem_we     (mem_img_we),
    .mem_addr   (mem_img_addr[MEMSIZE-1:0]),
    .mem_wdata  (mem_img_wdata[DWIDTH-1:0]),
    .*
  );

  renkon_top renkon0(
    // Outputs
    .ack        (renkon_ack),
    .img_we     (renkon_img_we),
    .img_addr   (renkon_img_addr[MEMSIZE-1:0]),
    .img_wdata  (renkon_img_wdata[DWIDTH-1:0]),
    // Inputs
    .clk        (clk),
    .xrst       (xrst),
    .req        (renkon_req),
    .qbits      (renkon_qbits[LWIDTH-1:0]),
    .net_sel    (renkon_net_sel[RENKON_CORELOG-1:0]),
    .net_we     (renkon_net_we),
    .net_addr   (renkon_net_addr[RENKON_NETSIZE-1:0]),
    .net_wdata  (renkon_net_wdata[DWIDTH-1:0]),
    .in_offset  (renkon_in_offset[MEMSIZE-1:0]),
    .out_offset (renkon_out_offset[MEMSIZE-1:0]),
    .net_offset (renkon_net_offset[RENKON_NETSIZE-1:0]),
    .total_out  (renkon_total_out[LWIDTH-1:0]),
    .total_in   (renkon_total_in[LWIDTH-1:0]),
    .img_height (renkon_img_height[LWIDTH-1:0]),
    .img_width  (renkon_img_width[LWIDTH-1:0]),
    .fea_height (renkon_fea_height[LWIDTH-1:0]),
    .fea_width  (renkon_fea_width[LWIDTH-1:0]),
    .conv_kern  (renkon_conv_kern[LWIDTH-1:0]),
    .conv_strid (renkon_conv_strid[LWIDTH-1:0]),
    .conv_pad   (renkon_conv_pad[LWIDTH-1:0]),
    .bias_en    (renkon_bias_en),
    .relu_en    (renkon_relu_en),
    .pool_en    (renkon_pool_en),
    .pool_kern  (renkon_pool_kern[LWIDTH-1:0]),
    .pool_strid (renkon_pool_strid[LWIDTH-1:0]),
    .pool_pad   (renkon_pool_pad[LWIDTH-1:0]),
    .img_rdata  (renkon_img_rdata[DWIDTH-1:0]),
    .*
  );

  gobou_top gobou0(
    // Outputs
    .ack        (gobou_ack),
    .img_we     (gobou_img_we),
    .img_addr   (gobou_img_addr[MEMSIZE-1:0]),
    .img_wdata  (gobou_img_wdata[DWIDTH-1:0]),
    // Inputs
    .clk        (clk),
    .xrst       (xrst),
    .req        (gobou_req),
    .qbits      (gobou_qbits[LWIDTH-1:0]),
    .net_sel    (gobou_net_sel[GOBOU_CORELOG-1:0]),
    .net_we     (gobou_net_we),
    .net_addr   (gobou_net_addr[GOBOU_NETSIZE-1:0]),
    .net_wdata  (gobou_net_wdata[DWIDTH-1:0]),
    .in_offset  (gobou_in_offset[MEMSIZE-1:0]),
    .out_offset (gobou_out_offset[MEMSIZE-1:0]),
    .net_offset (gobou_net_offset[GOBOU_NETSIZE-1:0]),
    .total_out  (gobou_total_out[LWIDTH-1:0]),
    .total_in   (gobou_total_in[LWIDTH-1:0]),
    .bias_en    (gobou_bias_en),
    .relu_en    (gobou_relu_en),
    .img_rdata  (gobou_img_rdata[DWIDTH-1:0]),
    .*
  );

// }}}
endmodule
