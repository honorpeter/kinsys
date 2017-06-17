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
  , input [DWIDTH-1:0]      ddr_wdata

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
  , output [MEMSIZE-1:0]      ddr_addr
  , output [DWIDTH-1:0]       ddr_rdata
  );

  localparam TXN_NUM       = clogb2(BURST_LEN-1);

  wire                  we_pulse;
  wire                  re_pulse;
  wire                  s_write_end;
  wire                  s_read_end;
  wire                  err_wresp;
  wire                  err_rresp;
  wire                  wnext;
  wire                  rnext;
  wire [TXN_NUM+2-1:0]  burst_size;

  enum reg [2-1:0] {
    S_IDLE, S_WRITE, S_READ
  } r_state;
  reg                     r_we;
  reg                     r_re;
  reg                     r_ack;
  reg [3:0]               r_err;
  reg [ID_WIDTH-1:0]      r_awid;
  reg [DWIDTH-1:0]        r_awaddr;
  reg [7:0]               r_awlen;
  reg [2:0]               r_awsize;
  reg [1:0]               r_awburst;
  reg                     r_awlock;
  reg [3:0]               r_awcache;
  reg [2:0]               r_awprot;
  reg [3:0]               r_awqos;
  reg [AWUSER_WIDTH-1:0]  r_awuser;
  reg                     r_awvalid;
  reg [DWIDTH-1:0]        r_wdata;
  reg [DWIDTH/8-1:0]      r_wstrb;
  reg                     r_wlast;
  reg [WUSER_WIDTH-1:0]   r_wuser;
  reg                     r_wvalid;
  reg                     r_bready;
  reg [ID_WIDTH-1:0]      r_arid;
  reg [DWIDTH-1:0]        r_araddr;
  reg [7:0]               r_arlen;
  reg [2:0]               r_arsize;
  reg [1:0]               r_arburst;
  reg                     r_arlock;
  reg [3:0]               r_arcache;
  reg [2:0]               r_arprot;
  reg [3:0]               r_arqos;
  reg [ARUSER_WIDTH-1:0]  r_aruser;
  reg                     r_arvalid;
  reg                     r_rready;
  reg [TXN_NUM:0]         r_write_idx;
  reg [TXN_NUM:0]         r_read_idx;
  reg                     r_write_single_burst;
  reg                     r_read_single_burst;
  reg                     r_write_active;
  reg                     r_read_active;

//==========================================================
// core control
//==========================================================

  assign we_pulse = ddr_we && !r_we;
  assign re_pulse = ddr_re && !r_re;

  assign s_write_end = bvalid && r_bready;
  assign s_read_end  = rvalid && r_rready && r_read_idx == BURST_LEN - 1;

  assign burst_size = BURST_LEN * DWIDTH/8;

  always @(posedge clk)
    if (!xrst) begin
      r_we <= 0;
      r_re <= 0;
    end
    else begin
      r_we <= ddr_we;
      r_re <= ddr_re;
    end

  always @(posedge clk)
    if (!xrst) begin
      r_state <= S_IDLE;
      r_write_single_burst <= 0;
      r_read_single_burst  <= 0;
    end
    else
      case (r_state)
        S_IDLE:
          if (we_pulse)
            r_state <= S_WRITE;
          else if (re_pulse)
            r_state <= S_READ;

        S_WRITE:
          if (s_write_end)
            r_state <= S_IDLE;
          else if (!r_awvalid && !r_write_single_burst && !r_write_active)
            r_write_single_burst <= 1;
          else
            r_write_single_burst <= 0;

        S_READ:
          if (s_read_end)
            r_state <= S_IDLE;
          else if (!r_arvalid && !r_read_active && !r_read_single_burst)
            r_read_single_burst <= 1;
          else
            r_read_single_burst <= 0;

        default:
          r_state <= S_IDLE;
      endcase

  always @(posedge clk)
    if (!xrst)
      r_write_active <= 0;
    else if (we_pulse)
      r_write_active <= 0;
    else if (r_write_single_burst)
      r_write_active <= 1;
    else if (bvalid && r_bready)
      r_write_active <= 0;

  always @(posedge clk)
    if (!xrst)
      r_read_active <= 0;
    else if (re_pulse)
      r_read_active <= 0;
    else if (r_read_single_burst)
      r_read_active <= 1;
    else if (rvalid && r_rready && rlast)
      r_read_active <= 0;

//==========================================================
// write address control
//==========================================================

  assign awvalid  = r_awvalid;
  assign awid     = 0;
  assign awaddr   = r_awaddr;
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
      r_awvalid <= 0;
    else if (we_pulse)
      r_awvalid <= 0;
    else if (!r_awvalid && r_write_single_burst)
      r_awvalid <= 1;
    else if (awready && r_awvalid)
      r_awvalid <= 0;

  always @(posedge clk)
    if (!xrst)
      r_awaddr <= 0;
    else if (we_pulse)
      r_awaddr <= ddr_addr;
    else if (awready && r_awvalid)
      r_awaddr <= r_awaddr + burst_size;

//==========================================================
// write data control
//==========================================================

  assign wvalid = r_wvalid;
  assign wdata  = r_wdata;
  assign wstrb  = {DWIDTH/8{1'b1}};
  assign wlast  = r_wlast;
  assign wuser  = 0;

  assign wnext = wready && r_wvalid;

  always @(posedge clk)
    if (!xrst)
      r_wvalid <= 0;
    else if (we_pulse)
      r_wvalid <= 0;
    else if (!r_wvalid && r_write_single_burst)
      r_wvalid <= 1;
    else if (wnext && r_wlast)
      r_wvalid <= 0;

  always @(posedge clk)
    if (!xrst)
      r_wdata <= 0;
    else if (we_pulse)
      r_wdata <= ddr_wdata;
    else if (wnext)
      // r_wdata <= r_wdata + 1;
      r_wdata <= ddr_wdata;

  always @(posedge clk)
    if (!xrst)
      r_wlast <= 0;
    else if (we_pulse)
      r_wlast <= 0;
    else if ((r_write_idx == BURST_LEN - 2 && BURST_LEN >= 2 && wnext)
              || BURST_LEN == 1)
      r_wlast <= 1;
    else if (wnext)
      r_wlast <= 0;
    else if (r_wlast && BURST_LEN == 1)
      r_wlast <= 0;

  always @(posedge clk)
    if (!xrst)
      r_write_idx <= 0;
    else if (we_pulse || r_write_single_burst)
      r_write_idx <= 0;
    else if (wnext && r_write_idx != BURST_LEN - 1)
      r_write_idx <= r_write_idx + 1;

//==========================================================
// write response control
//==========================================================

  assign bready = r_bready;

  assign err_wresp = r_bready && bvalid && bresp[1];

  always @(posedge clk)
    if (!xrst)
      r_bready <= 0;
    else if (we_pulse)
      r_bready <= 0;
    else if (bvalid && !r_bready)
      r_bready <= 1;
    else if (r_bready)
      r_bready <= 0;

//==========================================================
// read address control
//==========================================================

  assign arvalid  = r_arvalid;
  assign arid     = 0;
  assign araddr   = r_araddr;
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
      r_arvalid <= 0;
    else if (re_pulse)
      r_arvalid <= 0;
    else if (!r_arvalid && r_read_single_burst)
      r_arvalid <= 1;
    else if (arready && r_arvalid)
      r_arvalid <= 0;

  always @(posedge clk)
    if (!xrst)
      r_araddr <= 0;
    else if (re_pulse)
      r_araddr <= ddr_addr;
    else if (arready && r_arvalid)
      r_araddr <= r_araddr + burst_size;

//==========================================================
// read data control
//==========================================================

  assign rready = r_rready;

  assign rnext = rvalid && r_rready;

  assign err_rresp = r_rready && rvalid && rresp[1];

  always @(posedge clk)
    if (!xrst)
      r_rready <= 0;
    else if (re_pulse)
      r_rready <= 0;
    else if (rvalid) begin
      if (rlast && r_rready)
        r_rready <= 0;
      else
        r_rready <= 1;
    end

  always @(posedge clk)
    if (!xrst)
      r_read_idx <= 0;
    else if (re_pulse || r_read_single_burst)
      r_read_idx <= 0;
    else if (rnext && r_read_idx != BURST_LEN - 1)
      r_read_idx <= r_read_idx + 1;

//==========================================================
// memory control
//==========================================================

  assign err = r_err;

  assign ddr_rdata = rdata;

  always @(posedge clk)
    if (!xrst)
      r_err <= 0;
    else if (we_pulse || re_pulse)
      r_err <= 0;
    else if (err_wresp || err_rresp)
      r_err <= {err_wresp, err_rresp, 1'b1};

endmodule
