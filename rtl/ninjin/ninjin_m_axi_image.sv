`include "ninjin.svh"

module ninjin_m_axi_image
 #( parameter BURST_MAX     = 256
  , parameter DATA_WIDTH    = BWIDTH
  , parameter ADDR_WIDTH    = BWIDTH
  , parameter ID_WIDTH      = 12
  , parameter AWUSER_WIDTH  = 0
  , parameter ARUSER_WIDTH  = 0
  , parameter WUSER_WIDTH   = 0
  , parameter RUSER_WIDTH   = 0
  , parameter BUSER_WIDTH   = 0
  )
  ( input                     clk
  , input                     xrst
  , input                     awready
  , input                     wready
  , input [ID_WIDTH-1:0]      bid
  , input [1:0]               bresp
  , input [BUSER_WIDTH-1:0]   buser
  , input                     bvalid
  , input                     arready
  , input [ID_WIDTH-1:0]      rid
  , input [DATA_WIDTH-1:0]    rdata
  , input [1:0]               rresp
  , input                     rlast
  , input [RUSER_WIDTH-1:0]   ruser
  , input                     rvalid
  , input                     ddr_req
  , input                     ddr_mode
  , input [WORDSIZE+LSB-1:0]  ddr_base
  , input [LWIDTH-1:0]        ddr_len
  , input [BWIDTH-1:0]        ddr_rdata

  , output [3:0]              err
  , output                    awvalid
  , output [ID_WIDTH-1:0]     awid
  , output [ADDR_WIDTH-1:0]   awaddr
  , output [7:0]              awlen
  , output [2:0]              awsize
  , output [1:0]              awburst
  , output                    awlock
  , output [3:0]              awcache
  , output [2:0]              awprot
  , output [3:0]              awqos
  , output [AWUSER_WIDTH-1:0] awuser
  , output                    wvalid
  , output [DATA_WIDTH-1:0]   wdata
  , output [DATA_WIDTH/8-1:0] wstrb
  , output                    wlast
  , output [WUSER_WIDTH-1:0]  wuser
  , output                    bready
  , output                    arvalid
  , output [ID_WIDTH-1:0]     arid
  , output [ADDR_WIDTH-1:0]   araddr
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
  , output [WORDSIZE-1:0]     ddr_waddr
  , output [BWIDTH-1:0]       ddr_wdata
  , output [WORDSIZE-1:0]     ddr_raddr
  );

  localparam TXN_NUM = clogb2(BURST_MAX-1);

  wire                    req_pulse;
  wire                    wreq_pulse;
  wire                    rreq_pulse;
  wire                    write_end;
  wire                    read_end;
  wire                    err_wresp;
  wire                    err_rresp;
  wire                    wnext;
  wire                    rnext;

  enum reg [2-1:0] {
    S_IDLE, S_BUSY
  } state_write$, state_read$;
  reg                     ack$;
  reg [3:0]               err$;
  reg [ID_WIDTH-1:0]      awid$;
  reg [BWIDTH-1:0]        awaddr$;
  reg [7:0]               awlen$;
  reg [2:0]               awsize$;
  reg [1:0]               awburst$;
  reg                     awlock$;
  reg [3:0]               awcache$;
  reg [2:0]               awprot$;
  reg [3:0]               awqos$;
  reg [AWUSER_WIDTH-1:0]  awuser$;
  reg                     awvalid$;
  reg [BWIDTH-1:0]        wdata$;
  reg [BWIDTH/8-1:0]      wstrb$;
  reg                     wlast$;
  reg [WUSER_WIDTH-1:0]   wuser$;
  reg                     wvalid$;
  reg                     bready$;
  reg [ID_WIDTH-1:0]      arid$;
  reg [BWIDTH-1:0]        araddr$;
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
  reg [TXN_NUM:0]         read_idx$;
  reg                     write_start$;
  reg                     read_start$;
  reg                     write_active$;
  reg                     read_active$;
  reg                     req$;
  reg [WORDSIZE-1:0]      read_base$;
  reg [LWIDTH-1:0]        read_len$;
  reg [WORDSIZE-1:0]      write_base$;
  reg [LWIDTH-1:0]        write_len$;
  reg                     ddr_we$;
  reg [WORDSIZE-1:0]      ddr_waddr$;
  reg [BWIDTH-1:0]        ddr_wdata$;
  reg [WORDSIZE-1:0]      ddr_raddr$;
  reg [WORDSIZE-1:0]    tmp_addr$;
  reg [DATA_WIDTH-1:0]  tmp_data$;
  reg [DATA_WIDTH-1:0]  tmp_data2$;
  reg have_awaddr$;
  reg next_awaddr$;


//==========================================================
// core control
//==========================================================
// {{{

  assign req_pulse  = ddr_req && !req$;
  assign wreq_pulse = ddr_mode == DDR_WRITE && req_pulse;
  assign rreq_pulse = ddr_mode == DDR_READ  && req_pulse;

  assign write_end  = bvalid && bready$;
  assign read_end   = rvalid && rready$ && read_idx$ == read_len$ - 1;

  always @(posedge clk)
    if (!xrst)
      req$ <= 0;
    else
      req$ <= ddr_req;

  always @(posedge clk)
    if (!xrst) begin
      read_base$  <= 0;
      read_len$   <= 0;
      write_base$ <= 0;
      write_len$  <= 0;
    end
    else if (ddr_req)
      case (ddr_mode)
        DDR_READ: begin
          read_base$  <= ddr_base >> LSB;
          read_len$   <= ddr_len;
        end
        DDR_WRITE: begin
          write_base$ <= ddr_base >> LSB;
          write_len$  <= ddr_len;
        end
        default: begin
          read_base$  <= 0;
          read_len$   <= 0;
          write_base$ <= 0;
          write_len$  <= 0;
        end
      endcase

  /*
   * Read and write channel works independent each other.
   * They could be multiplexed for burst transaction.
   */
  always @(posedge clk)
    if (!xrst) begin
      state_write$ <= S_IDLE;
      write_start$ <= 0;
    end
    else
      case (state_write$)
        S_IDLE:
          if (wreq_pulse)
            state_write$ <= S_BUSY;

        S_BUSY:
          if (write_end)
            state_write$ <= S_IDLE;
          else if (!awvalid$ && !write_start$ && !write_active$)
            write_start$ <= 1;
          else
            write_start$ <= 0;

        default:
          state_write$ <= S_IDLE;
      endcase

  always @(posedge clk)
    if (!xrst) begin
      state_read$ <= S_IDLE;
      read_start$ <= 0;
    end
    else
      case (state_read$)
        S_IDLE:
          if (rreq_pulse)
            state_read$ <= S_BUSY;

        S_BUSY:
          if (read_end)
            state_read$ <= S_IDLE;
          else if (!arvalid$ && !read_active$ && !read_start$)
            read_start$ <= 1;
          else
            read_start$ <= 0;

        default:
          state_read$ <= S_IDLE;
      endcase

  always @(posedge clk)
    if (!xrst)
      write_active$ <= 0;
    else if (wreq_pulse)
      write_active$ <= 0;
    else if (write_start$)
      write_active$ <= 1;
    else if (bvalid && bready$)
      write_active$ <= 0;

  always @(posedge clk)
    if (!xrst)
      read_active$ <= 0;
    else if (rreq_pulse)
      read_active$ <= 0;
    else if (read_start$)
      read_active$ <= 1;
    else if (rvalid && rready$ && rlast)
      read_active$ <= 0;

// }}}
//==========================================================
// write address control
//==========================================================
// {{{

  assign awvalid  = awvalid$;
  assign awid     = 0;
  assign awaddr   = awaddr$;
  assign awlen    = write_len$ - 1;
  assign awsize   = clogb2(BWIDTH/8 - 1);
  assign awburst  = 2'b01;
  assign awlock   = 1'b0;
  assign awcache  = 4'b0010;
  assign awprot   = 3'b000;
  assign awqos    = 4'b0000;
  assign awuser   = 1;

  always @(posedge clk)
    if (!xrst)
      awvalid$ <= 0;
    else if (wreq_pulse)
      awvalid$ <= 0;
    else if (!awvalid$ && write_start$)
      awvalid$ <= 1;
    else if (awready && awvalid$)
      awvalid$ <= 0;

  always @(posedge clk)
    if (!xrst)
      awaddr$ <= 0;
    else if (wreq_pulse)
      awaddr$ <= ddr_base;

// }}}
//==========================================================
// write data control
//==========================================================
// {{{

  assign wvalid = wvalid$;
  // assign wdata  = wdata$;
  assign wstrb  = {BWIDTH/8{1'b1}};
  assign wlast  = wlast$;
  assign wuser  = 0;

  assign wnext = wready && wvalid$;

  // TODO: re-define this temp signal
  always @(posedge clk) begin
    have_awaddr$ <= awready && awvalid$;
    next_awaddr$ <= have_awaddr$;
  end
  always @(posedge clk)
    if (!xrst)
      wvalid$ <= 0;
    else if (wreq_pulse)
      wvalid$ <= 0;
    else if (!wvalid$ && have_awaddr$)
      wvalid$ <= 1;
    else if (wnext && wlast$)
      wvalid$ <= 0;

  // input ddr_rdata have been interpreted as write data for host memory.
  always @(posedge clk)
    if (!xrst)
      wdata$ <= 0;
    else if (have_awaddr$)
      wdata$ <= ddr_rdata;
    else if (wnext && write_idx$ != write_len$ - 1)
      wdata$ <= ddr_rdata;

  always @(posedge clk)
    if (!xrst)
      wlast$ <= 0;
    else if (wreq_pulse)
      wlast$ <= 0;
    else if ((write_idx$ == write_len$ - 2 && write_len$ >= 2 && wnext)
              || write_len$ == 1)
      wlast$ <= 1;
    else if (wnext)
      wlast$ <= 0;
    else if (wlast$ && write_len$ == 1)
      wlast$ <= 0;

  always @(posedge clk)
    if (!xrst)
      write_idx$ <= 0;
    else if (wreq_pulse || write_start$)
      write_idx$ <= 0;
    else if (wnext && write_idx$ != write_len$ - 1)
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
  assign arlen    = read_len$ - 1;
  assign arsize   = clogb2(BWIDTH/8 - 1);
  assign arburst  = 2'b01;
  assign arlock   = 1'b0;
  assign arcache  = 4'b0010;
  assign arprot   = 3'b000;
  assign arqos    = 4'b0000;
  assign aruser   = 1;

  always @(posedge clk)
    if (!xrst)
      arvalid$ <= 0;
    else if (rreq_pulse)
      arvalid$ <= 0;
    else if (!arvalid$ && read_start$)
      arvalid$ <= 1;
    else if (arready && arvalid$)
      arvalid$ <= 0;

  always @(posedge clk)
    if (!xrst)
      araddr$ <= 0;
    else if (rreq_pulse)
      araddr$ <= ddr_base;

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
      read_idx$ <= 0;
    else if (rreq_pulse || read_start$)
      read_idx$ <= 0;
    else if (rnext && read_idx$ != read_len$ - 1)
      read_idx$ <= read_idx$ + 1;

// }}}
//==========================================================
// memory control
//==========================================================
// {{{

  assign err = err$;

  // read data is emitted as write data for target ram region.
  assign ddr_we     = ddr_we$;
  assign ddr_waddr  = ddr_waddr$;
  assign ddr_wdata  = ddr_wdata$;

  // assign ddr_raddr  = ddr_raddr$;
  // assign ddr_raddr  = wnext && write_idx$ != write_len$ - 1
  //                   ? ddr_raddr$ + 1
  //                   : ddr_raddr$;

  always @(posedge clk)
    if (!xrst)
      err$ <= 0;
    else if (wreq_pulse || rreq_pulse)
      err$ <= 0;
    else if (err_wresp || err_rresp)
      err$ <= {err_wresp, err_rresp, 1'b1};

  always @(posedge clk)
    if (!xrst)
      ddr_we$ <= 0;
    else if (rvalid && rready$)
      ddr_we$ <= 1;
    else
      ddr_we$ <= 0;

  always @(posedge clk)
    if (!xrst)
      ddr_waddr$ <= 0;
    else if (read_start$)
      ddr_waddr$ <= read_base$;
    else if (ddr_we$)
      ddr_waddr$ <= ddr_waddr$ + 1;

  always @(posedge clk)
    if (!xrst)
      ddr_wdata$ <= 0;
    else if (rvalid && rready$)
      ddr_wdata$ <= rdata;
    else
      ddr_wdata$ <= 0;

  always @(posedge clk)
    if (!xrst)
      ddr_raddr$ <= 0;
    else if (write_start$)
      ddr_raddr$ <= write_base$;
    else if (have_awaddr$)
      ddr_raddr$ <= ddr_raddr$ + 1;
    else if (wnext && write_idx$ != write_len$ - 1)
      ddr_raddr$ <= ddr_raddr$ + 1;

// }}}
//==========================================================
// temp TODO: absolutely need refactoring
//==========================================================
// {{{

  assign ddr_raddr  = tmp_addr$;
  assign wdata  = tmp_data$;

  always @(posedge clk)
    if (!xrst)
      tmp_addr$ <= 0;
    else if (write_start$)
      tmp_addr$ <= write_base$;
    else if (awready && awvalid$)
      tmp_addr$ <= tmp_addr$ + 1;
    else if (have_awaddr$)
      tmp_addr$ <= tmp_addr$ + 1;
    else if (wnext && write_idx$ != write_len$ - 1)
      tmp_addr$ <= tmp_addr$ + 1;

  always @(posedge clk)
    if (!xrst)
      tmp_data$ <= 0;
    // else if (state_write$ == S_IDLE)
    //   tmp_data$ <= 0;
    else if (have_awaddr$)
      tmp_data$ <= ddr_rdata;
    else if (wnext)
      if (write_idx$ == 0)
        tmp_data$ <= tmp_data2$;
      else if (write_idx$ != write_len$ - 1)
        tmp_data$ <= ddr_rdata;

  always @(posedge clk)
    if (!xrst)
      tmp_data2$ <= 0;
    else if (state_write$ == S_IDLE)
      tmp_data2$ <= 0;
    else if (next_awaddr$)
      tmp_data2$ <= ddr_rdata;

// }}}
endmodule
