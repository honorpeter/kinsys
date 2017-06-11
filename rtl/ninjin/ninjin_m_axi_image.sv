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
  , parameter TOTAL_LEN     = 12
  )
  ( input                   clk
  , input                   xrst
  , input                   req
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
  , input [DWIDTH-1:0]      ddr_base

  , output                    ack
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
  );

  localparam TXN_NUM       = clogb2(BURST_LEN-1);
  // Total Data Amount (in byte: 2^12 byte -> 2^12 / (BURST_LEN*DWIDTH/8) req)
  localparam NO_BURSTS_REQ = TOTAL_LEN - clogb2(BURST_LEN*DWIDTH/8-1);

  wire                  req_pulse;
  wire                  s_write_end;
  wire                  s_read_end;
  wire                  s_comp_end;
  wire                  err_wresp;
  wire                  err_rresp;
  wire                  err_diff;
  wire                  wnext;
  wire                  rnext;
  wire [TXN_NUM+2-1:0]  burst_size;

  enum reg [2-1:0] {
    S_IDLE, S_WRITE, S_READ, S_COMP
  } r_state;
  reg                     r_req;
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
  reg [NO_BURSTS_REQ:0]   r_write_burst_cnt;
  reg [NO_BURSTS_REQ:0]   r_read_burst_cnt;
  reg [TXN_NUM:0]         r_write_idx;
  reg [TXN_NUM:0]         r_read_idx;
  reg                     r_write_single_burst;
  reg                     r_read_single_burst;
  reg                     r_write_active;
  reg                     r_read_active;
  reg [DWIDTH-1:0]        r_exp_rdata;

//==========================================================
// core control
//==========================================================

  assign req_pulse = req && !r_req;

  assign s_write_end = bvalid && r_bready && r_write_burst_cnt[NO_BURSTS_REQ];
  assign s_read_end  = rvalid && r_rready && r_read_idx == BURST_LEN - 1
                    && r_read_burst_cnt[NO_BURSTS_REQ];
  assign s_comp_end  = r_state == S_COMP;

  assign burst_size = BURST_LEN * DWIDTH/8;

  always @(posedge clk)
    if (!xrst)
      r_req <= 0;
    else
      r_req <= req;

  always @(posedge clk)
    if (!xrst) begin
      r_state <= S_IDLE;
      r_write_single_burst <= 0;
      r_read_single_burst  <= 0;
    end
    else
      case (r_state)
        S_IDLE:
          if (req_pulse)
            r_state <= S_WRITE;

        S_WRITE:
          if (s_write_end)
            r_state <= S_READ;
          else if (!r_awvalid && !r_write_single_burst && !r_write_active)
            r_write_single_burst <= 1;
          else
            r_write_single_burst <= 0;

        S_READ:
          if (s_read_end)
            r_state <= S_COMP;
          else if (!r_arvalid && !r_read_active && !r_read_single_burst)
            r_read_single_burst <= 1;
          else
            r_read_single_burst <= 0;

        S_COMP:
          if (s_comp_end)
            r_state <= S_IDLE;

        default:
          r_state <= S_IDLE;
      endcase

  always @(posedge clk)
    if (!xrst)
      r_write_active <= 0;
    else if (req_pulse)
      r_write_active <= 0;
    else if (r_write_single_burst)
      r_write_active <= 1;
    else if (bvalid && r_bready)
      r_write_active <= 0;

  always @(posedge clk)
    if (!xrst)
      r_read_active <= 0;
    else if (req_pulse)
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
    else if (req_pulse)
      r_awvalid <= 0;
    else if (!r_awvalid && r_write_single_burst)
      r_awvalid <= 1;
    else if (awready && r_awvalid)
      r_awvalid <= 0;

  always @(posedge clk)
    if (!xrst)
      r_awaddr <= 0;
    else if (req_pulse)
      r_awaddr <= ddr_base;
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
    else if (req_pulse)
      r_wvalid <= 0;
    else if (!r_wvalid && r_write_single_burst)
      r_wvalid <= 1;
    else if (wnext && r_wlast)
      r_wvalid <= 0;

  always @(posedge clk)
    if (!xrst)
      r_wdata <= 0;
    else if (req_pulse)
      r_wdata <= 0;
    else if (wnext)
      r_wdata <= r_wdata + 1;

  always @(posedge clk)
    if (!xrst)
      r_wlast <= 0;
    else if (req_pulse)
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
    else if (req_pulse || r_write_single_burst)
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
    else if (req_pulse)
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
    else if (req_pulse)
      r_arvalid <= 0;
    else if (!r_arvalid && r_read_single_burst)
      r_arvalid <= 1;
    else if (arready && r_arvalid)
      r_arvalid <= 0;

  always @(posedge clk)
    if (!xrst)
      r_araddr <= 0;
    else if (req_pulse)
      r_araddr <= ddr_base;
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
    else if (req_pulse)
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
    else if (req_pulse || r_read_single_burst)
      r_read_idx <= 0;
    else if (rnext && r_read_idx != BURST_LEN - 1)
      r_read_idx <= r_read_idx + 1;

//==========================================================
// memory control
//==========================================================

  assign ack = r_ack;
  assign err = r_err;

  assign err_diff = rnext && rdata != r_exp_rdata;

  always @(posedge clk)
    if (!xrst)
      r_ack <= 0;
    else if (req_pulse)
      r_ack <= 0;
    else if (s_comp_end)
      r_ack <= 1;

  always @(posedge clk)
    if (!xrst)
      r_err <= 0;
    else if (req_pulse)
      r_err <= 0;
    else if (err_diff || err_wresp || err_rresp)
      r_err <= {err_diff, err_wresp, err_rresp, 1'b1};

  always @(posedge clk)
    if (!xrst)
      r_exp_rdata <= 0;
    else if (rvalid && r_rready)
      r_exp_rdata <= r_exp_rdata + 1;

  always @(posedge clk)
    if (!xrst)
      r_write_burst_cnt <= 0;
    else if (req_pulse)
      r_write_burst_cnt <= 0;
    else if (awready && r_awvalid) begin
      if (r_write_burst_cnt[NO_BURSTS_REQ] == 1'b0)
        r_write_burst_cnt <= r_write_burst_cnt + DWIDTH/8;
    end

  always @(posedge clk)
    if (!xrst)
      r_read_burst_cnt <= 0;
    else if (req_pulse)
      r_read_burst_cnt <= 0;
    else if (arready && r_arvalid) begin
      if (r_read_burst_cnt[NO_BURSTS_REQ] == 1'b0)
        r_read_burst_cnt <= r_read_burst_cnt + DWIDTH/8;
    end

endmodule
