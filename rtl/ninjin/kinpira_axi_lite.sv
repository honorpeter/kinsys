`include "ninjin.svh"
`include "gobou.svh"
`include "renkon.svh"

module kinpira_axi_lite
 #( parameter C_s_axi_DATA_WIDTH  = 32
  , parameter C_s_axi_ADDR_WIDTH  = 7
  )
  // Ports of Axi Slave Bus Interface s_axi
  ( input                             s_axi_aclk
  , input                             s_axi_aresetn
  , input  [C_s_axi_ADDR_WIDTH-1:0]   s_axi_awaddr
  , input  [2:0]                      s_axi_awprot
  , input                             s_axi_awvalid
  , output                            s_axi_awready
  , input  [C_s_axi_DATA_WIDTH-1:0]   s_axi_wdata
  , input  [C_s_axi_DATA_WIDTH/8-1:0] s_axi_wstrb
  , input                             s_axi_wvalid
  , output                            s_axi_wready
  , output [1:0]                      s_axi_bresp
  , output                            s_axi_bvalid
  , input                             s_axi_bready
  , input  [C_s_axi_ADDR_WIDTH-1:0]   s_axi_araddr
  , input  [2:0]                      s_axi_arprot
  , input                             s_axi_arvalid
  , output                            s_axi_arready
  , output [C_s_axi_DATA_WIDTH-1:0]   s_axi_rdata
  , output [1:0]                      s_axi_rresp
  , output                            s_axi_rvalid
  , input                             s_axi_rready
  );
// Instantiation of Axi Bus Interface s_axi
  wire [C_s_axi_DATA_WIDTH-1:0]	in_port [PORT/2-1:0];
  wire [C_s_axi_DATA_WIDTH-1:0]	out_port [PORT-1:PORT/2];

  ninjin_s_axi_lite #(
    .DATA_WIDTH (C_s_axi_DATA_WIDTH),
    .ADDR_WIDTH (C_s_axi_ADDR_WIDTH)
  ) ninjin_s_axi_lite_inst (
    .clk      (s_axi_aclk),
    .xrst     (s_axi_aresetn),
    .awaddr   (s_axi_awaddr),
    .awprot   (s_axi_awprot),
    .awvalid  (s_axi_awvalid),
    .awready  (s_axi_awready),
    .wdata    (s_axi_wdata),
    .wstrb    (s_axi_wstrb),
    .wvalid   (s_axi_wvalid),
    .wready   (s_axi_wready),
    .bresp    (s_axi_bresp),
    .bvalid   (s_axi_bvalid),
    .bready   (s_axi_bready),
    .araddr   (s_axi_araddr),
    .arprot   (s_axi_arprot),
    .arvalid  (s_axi_arvalid),
    .arready  (s_axi_arready),
    .rdata    (s_axi_rdata),
    .rresp    (s_axi_rresp),
    .rvalid   (s_axi_rvalid),
    .rready   (s_axi_rready),
    .*
  );

  // Add user logic here

  wire                      clk;
  wire                      xrst;
  wire signed [DWIDTH-1:0]  read_img;

  // For ninjin
  wire                      which;
  wire                      req;
  wire                      img_we;
  wire [IMGSIZE-1:0]        input_addr;
  wire [IMGSIZE-1:0]        output_addr;
  wire signed [DWIDTH-1:0]  write_img;
  wire [32-1:0]             net_we;
  wire [32-1:0]             net_addr;
  wire signed [DWIDTH-1:0]  write_net;
  wire [LWIDTH-1:0]         total_out;
  wire [LWIDTH-1:0]         total_in;
  wire [LWIDTH-1:0]         img_size;
  wire [LWIDTH-1:0]         fil_size;
  wire [LWIDTH-1:0]         pool_size;

  wire                      ack;
  wire                      mem_img_we;
  wire [IMGSIZE-1:0]        mem_img_addr;
  wire signed [DWIDTH-1:0]  write_mem_img;

  // For renkon
  wire                      renkon_req;
  wire                      renkon_img_we;
  wire [IMGSIZE-1:0]        renkon_input_addr;
  wire [IMGSIZE-1:0]        renkon_output_addr;
  wire signed [DWIDTH-1:0]  renkon_write_img;
  wire [RENKON_CORELOG:0]   renkon_net_we;
  wire [RENKON_NETSIZE-1:0] renkon_net_addr;
  wire signed [DWIDTH-1:0]  renkon_write_net;
  wire [LWIDTH-1:0]         renkon_total_out;
  wire [LWIDTH-1:0]         renkon_total_in;
  wire [LWIDTH-1:0]         renkon_img_size;
  wire [LWIDTH-1:0]         renkon_fil_size;
  wire [LWIDTH-1:0]         renkon_pool_size;
  wire signed [DWIDTH-1:0]  renkon_read_img;

  wire                      renkon_ack;
  wire                      renkon_mem_img_we;
  wire [IMGSIZE-1:0]        renkon_mem_img_addr;
  wire signed [DWIDTH-1:0]  renkon_write_mem_img;

  // For gobou
  wire                      gobou_req;
  wire                      gobou_img_we;
  wire [IMGSIZE-1:0]        gobou_input_addr;
  wire [IMGSIZE-1:0]        gobou_output_addr;
  wire signed [DWIDTH-1:0]  gobou_write_img;
  wire [GOBOU_CORELOG:0]    gobou_net_we;
  wire [GOBOU_NETSIZE-1:0]  gobou_net_addr;
  wire signed [DWIDTH-1:0]  gobou_write_net;
  wire [LWIDTH-1:0]         gobou_total_out;
  wire [LWIDTH-1:0]         gobou_total_in;
  wire [LWIDTH-1:0]         gobou_img_size;
  wire [LWIDTH-1:0]         gobou_fil_size;
  wire [LWIDTH-1:0]         gobou_pool_size;
  wire signed [DWIDTH-1:0]  gobou_read_img;

  wire                      gobou_ack;
  wire                      gobou_mem_img_we;
  wire [IMGSIZE-1:0]        gobou_mem_img_addr;
  wire signed [DWIDTH-1:0]  gobou_write_mem_img;

  reg r_which;



  /* which:
   *   0: renkon  (2D convolution)
   *   1: gobou   (1D linear)
   */
  assign clk          = s_axi_aclk;
  assign xrst         = s_axi_aresetn;
  assign which        = in_port[0][0];
  assign req          = in_port[1][0];
  assign img_we       = in_port[2][0];
  assign input_addr   = in_port[3][IMGSIZE-1:0];
  assign output_addr  = in_port[4][IMGSIZE-1:0];
  assign write_img    = in_port[5][DWIDTH-1:0];
  assign net_we       = in_port[6][32-1:0];
  assign net_addr     = in_port[7][32-1:0];
  assign write_net    = in_port[8][DWIDTH-1:0];
  assign total_out    = in_port[9][LWIDTH-1:0];
  assign total_in     = in_port[10][LWIDTH-1:0];
  assign img_size     = in_port[11][LWIDTH-1:0];
  assign fil_size     = in_port[12][LWIDTH-1:0];
  assign pool_size    = in_port[13][LWIDTH-1:0];

  assign out_port[31] = {31'b0, r_which};
  assign out_port[30] = {31'b0, ack};
  assign out_port[29] = {{(32-DWIDTH){read_img[DWIDTH-1]}}, read_img};

  // For renkon
  assign renkon_req         = !which ? req                        : 0;
  assign renkon_img_we      = !which ? img_we                     : 0;
  assign renkon_input_addr  = !which ? input_addr                 : 0;
  assign renkon_output_addr = !which ? output_addr                : 0;
  assign renkon_write_img   = !which ? write_img                  : 0;
  assign renkon_net_we      = !which ? net_we[RENKON_CORELOG:0]   : 0;
  assign renkon_net_addr    = !which ? net_addr[RENKON_NETSIZE-1] : 0;
  assign renkon_write_net   = !which ? write_net                  : 0;
  assign renkon_total_out   = !which ? total_out                  : 0;
  assign renkon_total_in    = !which ? total_in                   : 0;
  assign renkon_img_size    = !which ? img_size                   : 0;
  assign renkon_fil_size    = !which ? fil_size                   : 0;
  assign renkon_pool_size   = !which ? pool_size                  : 0;
  assign renkon_read_img    = !which ? read_img                   : 0;

  // For gobou
  assign gobou_req          = which ? req                         : 0;
  assign gobou_img_we       = which ? img_we                      : 0;
  assign gobou_input_addr   = which ? input_addr                  : 0;
  assign gobou_output_addr  = which ? output_addr                 : 0;
  assign gobou_write_img    = which ? write_img                   : 0;
  assign gobou_net_we       = which ? net_we[GOBOU_CORELOG:0]     : 0;
  assign gobou_net_addr     = which ? net_addr[GOBOU_NETSIZE-1:0] : 0;
  assign gobou_write_net    = which ? write_net                   : 0;
  assign gobou_total_out    = which ? total_out                   : 0;
  assign gobou_total_in     = which ? total_in                    : 0;
  assign gobou_img_size     = which ? img_size                    : 0;
  assign gobou_fil_size     = which ? fil_size                    : 0;
  assign gobou_pool_size    = which ? pool_size                   : 0;
  assign gobou_read_img     = which ? read_img                    : 0;

  assign ack            = !which ? renkon_ack           : gobou_ack           ;
  assign mem_img_we     = !which ? renkon_mem_img_we    : gobou_mem_img_we    ;
  assign mem_img_addr   = !which ? renkon_mem_img_addr  : gobou_mem_img_addr  ;
  assign write_mem_img  = !which ? renkon_write_mem_img : gobou_write_mem_img ;


  always @(posedge clk)
    if (!xrst)
      r_which <= 0;
    else
      r_which <= which;


  mem_sp #(DWIDTH, IMGSIZE) mem_img(/*AUTOINST*/
    // Outputs
    .read_data  (read_img[DWIDTH-1:0]),
    // Inputs
    .clk        (clk),
    .mem_we     (mem_img_we),
    .mem_addr   (mem_img_addr[IMGSIZE-1:0]),
    .write_data (write_mem_img[DWIDTH-1:0])
  );

  renkon_top renkon(/*AUTOINST*/
    // Outputs
    .ack            (renkon_ack),
    .mem_img_we     (renkon_mem_img_we),
    .mem_img_addr   (renkon_mem_img_addr[IMGSIZE-1:0]),
    .write_mem_img  (renkon_write_mem_img[DWIDTH-1:0]),
    // Inputs
    .clk            (clk),
    .xrst           (xrst),
    .req            (renkon_req),
    .img_we         (renkon_img_we),
    .input_addr     (renkon_input_addr[IMGSIZE-1:0]),
    .output_addr    (renkon_output_addr[IMGSIZE-1:0]),
    .write_img      (renkon_write_img[DWIDTH-1:0]),
    .net_we         (renkon_net_we[RENKON_CORELOG:0]),
    .net_addr       (renkon_net_addr[RENKON_NETSIZE-1:0]),
    .write_net      (renkon_write_net[DWIDTH-1:0]),
    .total_out      (renkon_total_out[LWIDTH-1:0]),
    .total_in       (renkon_total_in[LWIDTH-1:0]),
    .img_size       (renkon_img_size[LWIDTH-1:0]),
    .fil_size       (renkon_fil_size[LWIDTH-1:0]),
    .pool_size      (renkon_pool_size[LWIDTH-1:0]),
    .read_img       (renkon_read_img[DWIDTH-1:0])
  );

  gobou_top gobou(/*AUTOINST*/
    // Outputs
    .ack            (gobou_ack),
    .mem_img_we     (gobou_mem_img_we),
    .mem_img_addr   (gobou_mem_img_addr[IMGSIZE-1:0]),
    .write_mem_img  (gobou_write_mem_img[DWIDTH-1:0]),
    // Inputs
    .clk            (clk),
    .xrst           (xrst),
    .req            (gobou_req),
    .img_we         (gobou_img_we),
    .input_addr     (gobou_input_addr[IMGSIZE-1:0]),
    .output_addr    (gobou_output_addr[IMGSIZE-1:0]),
    .write_img      (gobou_write_img[DWIDTH-1:0]),
    .net_we         (gobou_net_we[GOBOU_CORELOG:0]),
    .net_addr       (gobou_net_addr[GOBOU_NETSIZE-1:0]),
    .write_net      (gobou_write_net[DWIDTH-1:0]),
    .total_out      (gobou_total_out[LWIDTH-1:0]),
    .total_in       (gobou_total_in[LWIDTH-1:0]),
    .read_img       (gobou_read_img[DWIDTH-1:0])
  );

  // User logic ends

endmodule
