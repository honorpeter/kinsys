`include "ninjin.svh"

module ninjin_s_axi_image
 #( parameter DATA_WIDTH    = 32
  , parameter ADDR_WIDTH    = 12
  , parameter ID_WIDTH      = 12
  , parameter AWUSER_WIDTH  = 0
  , parameter ARUSER_WIDTH  = 0
  , parameter WUSER_WIDTH   = 0
  , parameter RUSER_WIDTH   = 0
  , parameter BUSER_WIDTH   = 0
  )
  ( input                     clk
  , input                     xrst
  , input [ID_WIDTH-1:0]      awid
  , input [ADDR_WIDTH-1:0]    awaddr
  , input [7:0]               awlen
  , input [2:0]               awsize
  , input [1:0]               awburst
  , input                     awlock
  , input [3:0]               awcache
  , input [2:0]               awprot
  , input [3:0]               awqos
  , input [3:0]               awregion
  , input [AWUSER_WIDTH-1:0]  awuser
  , input                     awvalid
  , input [DATA_WIDTH-1:0]    wdata
  , input [DATA_WIDTH/8-1:0]  wstrb
  , input                     wlast
  , input [WUSER_WIDTH-1:0]   wuser
  , input                     wvalid
  , input                     bready
  , input [ID_WIDTH-1:0]      arid
  , input [ADDR_WIDTH-1:0]    araddr
  , input [7:0]               arlen
  , input [2:0]               arsize
  , input [1:0]               arburst
  , input                     arlock
  , input [3:0]               arcache
  , input [2:0]               arprot
  , input [3:0]               arqos
  , input [3:0]               arregion
  , input [ARUSER_WIDTH-1:0]  aruser
  , input                     arvalid
  , input                     rready
  , input [DATA_WIDTH-1:0]    mem_rdata

  , output                    awready
  , output                    wready
  , output                    bvalid
  , output [ID_WIDTH-1:0]     bid
  , output [1:0]              bresp
  , output [BUSER_WIDTH-1:0]  buser
  , output                    arready
  , output                    rvalid
  , output [ID_WIDTH-1:0]     rid
  , output [DATA_WIDTH-1:0]   rdata
  , output [1:0]              rresp
  , output                    rlast
  , output [RUSER_WIDTH-1:0]  ruser
  , output                    mem_we
  , output [MEMSIZE-1:0]      mem_addr
  , output [DATA_WIDTH-1:0]   mem_wdata
  );

  wire                  aw_wrap_en;
  wire [DATA_WIDTH-1:0] aw_wrap_size;
  wire                  ar_wrap_en;
  wire [DATA_WIDTH-1:0] ar_wrap_size;

  reg                   r_awready;
  reg [ADDR_WIDTH-1:0]  r_awaddr;
  reg [7:0]             r_awlen;
  reg [7:0]             r_awlen_cnt;
  reg [1:0]             r_awburst;
  reg                   r_wready;
  reg [ID_WIDTH-1:0]    r_bid;
  reg [1:0]             r_bresp;
  reg [BUSER_WIDTH-1:0] r_buser;
  reg                   r_bvalid;
  reg                   r_arready;
  reg [ADDR_WIDTH-1:0]  r_araddr;
  reg [7:0]             r_arlen;
  reg [7:0]             r_arlen_cnt;
  reg [1:0]             r_arburst;
  reg [ID_WIDTH-1:0]    r_rid;
  reg [DATA_WIDTH-1:0]  r_rdata;
  reg [1:0]             r_rresp;
  reg                   r_rlast;
  reg [RUSER_WIDTH-1:0] r_ruser;
  reg                   r_rvalid;
  reg                   r_awv_issued;
  reg                   r_arv_issued;

  localparam NUM_MEM = 1;


//==========================================================
// write address control
//==========================================================

  assign awready = r_awready;

  always @(posedge clk)
    if (!xrst) begin
      r_awready    <= 0;
      r_awv_issued <= 0;
    end
    else
      if (!r_awready && awvalid && !r_awv_issued && !r_arv_issued) begin
        r_awready    <= 1;
        r_awv_issued <= 1;
      end
      else if (wlast && r_wready)
        r_awv_issued <= 0;
      else
        r_awready <= 0;

  always @(posedge clk)
    if (!xrst)
      r_awaddr <= 0;
    else
      if (!r_awready && awvalid && !r_awv_issued)
        r_awaddr <= awaddr[ADDR_WIDTH-1:0];
      else if (r_awlen_cnt <= r_awlen && r_wready && wvalid)
        case (r_awburst)
          2'b00:
            r_awaddr <= r_awaddr;

          2'b01: begin
            r_awaddr[ADDR_WIDTH-1:LSB]  <= r_awaddr[ADDR_WIDTH-1:LSB] + 1;
            r_awaddr[LSB-1:0]           <= {LSB{1'b0}};
          end

          2'b10:
            if (aw_wrap_en)
              r_awaddr <= r_awaddr - aw_wrap_size;
            else begin
              r_awaddr[ADDR_WIDTH-1:LSB]  <= r_awaddr[ADDR_WIDTH-1:LSB] + 1;
              r_awaddr[LSB-1:0]           <= {LSB{1'b0}};
            end

          default:
            r_awaddr <= r_awaddr[ADDR_WIDTH-1:LSB] + 1;
        endcase

  always @(posedge clk)
    if (!xrst) begin
      r_awlen     <= 0;
      r_awlen_cnt <= 0;
    end
    else if (!r_awready && awvalid && !r_awv_issued) begin
      r_awlen     <= awlen;
      r_awlen_cnt <= 0;
    end
    else if (r_awlen_cnt <= r_awlen && r_wready && wvalid)
      r_awlen_cnt <= r_awlen_cnt + 1;

  always @(posedge clk)
    if (!xrst)
      r_awburst <= 0;
    else if (!r_awready && awvalid && !r_awv_issued)
      r_awburst <= awburst;

//==========================================================
// write data control
//==========================================================

  assign wready = r_wready;

  always @(posedge clk)
    if (!xrst)
      r_wready <= 0;
    else if (!r_wready && wvalid && r_awv_issued)
      r_wready <= 1;
    else if (wlast && r_wready)
      r_wready <= 0;

//==========================================================
// write response control
//==========================================================

  assign bvalid = r_bvalid;
  assign buser  = r_buser;
  assign bresp  = r_bresp;
  assign bid    = awid;

  always @(posedge clk)
    if (!xrst)
      r_bvalid <= 0;
    else if (r_awv_issued && r_wready && wvalid && !r_bvalid && wlast)
      r_bvalid <= 1;
    else if (bready && r_bvalid)
      r_bvalid <= 0;

  always @(posedge clk)
    if (!xrst)
      r_buser <= 0;
    else
      r_buser <= 0;

  always @(posedge clk)
    if (!xrst)
      r_bresp <= 0;
    else if (r_awv_issued && r_wready && wvalid && !r_bvalid && wlast)
      r_bresp <= 0;

//==========================================================
// read address control
//==========================================================

  assign arready = r_arready;

  always @(posedge clk)
    if (!xrst) begin
      r_arready    <= 0;
      r_arv_issued <= 0;
    end
    else if (!r_arready && arvalid && !r_awv_issued && !r_arv_issued) begin
      r_arready    <= 1;
      r_arv_issued <= 1;
    end
    else if (r_rvalid && rready && r_arlen_cnt == r_arlen)
      r_arv_issued <= 0;
    else
      r_arready <= 0;

  always @(posedge clk)
    if (!xrst)
      r_araddr <= 0;
    else
      if (!r_arready && arvalid & !r_arv_issued)
        r_araddr <= araddr[ADDR_WIDTH-1:0];
      else if (r_arlen_cnt <= r_arlen && r_rvalid && rready)
        case (r_arburst)
          2'b00:
            r_araddr <= r_araddr;

          2'b01: begin
            r_araddr[ADDR_WIDTH-1:LSB]  <= r_araddr[ADDR_WIDTH-1:LSB] + 1;
            r_araddr[LSB-1:0]           <= {LSB{1'b0}};
          end

          2'b10:
            if (ar_wrap_en)
              r_araddr <= r_araddr - ar_wrap_size;
            else begin
              r_araddr[ADDR_WIDTH-1:LSB]  <= r_araddr[ADDR_WIDTH-1:LSB] + 1;
              r_araddr[LSB-1:0]           <= {LSB{1'b0}};
            end

          default:
            r_araddr <= r_araddr[ADDR_WIDTH-1:LSB] + 1;
        endcase

  always @(posedge clk)
    if (!xrst) begin
      r_arlen     <= 0;
      r_arlen_cnt <= 0;
    end
    else if (!r_arready && arvalid && !r_arv_issued) begin
      r_arlen     <= arlen;
      r_arlen_cnt <= 0;
    end
    else if (r_arlen_cnt <= r_arlen && r_rvalid && rready)
      r_arlen_cnt <= r_arlen_cnt + 1;

  always @(posedge clk)
    if (!xrst)
      r_arburst <= 0;
    else if (!r_arready && arvalid && !r_arv_issued)
      r_arburst <= arburst;

//==========================================================
// read data control
//==========================================================

  assign rvalid = r_rvalid;
  // assign rdata  = r_rdata;
  assign rlast  = r_rlast;
  assign ruser  = r_ruser;
  assign rresp  = r_rresp;
  assign rid    = arid;

  always @(posedge clk)
    if (!xrst)
      r_rvalid <= 0;
    else if (r_arv_issued && !r_rvalid)
      r_rvalid <= 1;
    else if (r_rvalid && rready)
      r_rvalid <= 0;

  // always @(posedge clk)
  //   if (!xrst)
  //     r_rdata <= 0;
  //   else if (rvalid)
  //     r_rdata <= mem_rdata;
  //   else
  //     r_rdata <= 0;

  always @(posedge clk)
    if (!xrst)
      r_rlast <= 0;
    else if (!r_arready && arvalid && !r_arv_issued)
      r_rlast <= 0;
    else if (r_arlen_cnt <= r_arlen && r_rvalid && rready)
      r_rlast <= 0;
    else if (r_arlen_cnt == r_arlen && !rlast && r_arv_issued)
      r_rlast <= 1;
    else if (rready)
      r_rlast <= 0;

  always @(posedge clk)
    if (!xrst)
      r_ruser <= 0;
    else
      r_ruser <= 0;

  always @(posedge clk)
    if (!xrst)
      r_rresp <= 0;
    else if (r_arv_issued && !r_rvalid)
      r_rresp <= 0;

//==========================================================
// memory control
//==========================================================

  assign mem_we    = r_wready && wvalid;
  assign mem_addr  = r_arv_issued ? r_araddr[ADDR_WIDTH-1:LSB]
                   : r_awv_issued ? r_awaddr[ADDR_WIDTH-1:LSB]
                   : 0;
  assign mem_wdata = wdata;
  assign rdata     = mem_rdata;

endmodule

