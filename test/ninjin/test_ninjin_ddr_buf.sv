`include "ninjin.svh"

const int READ_LEN   = 128+8;
// const int READ_LEN   = 16*12*12;
// TODO: currently, odd WRITE_LEN won't work.
//       (However, actual WRITE_LEN may be CORE * ~, where CORE is even)
const int WRITE_LEN  = 128+8;
// const int WRITE_LEN  = 8*4*4;

// int READ_OFFSET  = 42;
const int READ_OFFSET  = 'h0a00;
const int WRITE_OFFSET = 'h0a00;

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
  reg [IMGSIZE-1:0]       ddr_waddr;
  reg [BWIDTH-1:0]        ddr_wdata;
  reg [IMGSIZE-1:0]       ddr_raddr;
  wire                      ddr_req;
  wire                      ddr_mode;
  wire [IMGSIZE-1:0]        ddr_base;
  wire [LWIDTH-1:0]         ddr_len;
  wire [BWIDTH-1:0]         ddr_rdata;
  wire signed [DWIDTH-1:0]  mem_rdata;

  integer _ddr_base [1:0];
  integer _ddr_len [1:0];

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
    ddr_waddr = 0;
    ddr_wdata = 0;
    ddr_raddr = 0;
    #(STEP);

    $display("### prefetch");
    setup(READ_OFFSET, READ_LEN);
    #(RATE*BURST_LEN*STEP);

    $display("### reading");
    reset(READ_OFFSET, READ_LEN);
    for (int i = 0; i < READ_LEN; i++) begin
      read(i + READ_OFFSET);
      if (i % 14 == 0) #(10*STEP);
    end
    clear;
    #(STEP);

    $display("### writing");
    reset(WRITE_OFFSET, WRITE_LEN);
    for (int i = 0; i < WRITE_LEN; i++)
      write(i + WRITE_OFFSET, i + 'h0b00);
    clear;
    #(STEP);

    $display("### reading");
    reset(READ_OFFSET, READ_LEN);
    for (int i = 0; i < READ_LEN; i++) begin
      read(i + READ_OFFSET);
      if (i % 14 == 0) #(10*STEP);
    end
    clear;
    #(STEP);

    $display("### writing");
    reset(WRITE_OFFSET, WRITE_LEN);
    for (int i = 0; i < WRITE_LEN; i++)
      write(i + WRITE_OFFSET, i + 'h0b00);
    clear;
    #(STEP);

    #(2*BURST_LEN*STEP);
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
  always @(posedge ddr_req) begin
    #(STEP/2-1);
    if (ddr_mode == DDR_READ) begin
      _ddr_base[DDR_READ] = ddr_base;
      _ddr_len[DDR_READ]  = ddr_len;
      for (int i = 0; i < _ddr_len[DDR_READ]; i++) begin
        ddr_we    = 1;
        ddr_waddr = i + _ddr_base[DDR_READ];
        ddr_wdata = 'h0def0c00 + ddr_waddr - READ_OFFSET;
        #(STEP);
      end
      ddr_we    = 0;
      ddr_waddr = 0;
      ddr_wdata = 0;
      #(STEP);
    end
    #(STEP/2+1);
  end

  always @(posedge ddr_req) begin
    #(STEP/2-1);
    if (ddr_mode == DDR_WRITE) begin
      _ddr_base[DDR_WRITE] = ddr_base;
      _ddr_len[DDR_WRITE]  = ddr_len;
      for (int i = 0; i < _ddr_len[DDR_WRITE]; i++) begin
        ddr_raddr = i + _ddr_base[DDR_WRITE];
        #(STEP);
      end
      ddr_raddr = 0;
      #(STEP);
    end
    #(STEP/2+1);
  end

  // mem assert
  always @(mem_we, mem_addr, mem_wdata, mem_rdata) begin
    #(STEP/2-1);
    if (dut.mem_addr$ != 0)
      case (dut.state$[0])
        2:
          if (dut.mem_addr$ % 2 == 1)
            assert (mem_rdata == 'h0def) else
              $error("read assertion failed (odd)");
          else
            assert (mem_rdata == 'h0c00 + (dut.mem_addr$ - READ_OFFSET)/2) else
              $error("read assertion failed (even)");
        3:
          assert (mem_rdata == 'h0b00 + dut.mem_addr$ - WRITE_OFFSET) else
            $error("write assertion failed @ mem_rdata: %h, target: %h", mem_rdata, 'h0b00 + dut.mem_addr$ - WRITE_OFFSET);
        default:
          assert(1'b1);
      endcase
    #(STEP/2+1);
  end

  // ddr assert
  reg [IMGSIZE-1:0] ddr_raddr$;
  always @(posedge clk) ddr_raddr$ <= dut.ddr_raddr;
  always @(ddr_we, ddr_waddr, ddr_wdata, ddr_raddr, ddr_rdata) begin
    #(STEP/2-1);
    if (ddr_raddr$ != 0)
      assert (ddr_rdata == {
        16'h0b00 + (2'h2*ddr_raddr$[7:0]),
        16'h0b00 + (2'h2*ddr_raddr$[7:0]+1'h1)
      })
      else begin
        $error("ddr assertion failed @ raddr: %h rdata: %h",
          ddr_raddr$, ddr_rdata);
        $info("%h", {
          16'h0b00 + (2'h2*ddr_raddr$[7:0]),
          16'h0b00 + (2'h2*ddr_raddr$[7:0]+1'h1)
        });
      end
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
        // "%d ", xrst,
        "*%d ", dut.state$[0],
        // ": ",
        // "%5d ", dut.addr_diff,
        "%d ", dut.mode,
        "%d ", dut.txn_start,
        "%d ", dut.txn_stop,
        "%d ", dut.we_accum$,
        "%h ", dut.mem_wdata,
        "%h ", dut.buf_wdata$,
        "%h ", dut.buf_wdata[0],
        // ": ",
        // "%2x ", dut.count_len$,
        // "%2x ", dut.count_inner$,
        // "%d ", dut.java,
        // "%d ", dut.not_java,
        // "%d ", dut.count_post$,
        "| ",
        // "%d ", dut.addr_offset[BUFSIZE:1],
        // "%d ", dut.word_offset,
        "%x ",  mem_we,
        "%3x ", mem_addr,
        "%3x ", mem_wdata,
        "%3x ", mem_rdata,
        "| ",
        // "%d ",  prefetch,
        // "%d ",  total_len,
        // "%d ",  dut.base_addr$,
        // "| ",
        // "%x ",  ddr_req,
        // "%x ",  ddr_mode,
        // "%x ",  ddr_base,
        // "%x ",  ddr_len,
        // "| ",
        "%x ",  ddr_we,
        "%3x ", ddr_waddr,
        "%7x ", ddr_wdata,
        "%3x ", ddr_raddr,
        "%7x ", ddr_rdata,
        "| ",
        "*%d ", dut.which$,
        "*%d ", dut.mem_which$,
        "*%d ", dut.ddr_which$,
        "%d ",  dut.switch_buf,
        "%d ",  dut.switch_buf$,
        "*%d ", dut.first_buf$,
        ": ",
        "%x ",  dut.buf_we[0],
        "%x ",  dut.buf_base$[0],
        "%x ",  dut.buf_addr[0],
        "%7x ", dut.buf_wdata[0],
        "%7x ", dut.buf_rdata[0],
        // ": ",
        // "%x ",  dut.buf_we[1],
        // "%x ",  dut.buf_addr[1],
        // "%7x ", dut.buf_wdata[1],
        // "%7x ", dut.buf_rdata[1],
        // ": ",
        // "%x ",  dut.pre_we,
        // "%x ",  dut.pre_addr,
        // "%7x ", dut.pre_wdata,
        // "%7x ", dut.pre_rdata,
        // ": ",
        // "%x ",  dut.post_we,
        // "%x ",  dut.post_addr,
        // "%7x ", dut.post_wdata,
        // "%7x ", dut.post_rdata,
        "|"
      );
      #(STEP/2+1);
    end
  end

// }}}
endmodule

