`include "ninjin.svh"
`include "renkon.svh"
`include "gobou.svh"

module kinpira_axi
 #( parameter C_s_axi_params_DATA_WIDTH = 32
  , parameter C_s_axi_params_ADDR_WIDTH = 7

  // Parameters of Axi Slave Bus Interface s_axi_image
  , parameter C_s_axi_image_ID_WIDTH      = 12
  , parameter C_s_axi_image_DATA_WIDTH    = 32
  , parameter C_s_axi_image_ADDR_WIDTH    = 12
  , parameter C_s_axi_image_AWUSER_WIDTH  = 0
  , parameter C_s_axi_image_ARUSER_WIDTH  = 0
  , parameter C_s_axi_image_WUSER_WIDTH   = 0
  , parameter C_s_axi_image_RUSER_WIDTH   = 0
  , parameter C_s_axi_image_BUSER_WIDTH   = 0

  // Parameters of Axi Slave Bus Interface s_axi_renkon
  , parameter C_s_axi_renkon_ID_WIDTH     = 12
  , parameter C_s_axi_renkon_DATA_WIDTH   = 32
  , parameter C_s_axi_renkon_ADDR_WIDTH   = 12
  , parameter C_s_axi_renkon_AWUSER_WIDTH = 0
  , parameter C_s_axi_renkon_ARUSER_WIDTH = 0
  , parameter C_s_axi_renkon_WUSER_WIDTH  = 0
  , parameter C_s_axi_renkon_RUSER_WIDTH  = 0
  , parameter C_s_axi_renkon_BUSER_WIDTH  = 0

  // Parameters of Axi Slave Bus Interface s_axi_gobou
  , parameter C_s_axi_gobou_ID_WIDTH      = 12
  , parameter C_s_axi_gobou_DATA_WIDTH    = 32
  , parameter C_s_axi_gobou_ADDR_WIDTH    = 12
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

  // Ports of Axi Slave Bus Interface s_axi_image
  , input                                   s_axi_image_aclk
  , input                                   s_axi_image_aresetn
  , input  [C_s_axi_image_ID_WIDTH-1:0]     s_axi_image_awid
  , input  [C_s_axi_image_ADDR_WIDTH-1:0]   s_axi_image_awaddr
  , input  [7:0]                            s_axi_image_awlen
  , input  [2:0]                            s_axi_image_awsize
  , input  [1:0]                            s_axi_image_awburst
  , input                                   s_axi_image_awlock
  , input  [3:0]                            s_axi_image_awcache
  , input  [2:0]                            s_axi_image_awprot
  , input  [3:0]                            s_axi_image_awqos
  , input  [3:0]                            s_axi_image_awregion
  , input  [C_s_axi_image_AWUSER_WIDTH-1:0] s_axi_image_awuser
  , input                                   s_axi_image_awvalid
  , output                                  s_axi_image_awready
  , input  [C_s_axi_image_DATA_WIDTH-1:0]   s_axi_image_wdata
  , input  [C_s_axi_image_DATA_WIDTH/8-1:0] s_axi_image_wstrb
  , input                                   s_axi_image_wlast
  , input  [C_s_axi_image_WUSER_WIDTH-1:0]  s_axi_image_wuser
  , input                                   s_axi_image_wvalid
  , output                                  s_axi_image_wready
  , output [C_s_axi_image_ID_WIDTH-1:0]     s_axi_image_bid
  , output [1:0]                            s_axi_image_bresp
  , output [C_s_axi_image_BUSER_WIDTH-1:0]  s_axi_image_buser
  , output                                  s_axi_image_bvalid
  , input                                   s_axi_image_bready
  , input  [C_s_axi_image_ID_WIDTH-1:0]     s_axi_image_arid
  , input  [C_s_axi_image_ADDR_WIDTH-1:0]   s_axi_image_araddr
  , input  [7:0]                            s_axi_image_arlen
  , input  [2:0]                            s_axi_image_arsize
  , input  [1:0]                            s_axi_image_arburst
  , input                                   s_axi_image_arlock
  , input  [3:0]                            s_axi_image_arcache
  , input  [2:0]                            s_axi_image_arprot
  , input  [3:0]                            s_axi_image_arqos
  , input  [3:0]                            s_axi_image_arregion
  , input  [C_s_axi_image_ARUSER_WIDTH-1:0] s_axi_image_aruser
  , input                                   s_axi_image_arvalid
  , output                                  s_axi_image_arready
  , output [C_s_axi_image_ID_WIDTH-1:0]     s_axi_image_rid
  , output [C_s_axi_image_DATA_WIDTH-1:0]   s_axi_image_rdata
  , output [1:0]                            s_axi_image_rresp
  , output                                  s_axi_image_rlast
  , output [C_s_axi_image_RUSER_WIDTH-1:0]  s_axi_image_ruser
  , output                                  s_axi_image_rvalid
  , input                                   s_axi_image_rready

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


  wire                      clk;
  wire                      xrst;
  wire signed [DWIDTH-1:0]  mem_img_rdata;

  wire [C_s_axi_params_DATA_WIDTH-1:0]  in_port [PORT/2-1:0];
  wire [C_s_axi_params_DATA_WIDTH-1:0]  out_port [PORT-1:PORT/2];

  wire                                  mem_image_we;
  wire [C_s_axi_image_ADDR_WIDTH-2-1:0] mem_image_addr;
  wire [C_s_axi_image_DATA_WIDTH-1:0]   mem_image_wdata;
  wire [C_s_axi_image_DATA_WIDTH-1:0]   mem_image_rdata;

  wire                                  mem_gobou_we;
  wire [C_s_axi_gobou_ADDR_WIDTH-2-1:0] mem_gobou_addr;
  wire [C_s_axi_gobou_DATA_WIDTH-1:0]   mem_gobou_wdata;
  wire [C_s_axi_gobou_DATA_WIDTH-1:0]   mem_gobou_rdata;

  wire                                    mem_renkon_we;
  wire [C_s_axi_renkon_ADDR_WIDTH-2-1:0]  mem_renkon_addr;
  wire [C_s_axi_renkon_DATA_WIDTH-1:0]    mem_renkon_wdata;
  wire [C_s_axi_renkon_DATA_WIDTH-1:0]    mem_renkon_rdata;

  // For ninjin
  wire [2-1:0]              which;
  wire                      req;
  wire [32-1:0]             net_sel;
  wire [IMGSIZE-1:0]        in_offset;
  wire [IMGSIZE-1:0]        out_offset;
  wire [32-1:0]             net_offset;
  wire [LWIDTH-1:0]         total_out;
  wire [LWIDTH-1:0]         total_in;
  wire [LWIDTH-1:0]         img_size;
  wire [LWIDTH-1:0]         fil_size;
  wire [LWIDTH-1:0]         pool_size;
  wire signed [DWIDTH-1:0]  img_rdata;

  wire                      ack;
  wire                      mem_img_we;
  wire [IMGSIZE-1:0]        mem_img_addr;
  wire signed [DWIDTH-1:0]  mem_img_wdata;

  // For renkon
  wire                      renkon_req;
  wire [RENKON_CORELOG-1:0] renkon_net_sel;
  wire                      renkon_net_we;
  wire [RENKON_NETSIZE-1:0] renkon_net_addr;
  wire signed [DWIDTH-1:0]  renkon_net_wdata;
  wire [IMGSIZE-1:0]        renkon_in_offset;
  wire [IMGSIZE-1:0]        renkon_out_offset;
  wire [RENKON_NETSIZE-1:0] renkon_net_offset;
  wire [LWIDTH-1:0]         renkon_total_out;
  wire [LWIDTH-1:0]         renkon_total_in;
  wire [LWIDTH-1:0]         renkon_img_size;
  wire [LWIDTH-1:0]         renkon_fil_size;
  wire [LWIDTH-1:0]         renkon_pool_size;
  wire signed [DWIDTH-1:0]  renkon_img_rdata;

  wire                      renkon_ack;
  wire                      renkon_mem_img_we;
  wire [IMGSIZE-1:0]        renkon_mem_img_addr;
  wire signed [DWIDTH-1:0]  renkon_mem_img_wdata;

  // For gobou
  wire                      gobou_req;
  wire [GOBOU_CORELOG-1:0]  gobou_net_sel;
  wire                      gobou_net_we;
  wire [GOBOU_NETSIZE-1:0]  gobou_net_addr;
  wire signed [DWIDTH-1:0]  gobou_net_wdata;
  wire [IMGSIZE-1:0]        gobou_in_offset;
  wire [IMGSIZE-1:0]        gobou_out_offset;
  wire [GOBOU_NETSIZE-1:0]  gobou_net_offset;
  wire [LWIDTH-1:0]         gobou_total_out;
  wire [LWIDTH-1:0]         gobou_total_in;
  wire [LWIDTH-1:0]         gobou_img_size;
  wire [LWIDTH-1:0]         gobou_fil_size;
  wire [LWIDTH-1:0]         gobou_pool_size;
  wire signed [DWIDTH-1:0]  gobou_img_rdata;

  wire                      gobou_ack;
  wire                      gobou_mem_img_we;
  wire [IMGSIZE-1:0]        gobou_mem_img_addr;
  wire signed [DWIDTH-1:0]  gobou_mem_img_wdata;

  reg [2-1:0] r_which;



  assign clk        = s_axi_params_aclk;
  assign xrst       = s_axi_params_aresetn;
  assign which      = in_port[0][1:0];
  assign req        = in_port[1][0];
  assign net_sel    = in_port[2][32-1:0];
  assign in_offset  = in_port[3][IMGSIZE-1:0];
  assign out_offset = in_port[4][IMGSIZE-1:0];
  assign net_offset = in_port[5][IMGSIZE-1:0];
  assign total_out  = in_port[6][LWIDTH-1:0];
  assign total_in   = in_port[7][LWIDTH-1:0];
  assign img_size   = in_port[8][LWIDTH-1:0];
  assign fil_size   = in_port[9][LWIDTH-1:0];
  assign pool_size  = in_port[10][LWIDTH-1:0];

  assign out_port[31] = {30'b0, r_which};
  assign out_port[30] = {31'b0, ack};

  // For renkon
  assign renkon_net_sel     = net_sel[RENKON_CORELOG-1:0];
  assign renkon_net_we      = mem_renkon_we;
  assign renkon_net_addr    = mem_renkon_addr;
  assign renkon_net_wdata   = mem_renkon_wdata;

  assign renkon_req        = which == WHICH_RENKON ? req : 0;
  assign renkon_in_offset  = which == WHICH_RENKON ? in_offset : 0;
  assign renkon_out_offset = which == WHICH_RENKON ? out_offset : 0;
  assign renkon_net_offset = which == WHICH_RENKON ? net_offset[RENKON_NETSIZE-1:0] : 0;
  assign renkon_total_out  = which == WHICH_RENKON ? total_out : 0;
  assign renkon_total_in   = which == WHICH_RENKON ? total_in : 0;
  assign renkon_img_size   = which == WHICH_RENKON ? img_size : 0;
  assign renkon_fil_size   = which == WHICH_RENKON ? fil_size : 0;
  assign renkon_pool_size  = which == WHICH_RENKON ? pool_size : 0;
  assign renkon_img_rdata  = which == WHICH_RENKON ? img_rdata : 0;


  // For gobou
  assign gobou_net_sel   = net_sel[GOBOU_CORELOG-1:0];
  assign gobou_net_we    = mem_gobou_we;
  assign gobou_net_addr  = mem_gobou_addr;
  assign gobou_net_wdata = mem_gobou_wdata;

  assign gobou_req         = which == WHICH_GOBOU ? req : 0;
  assign gobou_in_offset   = which == WHICH_GOBOU ? in_offset : 0;
  assign gobou_out_offset  = which == WHICH_GOBOU ? out_offset : 0;
  assign gobou_net_offset  = which == WHICH_GOBOU ? net_offset[GOBOU_NETSIZE-1:0] : 0;
  assign gobou_total_out   = which == WHICH_GOBOU ? total_out : 0;
  assign gobou_total_in    = which == WHICH_GOBOU ? total_in : 0;
  assign gobou_img_size    = which == WHICH_GOBOU ? img_size : 0;
  assign gobou_fil_size    = which == WHICH_GOBOU ? fil_size : 0;
  assign gobou_pool_size   = which == WHICH_GOBOU ? pool_size : 0;
  assign gobou_img_rdata   = which == WHICH_GOBOU ? img_rdata : 0;


  // For ninjin
  assign mem_image_rdata = {{32-DWIDTH{img_rdata[DWIDTH-1]}}, img_rdata};

  assign ack            = which == WHICH_RENKON ? renkon_ack
                        : which == WHICH_GOBOU  ? gobou_ack
                        : which == WHICH_NINJIN ? 1'b1
                        : 0;
  assign mem_img_we     = which == WHICH_RENKON ? renkon_mem_img_we
                        : which == WHICH_GOBOU  ? gobou_mem_img_we
                        : which == WHICH_NINJIN ? mem_image_we
                        : 0;
  assign mem_img_addr   = which == WHICH_RENKON ? renkon_mem_img_addr
                        : which == WHICH_GOBOU  ? gobou_mem_img_addr
                        : which == WHICH_NINJIN ? mem_image_addr
                        : 0;
  assign mem_img_wdata  = which == WHICH_RENKON ? renkon_mem_img_wdata
                        : which == WHICH_GOBOU  ? gobou_mem_img_wdata
                        : which == WHICH_NINJIN ? mem_image_wdata
                        : 0;

  always @(posedge clk)
    if (!xrst)
      r_which <= 0;
    else
      r_which <= which;



  ninjin_s_axi_params #(
    .DATA_WIDTH (C_s_axi_params_DATA_WIDTH),
    .ADDR_WIDTH (C_s_axi_params_ADDR_WIDTH)
  ) ninjin_s_axi_params_inst (
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

  ninjin_s_axi_image #(
    .ID_WIDTH     (C_s_axi_image_ID_WIDTH),
    .DATA_WIDTH   (C_s_axi_image_DATA_WIDTH),
    .ADDR_WIDTH   (C_s_axi_image_ADDR_WIDTH),
    .AWUSER_WIDTH (C_s_axi_image_AWUSER_WIDTH),
    .ARUSER_WIDTH (C_s_axi_image_ARUSER_WIDTH),
    .WUSER_WIDTH  (C_s_axi_image_WUSER_WIDTH),
    .RUSER_WIDTH  (C_s_axi_image_RUSER_WIDTH),
    .BUSER_WIDTH  (C_s_axi_image_BUSER_WIDTH)
  ) ninjin_s_axi_image_inst (
    .clk      (s_axi_image_aclk),
    .xrst     (s_axi_image_aresetn),
    .awid     (s_axi_image_awid),
    .awaddr   (s_axi_image_awaddr),
    .awlen    (s_axi_image_awlen),
    .awsize   (s_axi_image_awsize),
    .awburst  (s_axi_image_awburst),
    .awlock   (s_axi_image_awlock),
    .awcache  (s_axi_image_awcache),
    .awprot   (s_axi_image_awprot),
    .awqos    (s_axi_image_awqos),
    .awregion (s_axi_image_awregion),
    .awuser   (s_axi_image_awuser),
    .awvalid  (s_axi_image_awvalid),
    .awready  (s_axi_image_awready),
    .wdata    (s_axi_image_wdata),
    .wstrb    (s_axi_image_wstrb),
    .wlast    (s_axi_image_wlast),
    .wuser    (s_axi_image_wuser),
    .wvalid   (s_axi_image_wvalid),
    .wready   (s_axi_image_wready),
    .bid      (s_axi_image_bid),
    .bresp    (s_axi_image_bresp),
    .buser    (s_axi_image_buser),
    .bvalid   (s_axi_image_bvalid),
    .bready   (s_axi_image_bready),
    .arid     (s_axi_image_arid),
    .araddr   (s_axi_image_araddr),
    .arlen    (s_axi_image_arlen),
    .arsize   (s_axi_image_arsize),
    .arburst  (s_axi_image_arburst),
    .arlock   (s_axi_image_arlock),
    .arcache  (s_axi_image_arcache),
    .arprot   (s_axi_image_arprot),
    .arqos    (s_axi_image_arqos),
    .arregion (s_axi_image_arregion),
    .aruser   (s_axi_image_aruser),
    .arvalid  (s_axi_image_arvalid),
    .arready  (s_axi_image_arready),
    .rid      (s_axi_image_rid),
    .rdata    (s_axi_image_rdata),
    .rresp    (s_axi_image_rresp),
    .rlast    (s_axi_image_rlast),
    .ruser    (s_axi_image_ruser),
    .rvalid   (s_axi_image_rvalid),
    .rready   (s_axi_image_rready),
    .mem_we     (mem_image_we),
    .mem_addr   (mem_image_addr),
    .mem_wdata  (mem_image_wdata),
    .mem_rdata  (mem_image_rdata),
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
  ) ninjin_s_axi_renkon_inst (
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

  ninjin_s_axi_gobou #(
    .ID_WIDTH     (C_s_axi_gobou_ID_WIDTH),
    .DATA_WIDTH   (C_s_axi_gobou_DATA_WIDTH),
    .ADDR_WIDTH   (C_s_axi_gobou_ADDR_WIDTH),
    .AWUSER_WIDTH (C_s_axi_gobou_AWUSER_WIDTH),
    .ARUSER_WIDTH (C_s_axi_gobou_ARUSER_WIDTH),
    .WUSER_WIDTH  (C_s_axi_gobou_WUSER_WIDTH),
    .RUSER_WIDTH  (C_s_axi_gobou_RUSER_WIDTH),
    .BUSER_WIDTH  (C_s_axi_gobou_BUSER_WIDTH)
  ) ninjin_s_axi_gobou_inst (
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

  mem_sp #(DWIDTH, IMGSIZE) mem_img (
    // Outputs
    .mem_rdata  (img_rdata[DWIDTH-1:0]),
    // Inputs
    .clk        (clk),
    .mem_we     (mem_img_we),
    .mem_addr   (mem_img_addr[IMGSIZE-1:0]),
    .mem_wdata  (mem_img_wdata[DWIDTH-1:0])
  );

  renkon_top renkon0 (
    // Outputs
    .ack            (renkon_ack),
    .mem_img_we     (renkon_mem_img_we),
    .mem_img_addr   (renkon_mem_img_addr[IMGSIZE-1:0]),
    .mem_img_wdata  (renkon_mem_img_wdata[DWIDTH-1:0]),
    // Inputs
    .clk            (clk),
    .xrst           (xrst),
    .req            (renkon_req),
    .net_sel        (renkon_net_sel[RENKON_CORELOG-1:0]),
    .net_we         (renkon_net_we),
    .net_addr       (renkon_net_addr[RENKON_NETSIZE-1:0]),
    .net_wdata      (renkon_net_wdata[DWIDTH-1:0]),
    .in_offset      (renkon_in_offset[IMGSIZE-1:0]),
    .out_offset     (renkon_out_offset[IMGSIZE-1:0]),
    .net_offset     (renkon_net_offset[RENKON_NETSIZE-1:0]),
    .total_out      (renkon_total_out[LWIDTH-1:0]),
    .total_in       (renkon_total_in[LWIDTH-1:0]),
    .img_size       (renkon_img_size[LWIDTH-1:0]),
    .fil_size       (renkon_fil_size[LWIDTH-1:0]),
    .pool_size      (renkon_pool_size[LWIDTH-1:0]),
    .img_rdata      (renkon_img_rdata[DWIDTH-1:0])
  );

  gobou_top gobou0 (
    // Outputs
    .ack            (gobou_ack),
    .mem_img_we     (gobou_mem_img_we),
    .mem_img_addr   (gobou_mem_img_addr[IMGSIZE-1:0]),
    .mem_img_wdata  (gobou_mem_img_wdata[DWIDTH-1:0]),
    // Inputs
    .clk            (clk),
    .xrst           (xrst),
    .req            (gobou_req),
    .net_sel        (gobou_net_sel[GOBOU_CORELOG-1:0]),
    .net_we         (gobou_net_we),
    .net_addr       (gobou_net_addr[GOBOU_NETSIZE-1:0]),
    .net_wdata      (gobou_net_wdata[DWIDTH-1:0]),
    .in_offset      (gobou_in_offset[IMGSIZE-1:0]),
    .out_offset     (gobou_out_offset[IMGSIZE-1:0]),
    .net_offset     (gobou_net_offset[GOBOU_NETSIZE-1:0]),
    .total_out      (gobou_total_out[LWIDTH-1:0]),
    .total_in       (gobou_total_in[LWIDTH-1:0]),
    .img_rdata      (gobou_img_rdata[DWIDTH-1:0])
  );

endmodule
