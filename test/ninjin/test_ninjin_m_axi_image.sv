`include "ninjin.svh"

parameter DATA_WIDTH    = 32;
parameter ADDR_WIDTH    = 12;
parameter ID_WIDTH      = 12;
parameter AWUSER_WIDTH  = 0;
parameter ARUSER_WIDTH  = 0;
parameter WUSER_WIDTH   = 0;
parameter RUSER_WIDTH   = 0;
parameter BUSER_WIDTH   = 0;

module test_ninjin_m_axi_image;

  reg                   clk;
  reg                   xrst;
  reg                   awready;
  reg                   wready;
  reg [ID_WIDTH-1:0]    bid;
  reg [1:0]             bresp;
  reg [BUSER_WIDTH-1:0] buser;
  reg                   bvalid;
  reg                   arready;
  reg [ID_WIDTH-1:0]    rid;
  reg [BWIDTH-1:0]      rdata;
  reg [1:0]             rresp;
  reg                   rlast;
  reg [RUSER_WIDTH-1:0] ruser;
  reg                   rvalid;
  reg                   ddr_req;
  reg                   ddr_mode;
  reg [MEMSIZE+LSB-1:0] ddr_base;
  reg [LWIDTH-1:0]      ddr_len;
  reg [BWIDTH-1:0]      ddr_rdata;

  wire [3:0]              err;
  wire                    awvalid;
  wire [ID_WIDTH-1:0]     awid;
  wire [BWIDTH-1:0]       awaddr;
  wire [7:0]              awlen;
  wire [2:0]              awsize;
  wire [1:0]              awburst;
  wire                    awlock;
  wire [3:0]              awcache;
  wire [2:0]              awprot;
  wire [3:0]              awqos;
  wire [AWUSER_WIDTH-1:0] awuser;
  wire                    wvalid;
  wire [BWIDTH-1:0]       wdata;
  wire [BWIDTH/8-1:0]     wstrb;
  wire                    wlast;
  wire [WUSER_WIDTH-1:0]  wuser;
  wire                    bready;
  wire                    arvalid;
  wire [ID_WIDTH-1:0]     arid;
  wire [BWIDTH-1:0]       araddr;
  wire [7:0]              arlen;
  wire [2:0]              arsize;
  wire [1:0]              arburst;
  wire                    arlock;
  wire [3:0]              arcache;
  wire [2:0]              arprot;
  wire [3:0]              arqos;
  wire [ARUSER_WIDTH-1:0] aruser;
  wire                    rready;
  wire                    ddr_we;
  wire [MEMSIZE-1:0]      ddr_waddr;
  wire [BWIDTH-1:0]       ddr_wdata;
  wire [MEMSIZE-1:0]      ddr_raddr;

  ninjin_m_axi_image dut(.*);

  mem_dp #(BWIDTH, MEMSIZE) mem_ddr(
    .mem_we1    (ddr_we),
    .mem_addr1  (ddr_waddr),
    .mem_wdata1 (ddr_wdata),
    .mem_rdata1 (),
    .mem_we2    (1'b0),
    .mem_addr2  (ddr_raddr),
    .mem_wdata2 ({BWIDTH{1'b0}}),
    .mem_rdata2 (ddr_rdata),
    .*
  );

  // clock
  initial begin
    clk = 0;
    forever
      #(STEP/2) clk = ~clk;
  end

//==========================================================
// scenario
//==========================================================
// {{{

  initial begin
    xrst = 0;
    #(STEP);

    xrst      = 1;
    awready   = 0;
    wready    = 0;
    bid       = 0;
    bresp     = 0;
    buser     = 0;
    bvalid    = 0;
    arready   = 0;
    rid       = 0;
    rdata     = 0;
    rresp     = 0;
    rlast     = 0;
    ruser     = 0;
    rvalid    = 0;
    ddr_req   = 0;
    ddr_mode  = 0;
    ddr_base  = 0;
    ddr_len   = 0;
    // ddr_rdata = 0;

    ddr_init;
    #(STEP);

    ddr_read_txn('ha000, BURST_MAX);
    repeat (32) #(STEP);
    // repeat (BURST_MAX + 32) #(STEP);

    ddr_write_txn('hc000, BURST_MAX);
    repeat (BURST_MAX + 32) #(STEP);

    $finish();
  end

// }}}
//==========================================================
// tasks
//==========================================================
// {{{

  task ddr_init;
    for (int i = 0; i < 2**MEMSIZE; i++)
      mem_ddr.mem[i] = i + 'h42;
  endtask

  task ddr_write_txn
    ( input [MEMSIZE-1:0] base
    , input [MEMSIZE-1:0] len
    );

    ddr_req   = 1;
    ddr_mode  = DDR_WRITE;
    ddr_base  = base;
    ddr_len   = len;
    #(STEP);
    ddr_req   = 0;
    #(STEP);
  endtask

  task ddr_read_txn
    ( input [MEMSIZE-1:0] base
    , input [MEMSIZE-1:0] len
    );

    ddr_req   = 1;
    ddr_mode  = DDR_READ;
    ddr_base  = base;
    ddr_len   = len;
    #(STEP);
    ddr_req   = 0;
    #(STEP);
  endtask

// }}}
//==========================================================
// models
//==========================================================
// {{{

  integer _awlen, _arlen;

  // write address channel
  always @(awvalid) begin
    #(STEP/2-1);
    if (awvalid) begin
      awready = 1;
      _awlen = awlen;
      #(STEP);
      awready = 0;
      #(STEP);
    end
    #(STEP/2+1);
  end

  // write data channel
  always @(wvalid) begin
    #(STEP/2-1);
    if (wvalid) begin
      #(4*STEP);
      wready = 1;
      for (int i = 0; i < _awlen+1; i++)
        #(STEP);
      wready = 0;
      #(14*STEP);
      bvalid = 1;
      #(STEP);
    end
    #(STEP/2+1);
  end

  // write response channel
  always @(bready) begin
    #(STEP/2-1);
    if (bready) begin
      bvalid = 1;
      #(STEP);
      bvalid = 0;
      #(STEP);
    end
    #(STEP/2+1);
  end

  // read address channel
  always @(arvalid) begin
    #(STEP/2-1);
    if (arvalid) begin
      arready = 1;
      _arlen  = arlen;
      #(STEP);
      arready = 0;
      #(21*STEP);
      rvalid = 1;
      rdata  = 'hb000;
      #(STEP);
    end
    #(STEP/2+1);
  end

  // read date channel
  always @(rready) begin
    #(STEP/2-1);
    if (rready) begin
      for (int i = 0; i < _arlen+1; i++) begin
        rvalid = 1;
        rdata  = 'hb000 + i;
        if (i == _arlen)
          rlast = 1;
        #(STEP);
      end
      rvalid  = 0;
      rlast   = 0;
      #(STEP);
    end
    #(STEP/2+1);
  end

// }}}
//==========================================================
// display
//==========================================================
// {{{

  initial begin
    $display("clk: |");
    forever begin
      #(STEP/2-1);
      $display(
        "%3x: ", $time/STEP,
        "*%-6p ", dut.state_write$,
        "*%-6p ", dut.state_read$,
        "| ",
        "%x ",  ddr_req,
        "%x ",  ddr_mode,
        "%x ",  ddr_base,
        "%x ",  ddr_len,
        ": ",
        "%x ",  ddr_we,
        "%x ",  ddr_waddr,
        "%x ",  ddr_wdata,
        ": ",
        "%x ",  ddr_raddr,
        "%x ",  ddr_rdata,
        "|aw: ",
        "%x ",  awvalid,
        "%x ",  awready,
        ": ",
        "%4x ", awaddr,
        "|w: ",
        "%x ",  dut.write_start$,
        "%x ",  wvalid,
        "%x ",  wready,
        "%x ",  dut.wnext,
        ": ",
        "%x ", wdata,
        "|b: ",
        "%x ",  bvalid,
        "%x ",  bready,
        "|ar: ",
        "%x ",  arvalid,
        "%x ",  arready,
        ": ",
        "%4x ", araddr,
        "|r: ",
        "%x ",  dut.read_start$,
        "%x ",  rvalid,
        "%x ",  rready,
        "%x ",  dut.rnext,
        ": ",
        "%x ", rdata,
        "|"
      );
      #(STEP/2+1);
    end
  end

// }}}
endmodule
