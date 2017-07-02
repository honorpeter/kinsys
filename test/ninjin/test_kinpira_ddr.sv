`include "ninjin.svh"
`include "renkon.svh"
`include "gobou.svh"

parameter C_s_axi_params_DATA_WIDTH = BWIDTH;
parameter C_s_axi_params_ADDR_WIDTH = REGSIZE + LSB;

// Parameters of Axi Master Bus Interface m_axi_image
parameter C_m_axi_image_BURST_MAX     = BURST_MAX;
parameter C_m_axi_image_ID_WIDTH      = 1;
parameter C_m_axi_image_DATA_WIDTH    = BWIDTH;
parameter C_m_axi_image_ADDR_WIDTH    = MEMSIZE + LSB;
parameter C_m_axi_image_AWUSER_WIDTH  = 0;
parameter C_m_axi_image_ARUSER_WIDTH  = 0;
parameter C_m_axi_image_WUSER_WIDTH   = 0;
parameter C_m_axi_image_RUSER_WIDTH   = 0;
parameter C_m_axi_image_BUSER_WIDTH   = 0;

// Parameters of Axi Slave Bus Interface s_axi_renkon
parameter C_s_axi_renkon_ID_WIDTH     = 12;
parameter C_s_axi_renkon_DATA_WIDTH   = BWIDTH;
parameter C_s_axi_renkon_ADDR_WIDTH   = RENKON_CORELOG + RENKON_NETSIZE + LSB;
parameter C_s_axi_renkon_AWUSER_WIDTH = 0;
parameter C_s_axi_renkon_ARUSER_WIDTH = 0;
parameter C_s_axi_renkon_WUSER_WIDTH  = 0;
parameter C_s_axi_renkon_RUSER_WIDTH  = 0;
parameter C_s_axi_renkon_BUSER_WIDTH  = 0;

// Parameters of Axi Slave Bus Interface s_axi_gobou
parameter C_s_axi_gobou_ID_WIDTH      = 12;
parameter C_s_axi_gobou_DATA_WIDTH    = BWIDTH;
parameter C_s_axi_gobou_ADDR_WIDTH    = GOBOU_CORELOG + GOBOU_NETSIZE + LSB;
parameter C_s_axi_gobou_AWUSER_WIDTH  = 0;
parameter C_s_axi_gobou_ARUSER_WIDTH  = 0;
parameter C_s_axi_gobou_WUSER_WIDTH   = 0;
parameter C_s_axi_gobou_RUSER_WIDTH   = 0;
parameter C_s_axi_gobou_BUSER_WIDTH   = 0;

module test_kinpira_ddr;

  reg clk;
  reg xrst;
  reg                                     s_axi_params_aclk;
  reg                                     s_axi_params_aresetn;
  reg  [C_s_axi_params_ADDR_WIDTH-1:0]    s_axi_params_awaddr;
  reg  [2:0]                              s_axi_params_awprot;
  reg                                     s_axi_params_awvalid;
  wire                                    s_axi_params_awready;
  reg  [C_s_axi_params_DATA_WIDTH-1:0]    s_axi_params_wdata;
  reg  [C_s_axi_params_DATA_WIDTH/8-1:0]  s_axi_params_wstrb;
  reg                                     s_axi_params_wvalid;
  wire                                    s_axi_params_wready;
  wire [1:0]                              s_axi_params_bresp;
  wire                                    s_axi_params_bvalid;
  reg                                     s_axi_params_bready;
  reg  [C_s_axi_params_ADDR_WIDTH-1:0]    s_axi_params_araddr;
  reg  [2:0]                              s_axi_params_arprot;
  reg                                     s_axi_params_arvalid;
  wire                                    s_axi_params_arready;
  wire [C_s_axi_params_DATA_WIDTH-1:0]    s_axi_params_rdata;
  wire [1:0]                              s_axi_params_rresp;
  wire                                    s_axi_params_rvalid;
  reg                                     s_axi_params_rready;

  // Ports of Axi Master Bus Interface m_axi_image
  reg                                   m_axi_image_aclk;
  reg                                   m_axi_image_aresetn;
  wire [C_m_axi_image_ID_WIDTH-1:0]     m_axi_image_awid;
  wire [C_m_axi_image_ADDR_WIDTH-1:0]   m_axi_image_awaddr;
  wire [7:0]                            m_axi_image_awlen;
  wire [2:0]                            m_axi_image_awsize;
  wire [1:0]                            m_axi_image_awburst;
  wire                                  m_axi_image_awlock;
  wire [3:0]                            m_axi_image_awcache;
  wire [2:0]                            m_axi_image_awprot;
  wire [3:0]                            m_axi_image_awqos;
  wire [C_m_axi_image_AWUSER_WIDTH-1:0] m_axi_image_awuser;
  wire                                  m_axi_image_awvalid;
  reg                                   m_axi_image_awready;
  wire [C_m_axi_image_DATA_WIDTH-1:0]   m_axi_image_wdata;
  wire [C_m_axi_image_DATA_WIDTH/8-1:0] m_axi_image_wstrb;
  wire                                  m_axi_image_wlast;
  wire [C_m_axi_image_WUSER_WIDTH-1:0]  m_axi_image_wuser;
  wire                                  m_axi_image_wvalid;
  reg                                   m_axi_image_wready;
  reg  [C_m_axi_image_ID_WIDTH-1:0]     m_axi_image_bid;
  reg  [1:0]                            m_axi_image_bresp;
  reg  [C_m_axi_image_BUSER_WIDTH-1:0]  m_axi_image_buser;
  reg                                   m_axi_image_bvalid;
  wire                                  m_axi_image_bready;
  wire [C_m_axi_image_ID_WIDTH-1:0]     m_axi_image_arid;
  wire [C_m_axi_image_ADDR_WIDTH-1:0]   m_axi_image_araddr;
  wire [7:0]                            m_axi_image_arlen;
  wire [2:0]                            m_axi_image_arsize;
  wire [1:0]                            m_axi_image_arburst;
  wire                                  m_axi_image_arlock;
  wire [3:0]                            m_axi_image_arcache;
  wire [2:0]                            m_axi_image_arprot;
  wire [3:0]                            m_axi_image_arqos;
  wire [C_m_axi_image_ARUSER_WIDTH-1:0] m_axi_image_aruser;
  wire                                  m_axi_image_arvalid;
  reg                                   m_axi_image_arready;
  reg  [C_m_axi_image_ID_WIDTH-1:0]     m_axi_image_rid;
  reg  [C_m_axi_image_DATA_WIDTH-1:0]   m_axi_image_rdata;
  reg  [1:0]                            m_axi_image_rresp;
  reg                                   m_axi_image_rlast;
  reg  [C_m_axi_image_RUSER_WIDTH-1:0]  m_axi_image_ruser;
  reg                                   m_axi_image_rvalid;
  wire                                  m_axi_image_rready;

  // Ports of Axi Slave Bus Interface s_axi_renkon
  reg                                     s_axi_renkon_aclk;
  reg                                     s_axi_renkon_aresetn;
  reg  [C_s_axi_renkon_ID_WIDTH-1:0]      s_axi_renkon_awid;
  reg  [C_s_axi_renkon_ADDR_WIDTH-1:0]    s_axi_renkon_awaddr;
  reg  [7:0]                              s_axi_renkon_awlen;
  reg  [2:0]                              s_axi_renkon_awsize;
  reg  [1:0]                              s_axi_renkon_awburst;
  reg                                     s_axi_renkon_awlock;
  reg  [3:0]                              s_axi_renkon_awcache;
  reg  [2:0]                              s_axi_renkon_awprot;
  reg  [3:0]                              s_axi_renkon_awqos;
  reg  [3:0]                              s_axi_renkon_awregion;
  reg  [C_s_axi_renkon_AWUSER_WIDTH-1:0]  s_axi_renkon_awuser;
  reg                                     s_axi_renkon_awvalid;
  wire                                    s_axi_renkon_awready;
  reg  [C_s_axi_renkon_DATA_WIDTH-1:0]    s_axi_renkon_wdata;
  reg  [C_s_axi_renkon_DATA_WIDTH/8-1:0]  s_axi_renkon_wstrb;
  reg                                     s_axi_renkon_wlast;
  reg  [C_s_axi_renkon_WUSER_WIDTH-1:0]   s_axi_renkon_wuser;
  reg                                     s_axi_renkon_wvalid;
  wire                                    s_axi_renkon_wready;
  wire [C_s_axi_renkon_ID_WIDTH-1:0]      s_axi_renkon_bid;
  wire [1:0]                              s_axi_renkon_bresp;
  wire [C_s_axi_renkon_BUSER_WIDTH-1:0]   s_axi_renkon_buser;
  wire                                    s_axi_renkon_bvalid;
  reg                                     s_axi_renkon_bready;
  reg  [C_s_axi_renkon_ID_WIDTH-1:0]      s_axi_renkon_arid;
  reg  [C_s_axi_renkon_ADDR_WIDTH-1:0]    s_axi_renkon_araddr;
  reg  [7:0]                              s_axi_renkon_arlen;
  reg  [2:0]                              s_axi_renkon_arsize;
  reg  [1:0]                              s_axi_renkon_arburst;
  reg                                     s_axi_renkon_arlock;
  reg  [3:0]                              s_axi_renkon_arcache;
  reg  [2:0]                              s_axi_renkon_arprot;
  reg  [3:0]                              s_axi_renkon_arqos;
  reg  [3:0]                              s_axi_renkon_arregion;
  reg  [C_s_axi_renkon_ARUSER_WIDTH-1:0]  s_axi_renkon_aruser;
  reg                                     s_axi_renkon_arvalid;
  wire                                    s_axi_renkon_arready;
  wire [C_s_axi_renkon_ID_WIDTH-1:0]      s_axi_renkon_rid;
  wire [C_s_axi_renkon_DATA_WIDTH-1:0]    s_axi_renkon_rdata;
  wire [1:0]                              s_axi_renkon_rresp;
  wire                                    s_axi_renkon_rlast;
  wire [C_s_axi_renkon_RUSER_WIDTH-1:0]   s_axi_renkon_ruser;
  wire                                    s_axi_renkon_rvalid;
  reg                                     s_axi_renkon_rready;

  // Ports of Axi Slave Bus Interface s_axi_gobou
  reg                                   s_axi_gobou_aclk;
  reg                                   s_axi_gobou_aresetn;
  reg  [C_s_axi_gobou_ID_WIDTH-1:0]     s_axi_gobou_awid;
  reg  [C_s_axi_gobou_ADDR_WIDTH-1:0]   s_axi_gobou_awaddr;
  reg  [7:0]                            s_axi_gobou_awlen;
  reg  [2:0]                            s_axi_gobou_awsize;
  reg  [1:0]                            s_axi_gobou_awburst;
  reg                                   s_axi_gobou_awlock;
  reg  [3:0]                            s_axi_gobou_awcache;
  reg  [2:0]                            s_axi_gobou_awprot;
  reg  [3:0]                            s_axi_gobou_awqos;
  reg  [3:0]                            s_axi_gobou_awregion;
  reg  [C_s_axi_gobou_AWUSER_WIDTH-1:0] s_axi_gobou_awuser;
  reg                                   s_axi_gobou_awvalid;
  wire                                  s_axi_gobou_awready;
  reg  [C_s_axi_gobou_DATA_WIDTH-1:0]   s_axi_gobou_wdata;
  reg  [C_s_axi_gobou_DATA_WIDTH/8-1:0] s_axi_gobou_wstrb;
  reg                                   s_axi_gobou_wlast;
  reg  [C_s_axi_gobou_WUSER_WIDTH-1:0]  s_axi_gobou_wuser;
  reg                                   s_axi_gobou_wvalid;
  wire                                  s_axi_gobou_wready;
  wire [C_s_axi_gobou_ID_WIDTH-1:0]     s_axi_gobou_bid;
  wire [1:0]                            s_axi_gobou_bresp;
  wire [C_s_axi_gobou_BUSER_WIDTH-1:0]  s_axi_gobou_buser;
  wire                                  s_axi_gobou_bvalid;
  reg                                   s_axi_gobou_bready;
  reg  [C_s_axi_gobou_ID_WIDTH-1:0]     s_axi_gobou_arid;
  reg  [C_s_axi_gobou_ADDR_WIDTH-1:0]   s_axi_gobou_araddr;
  reg  [7:0]                            s_axi_gobou_arlen;
  reg  [2:0]                            s_axi_gobou_arsize;
  reg  [1:0]                            s_axi_gobou_arburst;
  reg                                   s_axi_gobou_arlock;
  reg  [3:0]                            s_axi_gobou_arcache;
  reg  [2:0]                            s_axi_gobou_arprot;
  reg  [3:0]                            s_axi_gobou_arqos;
  reg  [3:0]                            s_axi_gobou_arregion;
  reg  [C_s_axi_gobou_ARUSER_WIDTH-1:0] s_axi_gobou_aruser;
  reg                                   s_axi_gobou_arvalid;
  wire                                  s_axi_gobou_arready;
  wire [C_s_axi_gobou_ID_WIDTH-1:0]     s_axi_gobou_rid;
  wire [C_s_axi_gobou_DATA_WIDTH-1:0]   s_axi_gobou_rdata;
  wire [1:0]                            s_axi_gobou_rresp;
  wire                                  s_axi_gobou_rlast;
  wire [C_s_axi_gobou_RUSER_WIDTH-1:0]  s_axi_gobou_ruser;
  wire                                  s_axi_gobou_rvalid;
  reg                                   s_axi_gobou_rready;

  kinpira_ddr dut(.*);

  // clock
  initial begin
    clk = 0;
    forever
      #(STEP/2) clk = ~clk;
  end

  assign s_axi_params_aclk = clk,
         s_axi_renkon_aclk = clk,
         s_axi_gobou_aclk  = clk,
         m_axi_image_aclk  = clk;

  assign s_axi_params_aresetn = xrst,
         s_axi_renkon_aresetn = xrst,
         s_axi_gobou_aresetn  = xrst,
         m_axi_image_aresetn  = xrst;

  //flow
  initial begin
    xrst = 0;
    #(STEP);

    xrst = 1;
    #(STEP);

    #(10*STEP);
    $finish();
  end

  //display
  initial begin
    $display("clk: |");
    forever begin
      #(STEP/2-1);
      $display(
        "%d: ", $time/STEP,
        "| ",

        "|"
      );
      #(STEP/2+1);
    end
  end

endmodule
