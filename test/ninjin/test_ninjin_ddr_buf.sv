`include "ninjin.svh"

// TODO: currently, odd WRITE_LEN won't work.
//       (However, actual WRITE_LEN may be CORE * ~, where CORE is even)

const int READ_LEN   = 16*12*12;
const int WRITE_LEN  = 8*4*4;
// const int READ_LEN   = 1*28*28;
// const int WRITE_LEN  = 8*12*12;
// const int READ_LEN   = 512;
// const int WRITE_LEN  = 16;

// int READ_OFFSET  = 42;
const int READ_OFFSET  = 'ha000;
// const int WRITE_OFFSET = 'h0b00;
const int WRITE_OFFSET = READ_OFFSET + READ_LEN*RATE;

module test_ninjin_ddr_buf;

  parameter DDR_READ  = 'd0;
  parameter DDR_WRITE = 'd1;

  reg                     clk;
  reg                     xrst;
  reg                     pre_req;
  reg [WORDSIZE-1:0]      pre_base;
  reg [LWIDTH-1:0]        read_len;
  reg [LWIDTH-1:0]        write_len;
  reg                     mem_we;
  reg [MEMSIZE-1:0]       mem_addr;
  reg signed [DWIDTH-1:0] mem_wdata;
  reg                     ddr_we;
  reg [WORDSIZE-1:0]      ddr_waddr;
  reg [BWIDTH-1:0]        ddr_wdata;
  reg [WORDSIZE-1:0]      ddr_raddr;

  wire                      pre_ack;
  wire                      ddr_req;
  wire                      ddr_mode;
  wire [WORDSIZE+LSB-1:0]   ddr_base;
  wire [LWIDTH-1:0]         ddr_len;
  wire [BWIDTH-1:0]         ddr_rdata;
  wire signed [DWIDTH-1:0]  mem_rdata;

  wire [2-1:0] probe_state;

  integer _ddr_base [1:0];
  integer _ddr_len [1:0];

  int ddr_read_count  = 0;
  int ddr_write_count = 0;

  let max(a, b) = a > b ? a : b;
  let min(a, b) = a < b ? a : b;

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
    pre_req   = 0;
    pre_base  = 0;
    read_len  = 0;
    write_len = 0;
    mem_we    = 0;
    mem_addr  = 0;
    mem_wdata = 0;
    ddr_we    = 0;
    ddr_waddr = 0;
    ddr_wdata = 0;
    ddr_raddr = 0;
    #(STEP);

    $display("### pre_req");
    setup(READ_OFFSET >> LSB, READ_LEN, WRITE_LEN);

    $display("### reading");
    for (int i = 0; i < READ_LEN; i++) begin
      read(i + (READ_OFFSET >> RATELOG));
      if (i % 14 == 1) #(10*STEP);
      if (dut.switch_buf) #(10*STEP);
    end
    clear;

    $display("### writing");
    for (int i = 0; i < WRITE_LEN; i++)
      write(i + (WRITE_OFFSET >> RATELOG), i + 'h0005);
    clear;

    $display("### reading");
    for (int i = 0; i < READ_LEN; i++) begin
      read(i + (READ_OFFSET >> RATELOG));
      if (i % 14 == 1) #(10*STEP);
    end
    clear;

    $display("### writing");
    for (int i = 0; i < WRITE_LEN; i++)
      write(i + (WRITE_OFFSET >> RATELOG), i + 'h0005);
    clear;

    #(2*BURST_MAX*STEP);

    assert (
      ddr_read_count
      == max((READ_LEN/RATE-BURST_MAX), 0)*2 + min(BURST_MAX, READ_LEN/RATE)
    )
    else
      $error(
        "ddr_read_count not matched @ actual: %h, target: %h",
        ddr_read_count,
        max((READ_LEN/RATE-BURST_MAX), 0)*2 + min(BURST_MAX, READ_LEN/RATE)
      );
    assert (ddr_write_count == (WRITE_LEN/RATE) * 2) else
      $error(
        "ddr_write_count not matched @ actual: %h, target: %h",
        ddr_write_count, (WRITE_LEN/RATE) * 2
      );
    $finish();
  end

// }}}
//==========================================================
// tasks
//==========================================================
// {{{

  task setup
    ( input integer base
    , input integer rlen
    , input integer wlen
    );

    pre_req   = 1;
    pre_base  = base;
    read_len  = rlen;
    write_len = wlen;
    #(STEP);
    pre_req = 0;
    #(STEP);

    #(BURST_MAX*STEP);
    #(STEP);
  endtask

  task clear;
    mem_we    = 0;
    mem_addr  = 0;
    mem_wdata = 0;
    #(2*STEP);
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
// models
//==========================================================
// {{{

  // pseudo ddr
  always @(posedge ddr_req) begin
    #(STEP/2-1);
    if (ddr_mode == DDR_READ) begin
      _ddr_base[DDR_READ] = ddr_base;
      _ddr_len[DDR_READ]  = ddr_len;
      #(STEP);
      for (int i = 0; i < _ddr_len[DDR_READ]; i++) begin
        ddr_we    = 1;
        ddr_waddr = i + (_ddr_base[DDR_READ] >> LSB);
        ddr_wdata = 'h0def000c + ddr_waddr - (READ_OFFSET >> LSB);
        #(STEP);
        ddr_read_count++;
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
      #(STEP);
      for (int i = 0; i < _ddr_len[DDR_WRITE]; i++) begin
        ddr_raddr = i + (_ddr_base[DDR_WRITE] >> LSB);
        #(STEP);
        ddr_write_count++;
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
            assert (mem_rdata == 'h0def)
            else
              $error("read assert failed (odd) @ mem_rdata: %h, target: %h",
                mem_rdata, 'h0def);
          else
            assert (
              mem_rdata == 'h000c + (dut.mem_addr$ - (READ_OFFSET >> RATELOG))/2
            )
            else
              $error("read assert failed (even) @ mem_rdata: %h, target: %h",
                mem_rdata,
                'h000c + (dut.mem_addr$ - (READ_OFFSET >> RATELOG))/2);
        3:
          assert (
            mem_rdata == 'h0005 + dut.mem_addr$ - (WRITE_OFFSET >> RATELOG)
          )
          else
            $error("write assert failed @ mem_rdata: %h, target: %h",
              mem_rdata, 'h0005 + dut.mem_addr$ - (WRITE_OFFSET >> RATELOG));
        default:
          assert(1'b1);
      endcase
    #(STEP/2+1);
  end

  // ddr assert
  reg [MEMSIZE-1:0] ddr_raddr$;
  wire [DWIDTH-1:0]  ddr_offset;
  always @(posedge clk) ddr_raddr$ <= dut.ddr_raddr;
  assign ddr_offset = ddr_raddr$ - (WRITE_OFFSET >> LSB);
  always @(ddr_we, ddr_waddr, ddr_wdata, ddr_raddr, ddr_rdata) begin
    #(STEP/2-1);
    if (ddr_raddr$ != 0)
      assert (ddr_rdata == {
        16'h0005 + (2'h2*ddr_offset+1'h1),
        16'h0005 + (2'h2*ddr_offset)
      })
      else begin
        $error("ddr assert failed @ raddr: %h rdata: %h",
          ddr_raddr$, ddr_rdata);
        $info("expected: %h", {
          16'h0005 + (2'h2*ddr_offset+1'h1),
          16'h0005 + (2'h2*ddr_offset)
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
        "%4x: ", $time/STEP,
        // "%d ", xrst,
        "*%-7p ", dut.state$[0],
        "%d ", dut.mode,
        "%d ", dut.mode$,
        "%d ", dut.count_len$,
        // "%d ", dut.read_len,
        // "%d ", $signed(dut.rest_len),
        "*%3d ", dut.burst_len,
        "*%3d ", dut.burst_len$,
        "%d ", dut.count_buf$,
        // "%3d ", ddr_read_count,
        // "%3d ", ddr_write_count,
        // "| ",
        // "%x ", dut.count_post$,
        // "%x ", dut.switch_post_main,
        // "%x ", dut.switch_post_sub,
        "| ",
        "%x ",  mem_we,
        "%4x ", mem_addr,
        "%x ", mem_wdata,
        "%x ", mem_rdata,
        // "| ",
        // "%x ",  dut.pre_req,
        // "%x ",  dut.pre_base$,
        // "%d ",  dut.read_len$,
        // "%d ",  dut.write_len$,
        // "%x ",  dut.pre_we,
        // "%x ",  dut.pre_addr,
        // ": ",
        // "%x ",  ddr_req,
        // "%x ",  ddr_mode,
        // "%x ",  ddr_base,
        // "%x ",  ddr_len,
        // "| ",
        // "%x ",  ddr_we,
        // "%4x ", ddr_waddr,
        // "%7x ", ddr_wdata,
        // "%4x ", ddr_raddr,
        // "%7x ", ddr_rdata,
        // "| ",
        // "%4x ",  dut.pre_base$ << LSB,
        // "%4x ",  dut.post_base$ << LSB,
        "| ",
        "&%d ", dut.which$,
        "&%d ", dut.mem_which$,
        "&%d ", dut.ddr_which$,
        "%d ",  dut.switch_buf,
        ": ",
        "%x ",  dut.buf_addr$,
        "| ",
        "%x ",  dut.buf_we[0],
        "%x ",  dut.buf_addr[0],
        // "%7x ", dut.buf_wdata[0],
        "%8x ", dut.buf_rdata[0],
        ": ",
        "%4x ",  dut.buf_base$[0],
        "| ",
        "%x ",  dut.buf_we[1],
        "%x ",  dut.buf_addr[1],
        // "%7x ", dut.buf_wdata[1],
        "%8x ", dut.buf_rdata[1],
        ": ",
        "%4x ",  dut.buf_base$[1],
        "| ",
        "%x ",  dut.pre_we,
        "%x ",  dut.pre_addr,
        // "%7x ", dut.pre_wdata,
        "%8x ", dut.pre_rdata,
        "| ",
        "%x ",  dut.post_we,
        "%x ",  dut.post_addr,
        // "%7x ", dut.post_wdata,
        "%8x ", dut.post_rdata,
        "|"
      );
      #(STEP/2+1);
    end
  end

// }}}
endmodule

