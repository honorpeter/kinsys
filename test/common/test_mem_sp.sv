module test_mem_sp;

  localparam STEP    = 10;
  localparam DWIDTH  = 32;
  localparam MEMSIZE = 16;

  reg clk;
  reg mem_we;
  reg [MEMSIZE-1:0] mem_addr;
  reg signed [DWIDTH-1:0] mem_wdata;
  wire signed [DWIDTH-1:0] mem_rdata;

  mem_sp #(DWIDTH, MEMSIZE) dut(.*);

  // clock
  initial begin
    clk = 0;
    forever
      #(STEP/2) clk = ~clk;
  end

  //flow
  initial begin
    init;
    for (int i = 0; i < 16; i++)
      read(i+3000);

    init;
    for (int i = 0; i < 16; i++)
      write(i+3000, i+42);

    init;
    for (int i = 0; i < 16; i++)
      read(i+3000);

    init;
    #(5*STEP);
    $finish();
  end

  task init;
    begin
      mem_we    = 0;
      mem_addr  = 0;
      mem_wdata = 0;
      #(STEP);
    end
  endtask

  task read;
    input integer addr;
    begin
      mem_we    = 0;
      mem_addr  = addr;
      mem_wdata = 0;
      #(STEP);
    end
  endtask

  task write;
    input integer addr;
    input integer wdata;
    begin
      mem_we    = 1;
      mem_addr  = addr;
      mem_wdata = wdata;
      #(STEP);
    end
  endtask

  //display
  initial begin
    $display("clk: |");
    forever begin
      #(STEP/2-1);
      $display(
        "%3d: ", $time/STEP,
        "| ",
        "%d ", mem_we,
        "%d ", mem_addr,
        "%d ", mem_wdata,
        "| ",
        "%d ", mem_rdata,
        "|"
      );
      #(STEP/2+1);
    end
  end

endmodule
