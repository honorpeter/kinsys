`include "ninjin.svh"

const int READ_LEN   = 128+8;//16*12*12;
// TODO: currently, odd WRITE_LEN won't work.
//       (However, actual WRITE_LEN may be CORE * ~, where CORE is even)
const int WRITE_LEN  = 128+8;//8*4*4;

// int READ_OFFSET  = 42;
const int READ_OFFSET  = 3000;
const int WRITE_OFFSET = 3000;

module test_ninjin_ddr_buf;

  parameter DDR_READ  = 'd0;
  parameter DDR_WRITE = 'd1;

  reg                     clk;
  reg                     xrst;
  reg                     prefetch;
  reg [IMGSIZE-1:0]       base_addr;
  reg [LWIDTH-1:0]        total_len;
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

  integer burst_len;

  ninjin_ddr_buf dut(.*);

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
    xrst      = 0;
    #(STEP);

    xrst      = 1;
    prefetch  = 0;
    base_addr = 0;
    total_len = 0;
    mem_we    = 0;
    mem_addr  = 0;
    mem_wdata = 0;
    ddr_we    = 0;
    ddr_addr  = 0;
    ddr_wdata = 0;
    #(STEP);

    $display("### prefetch");
    setup(READ_OFFSET, READ_LEN);
    #(32*STEP);
    // #(512*STEP);

    $display("### reading");
    reset(READ_OFFSET, READ_LEN);
    for (int i = 0; i < READ_LEN; i++) begin
      read(i + READ_OFFSET);
      if (i % 14 == 0) #(10*STEP);
    end
    clear;
    #(32*STEP);

    $display("### writing");
    reset(WRITE_OFFSET, WRITE_LEN);
    for (int i = 0; i < WRITE_LEN; i++)
      write(i + WRITE_OFFSET, i + 'h0a00);
    clear;
    #(48*STEP);
    // #(512*STEP);

    $display("### reading");
    reset(READ_OFFSET, READ_LEN);
    for (int i = 0; i < READ_LEN; i++) begin
      read(i + READ_OFFSET);
      if (i % 14 == 0) #(10*STEP);
    end
    clear;
    #(32*STEP);

    $display("### writing");
    reset(WRITE_OFFSET, WRITE_LEN);
    for (int i = 0; i < WRITE_LEN; i++)
      write(i + WRITE_OFFSET, i + 'h0a00);
    clear;
    #(32*STEP);
    // #(512*STEP);

    $finish();
  end

// }}}
//==========================================================
// tasks
//==========================================================
// {{{

  task setup
    ( input integer base
    , input integer len
    );

    prefetch  = 1;
    base_addr = base;
    total_len = len;
    #(STEP);
    prefetch = 0;
    #(STEP);
  endtask

  task reset
    ( input integer base
    , input integer len
    );

    prefetch  = 0;
    base_addr = base;
    total_len = len;
    #(STEP);
  endtask

  task clear;
    mem_we    = 0;
    mem_addr  = 0;
    mem_wdata = 0;
    #(STEP);
  endtask

  task read
    ( input integer addr
    );

    mem_we    = 0;
    mem_addr  = addr;
    mem_wdata = 0;
    #(STEP);
  endtask

  task write
    ( input integer addr
    , input integer wdata
    );

    mem_we    = 1;
    mem_addr  = addr;
    mem_wdata = wdata;
    #(STEP);
  endtask

// }}}
//==========================================================
// models & assertions
//==========================================================
// {{{

  // pseudo ddr
  always @(ddr_req) begin
    #(STEP/2-1);
    if (ddr_req) begin
      burst_len = ddr_len;
      ddr_addr  = ddr_base;
      ddr_wdata = 0;
      case (ddr_mode)
        DDR_READ:  ddr_we = 1;
        DDR_WRITE: ddr_we = 0;
      endcase
      ddr_wdata = ddr_we ? 'h0defa000 + ddr_addr - READ_OFFSET : 0;
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

  // mem assert
  always @(mem_we, mem_addr, mem_wdata, mem_rdata) begin
    #(STEP/2-1);
    if (dut.r_mode == 1)
      case (dut.r_state[0])
        2:
          if (dut.r_mem_addr % 2 == 1)
            assert (mem_rdata == 'h0def) else
              $error("read assertion failed (odd)");
          else
            assert (mem_rdata == 'ha000 + (dut.r_mem_addr - READ_OFFSET)/2) else
              $error("read assertion failed (even)");
        3:
          assert (mem_rdata == 'h0a00 + dut.r_mem_addr - WRITE_OFFSET) else
            $error("write assertion failed");
        default:
          assert(1'b1);
      endcase
    #(STEP/2+1);
  end

// }}}
//==========================================================
// display
//==========================================================
// {{{

  initial begin
    $display("### test_ninjin_ddr_buf");
    forever begin
      #(STEP/2-1);
      $display(
        "%4d: ", $time/STEP,
        "%d ", xrst,
        "*%-7p ", dut.r_state[0],
        ": ",
        "%5d ", dut.addr_diff,
        "%d ", dut.mode,
        "%d ", dut.txn_start,
        "%d ", dut.txn_stop,
        ": ",
        "%d ", dut.r_count_len,
        "%d ", dut.r_count_inner,
        "| ",
        // "%d ", dut.addr_offset[BUFSIZE:1],
        // "%d ", dut.word_offset,
        "%d ",  mem_we,
        "%d ",  mem_addr,
        "%4x ", mem_wdata,
        "%4x ", mem_rdata,
        // "| ",
        // "%d ",  prefetch,
        // "%d ",  total_len,
        // "%d ",  dut.r_base_addr,
        // "| ",
        // "%d ",  ddr_req,
        // "%d ",  ddr_mode,
        // "%d ",  ddr_base,
        // "%d ",  ddr_len,
        "| ",
        "%d ",  ddr_we,
        "%d ",  ddr_addr,
        "%8x ", ddr_wdata,
        "%8x ", ddr_rdata,
        "| ",
        "*%-5p ", dut.r_which[0],
        "*%-5p ", dut.r_which[1],
        "*%-5p ", dut.r_first_buf,
        "%d ",  dut.switch_buf,
        "%d ",  dut.mem_addr,
        "%d ",  dut.r_mem_diff,
        ":a ",
        "%d ",  dut.buf_we[0],
        "%d ",  dut.r_buf_base[0],
        "%d ",  dut.buf_addr[0],
        "%8x ", dut.buf_wdata[0],
        "%8x ", dut.buf_rdata[0],
        // ":b ",
        // "%d ",  dut.buf_we[1],
        // "%d ",  dut.r_buf_base[1],
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

// }}}
endmodule

