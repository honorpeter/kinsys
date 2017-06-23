`include "ninjin.svh"

module ninjin_s_axi_gobou
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
  , output [ADDR_WIDTH-LSB-1:0] mem_addr
  , output [DATA_WIDTH-1:0]   mem_wdata
  );

  wire                  aw_wrap_en;
  wire [DATA_WIDTH-1:0] aw_wrap_size;
  wire                  ar_wrap_en;
  wire [DATA_WIDTH-1:0] ar_wrap_size;

  reg                   awready$;
  reg [ADDR_WIDTH-1:0]  awaddr$;
  reg [7:0]             awlen$;
  reg [7:0]             awlen_cnt$;
  reg [1:0]             awburst$;
  reg                   wready$;
  reg [ID_WIDTH-1:0]    bid$;
  reg [1:0]             bresp$;
  reg [BUSER_WIDTH-1:0] buser$;
  reg                   bvalid$;
  reg                   arready$;
  reg [ADDR_WIDTH-1:0]  araddr$;
  reg [7:0]             arlen$;
  reg [7:0]             arlen_cnt$;
  reg [1:0]             arburst$;
  reg [ID_WIDTH-1:0]    rid$;
  reg [DATA_WIDTH-1:0]  rdata$;
  reg [1:0]             rresp$;
  reg                   rlast$;
  reg [RUSER_WIDTH-1:0] ruser$;
  reg                   rvalid$;
  reg                   awv_issued$;
  reg                   arv_issued$;

  localparam NUM_MEM = 1;


//==========================================================
// write address control
//==========================================================

  assign awready = awready$;

  assign aw_wrap_size   = DATA_WIDTH/8 * awlen$;
  assign aw_wrap_en     = (awaddr$ & aw_wrap_size) == aw_wrap_size
                        ? 1'b1
                        : 1'b0;

  always @(posedge clk)
    if (!xrst) begin
      awready$    <= 0;
      awv_issued$ <= 0;
    end
    else
      if (!awready$ && awvalid && !awv_issued$ && !arv_issued$) begin
        awready$    <= 1;
        awv_issued$ <= 1;
      end
      else if (wlast && wready$)
        awv_issued$ <= 0;
      else
        awready$ <= 0;

  always @(posedge clk)
    if (!xrst)
      awaddr$ <= 0;
    else
      if (!awready$ && awvalid && !awv_issued$)
        awaddr$ <= awaddr[ADDR_WIDTH-1:0];
      else if (awlen_cnt$ <= awlen$ && wready$ && wvalid)
        case (awburst$)
          2'b00:
            awaddr$ <= awaddr$;

          2'b01: begin
            awaddr$[ADDR_WIDTH-1:LSB]  <= awaddr$[ADDR_WIDTH-1:LSB] + 1;
            awaddr$[LSB-1:0]           <= {LSB{1'b0}};
          end

          2'b10:
            if (aw_wrap_en)
              awaddr$ <= awaddr$ - aw_wrap_size;
            else begin
              awaddr$[ADDR_WIDTH-1:LSB]  <= awaddr$[ADDR_WIDTH-1:LSB] + 1;
              awaddr$[LSB-1:0]           <= {LSB{1'b0}};
            end

          default:
            awaddr$ <= awaddr$[ADDR_WIDTH-1:LSB] + 1;
        endcase

  always @(posedge clk)
    if (!xrst) begin
      awlen$     <= 0;
      awlen_cnt$ <= 0;
    end
    else if (!awready$ && awvalid && !awv_issued$) begin
      awlen$     <= awlen;
      awlen_cnt$ <= 0;
    end
    else if (awlen_cnt$ <= awlen$ && wready$ && wvalid)
      awlen_cnt$ <= awlen_cnt$ + 1;

  always @(posedge clk)
    if (!xrst)
      awburst$ <= 0;
    else if (!awready$ && awvalid && !awv_issued$)
      awburst$ <= awburst;

//==========================================================
// write data control
//==========================================================

  assign wready = wready$;

  always @(posedge clk)
    if (!xrst)
      wready$ <= 0;
    else if (!wready$ && wvalid && awv_issued$)
      wready$ <= 1;
    else if (wlast && wready$)
      wready$ <= 0;

//==========================================================
// write response control
//==========================================================

  assign bvalid = bvalid$;
  assign buser  = buser$;
  assign bresp  = bresp$;
  assign bid    = awid;

  always @(posedge clk)
    if (!xrst)
      bvalid$ <= 0;
    else if (awv_issued$ && wready$ && wvalid && !bvalid$ && wlast)
      bvalid$ <= 1;
    else if (bready && bvalid$)
      bvalid$ <= 0;

  always @(posedge clk)
    if (!xrst)
      buser$ <= 0;
    else
      buser$ <= 0;

  always @(posedge clk)
    if (!xrst)
      bresp$ <= 0;
    else if (awv_issued$ && wready$ && wvalid && !bvalid$ && wlast)
      bresp$ <= 0;

//==========================================================
// read address control
//==========================================================

  assign arready = arready$;

  assign ar_wrap_size   = DATA_WIDTH/8 * arlen$;
  assign ar_wrap_en     = (araddr$ & ar_wrap_size) == ar_wrap_size
                        ? 1'b1
                        : 1'b0;

  always @(posedge clk)
    if (!xrst) begin
      arready$    <= 0;
      arv_issued$ <= 0;
    end
    else if (!arready$ && arvalid && !awv_issued$ && !arv_issued$) begin
      arready$    <= 1;
      arv_issued$ <= 1;
    end
    else if (rvalid$ && rready && arlen_cnt$ == arlen$)
      arv_issued$ <= 0;
    else
      arready$ <= 0;

  always @(posedge clk)
    if (!xrst)
      araddr$ <= 0;
    else
      if (!arready$ && arvalid & !arv_issued$)
        araddr$ <= araddr[ADDR_WIDTH-1:0];
      else if (arlen_cnt$ <= arlen$ && rvalid$ && rready)
        case (arburst$)
          2'b00:
            araddr$ <= araddr$;

          2'b01: begin
            araddr$[ADDR_WIDTH-1:LSB]  <= araddr$[ADDR_WIDTH-1:LSB] + 1;
            araddr$[LSB-1:0]           <= {LSB{1'b0}};
          end

          2'b10:
            if (ar_wrap_en)
              araddr$ <= araddr$ - ar_wrap_size;
            else begin
              araddr$[ADDR_WIDTH-1:LSB]  <= araddr$[ADDR_WIDTH-1:LSB] + 1;
              araddr$[LSB-1:0]           <= {LSB{1'b0}};
            end

          default:
            araddr$ <= araddr$[ADDR_WIDTH-1:LSB] + 1;
        endcase

  always @(posedge clk)
    if (!xrst) begin
      arlen$     <= 0;
      arlen_cnt$ <= 0;
    end
    else if (!arready$ && arvalid && !arv_issued$) begin
      arlen$     <= arlen;
      arlen_cnt$ <= 0;
    end
    else if (arlen_cnt$ <= arlen$ && rvalid$ && rready)
      arlen_cnt$ <= arlen_cnt$ + 1;

  always @(posedge clk)
    if (!xrst)
      arburst$ <= 0;
    else if (!arready$ && arvalid && !arv_issued$)
      arburst$ <= arburst;

//==========================================================
// read data control
//==========================================================

  assign rvalid = rvalid$;
  // assign rdata  = rdata$;
  assign rlast  = rlast$;
  assign ruser  = ruser$;
  assign rresp  = rresp$;
  assign rid    = arid;

  always @(posedge clk)
    if (!xrst)
      rvalid$ <= 0;
    else if (arv_issued$ && !rvalid$)
      rvalid$ <= 1;
    else if (rvalid$ && rready)
      rvalid$ <= 0;

  // always @(posedge clk)
  //   if (!xrst)
  //     rdata$ <= 0;
  //   else if (rvalid)
  //     rdata$ <= mem_rdata;
  //   else
  //     rdata$ <= 0;

  always @(posedge clk)
    if (!xrst)
      rlast$ <= 0;
    else if (!arready$ && arvalid && !arv_issued$)
      rlast$ <= 0;
    else if (arlen_cnt$ <= arlen$ && rvalid$ && rready)
      rlast$ <= 0;
    else if (arlen_cnt$ == arlen$ && !rlast && arv_issued$)
      rlast$ <= 1;
    else if (rready)
      rlast$ <= 0;

  always @(posedge clk)
    if (!xrst)
      ruser$ <= 0;
    else
      ruser$ <= 0;

  always @(posedge clk)
    if (!xrst)
      rresp$ <= 0;
    else if (arv_issued$ && !rvalid$)
      rresp$ <= 0;

//==========================================================
// memory control
//==========================================================

  assign mem_we    = wready$ && wvalid;
  assign mem_addr  = arv_issued$ ? araddr$[ADDR_WIDTH-1:LSB]
                   : awv_issued$ ? awaddr$[ADDR_WIDTH-1:LSB]
                   : 0;
  assign mem_wdata = wdata;
  assign rdata     = mem_rdata;

endmodule

