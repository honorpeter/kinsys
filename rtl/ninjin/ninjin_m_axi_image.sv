`include "ninjin.svh"

module ninjin_m_axi_image
 #( parameter BURST_LEN     = 256
  , parameter DATA_WIDTH    = 32
  , parameter ADDR_WIDTH    = 12
  , parameter ID_WIDTH      = 12
  , parameter AWUSER_WIDTH  = 0
  , parameter ARUSER_WIDTH  = 0
  , parameter WUSER_WIDTH   = 0
  , parameter RUSER_WIDTH   = 0
  , parameter BUSER_WIDTH   = 0
  )
  ( input                   clk
  , input                   xrst
  , input                   awready
  , input                   wready
  , input [ID_WIDTH-1:0]    bid
  , input [1:0]             bresp
  , input [BUSER_WIDTH-1:0] buser
  , input                   bvalid
  , input                   arready
  , input [ID_WIDTH-1:0]    rid
  , input [DWIDTH-1:0]      rdata
  , input [1:0]             rresp
  , input                   rlast
  , input [RUSER_WIDTH-1:0] ruser
  , input                   rvalid
  , input                   ddr_req
  , input                   ddr_mode
  , input [MEMSIZE-1:0]     ddr_base
  , input [DWIDTH-1:0]      ddr_rdata

  , output [3:0]              err
  , output                    awvalid
  , output [ID_WIDTH-1:0]     awid
  , output [DWIDTH-1:0]       awaddr
  , output [7:0]              awlen
  , output [2:0]              awsize
  , output [1:0]              awburst
  , output                    awlock
  , output [3:0]              awcache
  , output [2:0]              awprot
  , output [3:0]              awqos
  , output [AWUSER_WIDTH-1:0] awuser
  , output                    wvalid
  , output [DWIDTH-1:0]       wdata
  , output [DWIDTH/8-1:0]     wstrb
  , output                    wlast
  , output [WUSER_WIDTH-1:0]  wuser
  , output                    bready
  , output                    arvalid
  , output [ID_WIDTH-1:0]     arid
  , output [DWIDTH-1:0]       araddr
  , output [7:0]              arlen
  , output [2:0]              arsize
  , output [1:0]              arburst
  , output                    arlock
  , output [3:0]              arcache
  , output [2:0]              arprot
  , output [3:0]              arqos
  , output [ARUSER_WIDTH-1:0] aruser
  , output                    rready
  , output                    ddr_we
  , output [MEMSIZE-1:0]      ddr_waddr
  , output [DWIDTH-1:0]       ddr_wdata
  , output [MEMSIZE-1:0]      ddr_raddr
  );

  localparam TXN_NUM = clogb2(BURST_LEN-1);

  wire                    wreq_pulse;
  wire                    rreq_pulse;
  wire                    s_write_end;
  wire                    s_read_end;
  wire                    err_wresp;
  wire                    err_rresp;
  wire                    wnext;
  wire                    rnext;
  wire [TXN_NUM+LSB-1:0]  burst_size;

  enum reg [2-1:0] {
    S_IDLE, S_BUSY
  } state_write$, state_read$;
  reg                     wreq$;
  reg                     rreq$;
  reg                     ack$;
  reg [3:0]               err$;
  reg [ID_WIDTH-1:0]      awid$;
  reg [DWIDTH-1:0]        awaddr$;
  reg [7:0]               awlen$;
  reg [2:0]               awsize$;
  reg [1:0]               awburst$;
  reg                     awlock$;
  reg [3:0]               awcache$;
  reg [2:0]               awprot$;
  reg [3:0]               awqos$;
  reg [AWUSER_WIDTH-1:0]  awuser$;
  reg                     awvalid$;
  reg [DWIDTH-1:0]        wdata$;
  reg [DWIDTH/8-1:0]      wstrb$;
  reg                     wlast$;
  reg [WUSER_WIDTH-1:0]   wuser$;
  reg                     wvalid$;
  reg                     bready$;
  reg [ID_WIDTH-1:0]      arid$;
  reg [DWIDTH-1:0]        araddr$;
  reg [7:0]               arlen$;
  reg [2:0]               arsize$;
  reg [1:0]               arburst$;
  reg                     arlock$;
  reg [3:0]               arcache$;
  reg [2:0]               arprot$;
  reg [3:0]               arqos$;
  reg [ARUSER_WIDTH-1:0]  aruser$;
  reg                     arvalid$;
  reg                     rready$;
  reg [TXN_NUM:0]         write_idx$;
  reg [TXN_NUM:0]         rreqad_idx$;
  reg                     write_single_burst$;
  reg                     rreqad_single_burst$;
  reg                     write_active$;
  reg                     rreqad_active$;

//==========================================================
// core control
//==========================================================
// {{{

  assign req_pulse  = ddr_req && !req$;
  assign wreq_pulse = ddr_mode == DDR_WRITE && req_pulse;
  assign rreq_pulse = ddr_mode == DDR_READ  && req_pulse;

  assign s_write_end = bvalid && bready$;
  assign s_read_end  = rvalid && rready$ && rreqad_idx$ == BURST_LEN - 1;

  assign burst_size = BURST_LEN * DWIDTH/8;

  always @(posedge clk)
    if (!xrst)
      req$ <= 0;
    else
      req$ <= ddr_req;

  /*
   * Read and write channel works independent each other.
   * They could be multiplexed for burst transaction.
   */
  always @(posedge clk)
    if (!xrst) begin
      state_write$ <= S_IDLE;
      write_single_burst$ <= 0;
    end
    else
      case (state_write$)
        S_IDLE:
          if (wreq_pulse)
            state_write$ <= S_BUSY;

        S_BUSY:
          if (s_write_end)
            state_write$ <= S_IDLE;
          else if (!awvalid$ && !write_single_burst$ && !write_active$)
            write_single_burst$ <= 1;
          else
            write_single_burst$ <= 0;

        default:
          state_write$ <= S_IDLE;
      endcase

  always @(posedge clk)
    if (!xrst) begin
      state_read$ <= S_IDLE;
      rreqad_single_burst$  <= 0;
    end
    else
      case (state_read$)
        S_IDLE:
          if (rreq_pulse)
            state_read$ <= S_BUSY;

        S_BUSY:
          if (s_read_end)
            state_read$ <= S_IDLE;
          else if (!arvalid$ && !rreqad_active$ && !rreqad_single_burst$)
            rreqad_single_burst$ <= 1;
          else
            rreqad_single_burst$ <= 0;

        default:
          state_read$ <= S_IDLE;
      endcase

  always @(posedge clk)
    if (!xrst)
      write_active$ <= 0;
    else if (wreq_pulse)
      write_active$ <= 0;
    else if (write_single_burst$)
      write_active$ <= 1;
    else if (bvalid && bready$)
      write_active$ <= 0;

  always @(posedge clk)
    if (!xrst)
      rreqad_active$ <= 0;
    else if (rreq_pulse)
      rreqad_active$ <= 0;
    else if (rreqad_single_burst$)
      rreqad_active$ <= 1;
    else if (rvalid && rready$ && rlast)
      rreqad_active$ <= 0;

// }}}
//==========================================================
// write address control
//==========================================================
// {{{

  assign awvalid  = awvalid$;
  assign awid     = 0;
  assign awaddr   = awaddr$;
  assign awlen    = BURST_LEN - 1;
  assign awsize   = clogb2(DWIDTH/8 - 1);
  assign awburst  = 2'b01;
  assign awlock   = 1'b0;
  assign awcache  = 4'b0010;
  assign awprot   = 3'h0;
  assign awqos    = 4'h0;
  assign awuser   = 1;

  always @(posedge clk)
    if (!xrst)
      awvalid$ <= 0;
    else if (wreq_pulse)
      awvalid$ <= 0;
    else if (!awvalid$ && write_single_burst$)
      awvalid$ <= 1;
    else if (awready && awvalid$)
      awvalid$ <= 0;

  always @(posedge clk)
    if (!xrst)
      awaddr$ <= 0;
    else if (wreq_pulse)
      awaddr$ <= ddr_waddr;
    else if (awready && awvalid$)
      awaddr$ <= awaddr$ + burst_size;

// }}}
//==========================================================
// write data control
//==========================================================
// {{{

  assign wvalid = wvalid$;
  assign wdata  = wdata$;
  assign wstrb  = {DWIDTH/8{1'b1}};
  assign wlast  = wlast$;
  assign wuser  = 0;

  assign wnext = wready && wvalid$;

  always @(posedge clk)
    if (!xrst)
      wvalid$ <= 0;
    else if (wreq_pulse)
      wvalid$ <= 0;
    else if (!wvalid$ && write_single_burst$)
      wvalid$ <= 1;
    else if (wnext && wlast$)
      wvalid$ <= 0;

  // input ddr_rdata have been interpreted as write data for host memory.
  always @(posedge clk)
    if (!xrst)
      wdata$ <= 0;
    else if (wreq_pulse)
      wdata$ <= ddr_rdata;
    else if (wnext)
      wdata$ <= ddr_rdata;

  always @(posedge clk)
    if (!xrst)
      wlast$ <= 0;
    else if (wreq_pulse)
      wlast$ <= 0;
    else if ((write_idx$ == BURST_LEN - 2 && BURST_LEN >= 2 && wnext)
              || BURST_LEN == 1)
      wlast$ <= 1;
    else if (wnext)
      wlast$ <= 0;
    else if (wlast$ && BURST_LEN == 1)
      wlast$ <= 0;

  always @(posedge clk)
    else if (wreq_pulse || write_single_burst$)
      write_idx$ <= 0;
    else if (wnext && write_idx$ != BURST_LEN - 1)
      write_idx$ <= write_idx$ + 1;

// }}}
//==========================================================
// write response control
//==========================================================
// {{{

  assign bready = bready$;

  assign err_wresp = bready$ && bvalid && bresp[1];

  always @(posedge clk)
    if (!xrst)
      bready$ <= 0;
    else if (wreq_pulse)
      bready$ <= 0;
    else if (bvalid && !bready$)
      bready$ <= 1;
    else if (bready$)
      bready$ <= 0;

// }}}
//==========================================================
// read address control
//==========================================================
// {{{

  assign arvalid  = arvalid$;
  assign arid     = 0;
  assign araddr   = araddr$;
  assign arlen    = BURST_LEN - 1;
  assign arsize   = clogb2(DWIDTH/8 - 1);
  assign arburst  = 2'b01;
  assign arlock   = 1'b0;
  assign arcache  = 4'b0010;
  assign arprot   = 3'h0;
  assign arqos    = 4'h0;
  assign aruser   = 1;

  always @(posedge clk)
    if (!xrst)
      arvalid$ <= 0;
    else if (rreq_pulse)
      arvalid$ <= 0;
    else if (!arvalid$ && rreqad_single_burst$)
      arvalid$ <= 1;
    else if (arready && arvalid$)
      arvalid$ <= 0;

  always @(posedge clk)
    if (!xrst)
      araddr$ <= 0;
    else if (rreq_pulse)
      araddr$ <= ddr_raddr;
    else if (arready && arvalid$)
      araddr$ <= araddr$ + burst_size;

// }}}
//==========================================================
// read data control
//==========================================================
// {{{

  assign rready = rready$;

  assign rnext = rvalid && rready$;

  assign err_rresp = rready$ && rvalid && rresp[1];

  always @(posedge clk)
    if (!xrst)
      rready$ <= 0;
    else if (rreq_pulse)
      rready$ <= 0;
    else if (rvalid) begin
      if (rlast && rready$)
        rready$ <= 0;
      else
        rready$ <= 1;
    end

  always @(posedge clk)
    if (!xrst)
      rreqad_idx$ <= 0;
    else if (rreq_pulse || rreqad_single_burst$)
      rreqad_idx$ <= 0;
    else if (rnext && rreqad_idx$ != BURST_LEN - 1)
      rreqad_idx$ <= rreqad_idx$ + 1;

// }}}
//==========================================================
// memory control
//==========================================================
// {{{

  assign err = err$;

  // read data is emitted as write data for target ram region.
  assign ddr_wdata = rdata;

  always @(posedge clk)
    if (!xrst)
      err$ <= 0;
    else if (wreq_pulse || rreq_pulse)
      err$ <= 0;
    else if (err_wresp || err_rresp)
      err$ <= {err_wresp, err_rresp, 1'b1};

// }}}
endmodule
