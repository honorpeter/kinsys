`ifndef _MEM_DP_SV_
`define _MEM_DP_SV_

// Standard simple dual port memory definition
module mem_dp
 #( parameter DWIDTH  = 16
  , parameter MEMSIZE = 8
  )
  ( input                       clk
  , input                       mem_we1
  , input                       mem_we2
  , input         [MEMSIZE-1:0] mem_addr1
  , input         [MEMSIZE-1:0] mem_addr2
  , input  signed [DWIDTH-1:0]  mem_wdata1
  , input  signed [DWIDTH-1:0]  mem_wdata2
  , output signed [DWIDTH-1:0]  mem_rdata1
  , output signed [DWIDTH-1:0]  mem_rdata2
  );

  localparam WORDS = 2 ** MEMSIZE;

  reg signed [DWIDTH-1:0]   mem [WORDS-1:0];
  reg        [MEMSIZE-1:0]  addr1$;
  reg        [MEMSIZE-1:0]  addr2$;

  assign mem_rdata1 = mem[addr1$];
  assign mem_rdata2 = mem[addr2$];

  always @(posedge clk) begin
    if (mem_we1)
      mem[mem_addr1] <= mem_wdata1;
    addr1$ <= mem_addr1;
  end

  always @(posedge clk) begin
    // if (mem_we2)
    //   mem[mem_addr2] <= mem_wdata2;
    addr2$ <= mem_addr2;
  end

  initial
    for (int i = 0; i < WORDS; i++)
      mem[i] = 0;

endmodule

`endif
