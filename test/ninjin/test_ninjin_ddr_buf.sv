`include "ninjin.svh"

const int READ_LEN   = 16*12*12;//128+8;
// TODO: currently, odd WRITE_LEN won't work.
//       (However, actual WRITE_LEN may be CORE * ~, where CORE is even)
const int WRITE_LEN  = 8*4*4;//128+8;

// int READ_OFFSET  = 42;
const int READ_OFFSET  = 3000;
const int WRITE_OFFSET = 3000;

module test_ninjin_ddr_buf;

  parameter DDR_READ  = 'd0;
  parameter DDR_WRITE = 'd1;

  reg                     clk;
  reg                     xrst;
  reg                     prefetch_en;
  reg [LWIDTH-1:0]        total_len;
  reg [IMGSIZE-1:0]       base_addr;
  reg                     mem_we;
  reg [IMGSIZE-1:0]       mem_addr;
  reg signed [DWIDTH-1:0] mem_wdata;
  reg                     ddr_we;
  reg [IMGSIZE-1:0]       ddr_addr;
  reg [BWIDTH-1:0]        ddr_wdata;
  wire                      ddr_req;
  wire                      ddr_mode;
  wire [IMGSIZE-1:0]        ddr_base;
  wire [LWIDTH-1:0]         ddr_len;
  wire [BWIDTH-1:0]         ddr_rdata;
  wire signed [DWIDTH-1:0]  mem_rdata;

  ninjin_ddr_buf dut(.*);

  // clock
  initial begin
    clk = 0;
    forever
      #(STEP/2) clk = ~clk;
  end

  //flow
  initial begin
    xrst      = 0;
    #(STEP);

    xrst      = 1;
    prefetch_en = 0;
    total_len = 0;
    base_addr = 0;
    mem_we    = 0;
    mem_addr  = 0;
    mem_wdata = 0;
    ddr_we    = 0;
    ddr_addr  = 0;
    ddr_wdata = 0;
    #(STEP);

    $display("### prefetch");
    prefetch_en = 1;
    total_len = READ_LEN;
    base_addr = READ_OFFSET;
    #(STEP);
    prefetch_en = 0;
    #(512*STEP);

    $display("### reading");
    mem_we    = 0;
    for (int i = 0; i < READ_LEN; i++) begin
      mem_addr  = i + READ_OFFSET;
      mem_wdata = 0;
      if (i % 14 == 0)
        #(10*STEP);
      #(STEP);
    end
    mem_we    = 0;
    mem_addr  = 0;
    mem_wdata = 0;
    #(STEP);
    #(32*STEP);

    $display("### writing");
    prefetch_en = 0;
    total_len   = WRITE_LEN;
    base_addr   = base_addr;
    #(STEP);
    mem_we = 1;
    for (int i = 0; i < WRITE_LEN; i++) begin
      mem_addr  = i + WRITE_OFFSET;
      mem_wdata = i + 'h0a00;
      #(STEP);
    end
    mem_we    = 0;
    mem_addr  = 0;
    mem_wdata = 0;
    #(STEP);
    #(512*STEP);

    $finish();
  end

  integer burst_len;
  always @(ddr_req) begin
    #(STEP/2-1);
    if (ddr_req) begin
      ddr_addr  = ddr_base;
      ddr_wdata = 0;
      burst_len = ddr_len;
      case (ddr_mode)
        DDR_READ:  ddr_we = 1;
        DDR_WRITE: ddr_we = 0;
      endcase
      ddr_wdata = ddr_we ? 'h0defa000 + ddr_addr - WRITE_OFFSET : 0;
      #(STEP);
      for (int i = 0; i < burst_len-1; i++) begin
        ddr_addr++;
        if (ddr_we)
          ddr_wdata++;
        #(STEP);
      end
      ddr_we    = 0;
      ddr_addr  = 0;
      ddr_wdata = 0;
      #(STEP);
    end
    #(STEP/2+1);
  end

  //display
  initial begin
    forever begin
      #(STEP/2-1);
      $display(
        "%4d: ", $time/STEP,
        "%d ", xrst,
        "%-7s ", dut.r_state[0],
        ": ",
        "%5d ", dut.addr_diff,
        "%d ", dut.mode,
        "%d ", dut.txn_start,
        "%d ", dut.txn_stop,
        ": ",
        "%2d ", dut.r_count_burst,
        "%d ", dut.r_count_len,
        "%d ", dut.r_count_inner,
        "| ",
        "%d ", dut.spagetti[BUFSIZE:1],
        "%d ", dut.fuga,
        "%d ",  mem_we,
        "%d ",  mem_addr,
        "%4x ", mem_wdata,
        "%4x ", mem_rdata,
        "| ",
        "%d ",  prefetch_en,
        "%d ",  total_len,
        "%d ",  dut.r_base_addr,
        "| ",
        "%d ",  ddr_req,
        "%d ",  ddr_mode,
        "%d ",  ddr_base,
        "%d ",  ddr_len,
        "| ",
        "%d ",  ddr_we,
        "%d ",  ddr_addr,
        "%8x ", ddr_wdata,
        "%8x ", ddr_rdata,
        "| ",
        "%6s ", dut.r_which,
        "%d ", dut.switch_buf,
        // ":a ",
        // "%d ",  dut.buf_we[0],
        // "%d ",  dut.buf_addr[0],
        // "%8x ", dut.buf_wdata[0],
        // "%8x ", dut.buf_rdata[0],
        // ":b ",
        // "%d ",  dut.buf_we[1],
        // "%d ",  dut.buf_addr[1],
        // "%8x ", dut.buf_wdata[1],
        // "%8x ", dut.buf_rdata[1],
        // ":p ",
        // "%d ",  dut.pre_we,
        // "%d ",  dut.pre_addr,
        // "%8x ", dut.pre_wdata,
        // "%8x ", dut.pre_rdata,
        "|"
      );
      #(STEP/2+1);
    end
  end

endmodule

