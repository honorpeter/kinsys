`include "ninjin.svh"

module test_ninjin_ddr_buf;

  reg                     clk;
  reg                     xrst;
  reg [LWIDTH-1:0]        total_len;
  reg                     mem_we;
  reg [MEMSIZE-1:0]       mem_addr;
  reg signed [DWIDTH-1:0] mem_wdata;
  reg [BWIDTH-1:0]        ddr_rdata;
  wire                      ddr_we;
  wire                      ddr_re;
  wire [MEMSIZE-1:0]        ddr_addr;
  wire [BWIDTH-1:0]         ddr_wdata;
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
    xrst = 0;
    #(STEP);

    xrst      = 1;
    mem_we    = 0;
    mem_addr  = 0;
    mem_wdata = 0;
    #(STEP);

    mem_we = 0;
    for (int i = 0; i < READ_REN; i++) begin
      mem_addr  = i + READ_OFFSET;
      mem_wdata = 0;
      #(STEP);
    end
    mem_we    = 0;
    mem_addr  = 0;
    mem_wdata = 0;
    #(STEP);

    mem_we = 1;
    for (int i = 0; i < WRITE_LEN; i++) begin
      mem_addr  = i + WRITE_OFFSET;
      mem_wdata = i;
      #(STEP);
    end
    mem_we    = 0;
    mem_addr  = 0;
    mem_wdata = 0;
    #(STEP);

    $finish();
  end

  //display
  initial begin
    $display("clk: |");
    forever begin
      #(STEP/2-1);
      $display(
        "%d: ", $time/STEP,
        "| ",
        "%d ", mem_we,
        "%d ", mem_addr,
        "%d ", mem_wdata,
        "%d ", mem_rdata,
        "| ",
        "%d ", ddr_we,
        "%d ", ddr_re,
        "%d ", ddr_addr,
        "%d ", ddr_wdata,
        "%d ", ddr_rdata,
        "|"
      );
      #(STEP/2+1);
    end
  end

endmodule
