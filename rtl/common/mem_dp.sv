`ifndef _MEM_DP_SV_
`define _MEM_DP_SV_

module mem_dp
 #( parameter DWIDTH  = 16
  , parameter MEMSIZE = 8
  )
  ( input                       clk
  , input                       mem_we1
  , input                       mem_we2
  , input         [MEMSIZE-1:0] mem_addr1
  , input         [MEMSIZE-1:0] mem_addr2
  , input  signed [DWIDTH-1:0]  write_data1
  , input  signed [DWIDTH-1:0]  write_data2
  , output signed [DWIDTH-1:0]  read_data1
  , output signed [DWIDTH-1:0]  read_data2
  );

  localparam WORDS = 2 ** MEMSIZE;

  reg signed [DWIDTH-1:0] mem [WORDS-1:0];
  reg [MEMSIZE-1:0]        r_addr1;
  reg [MEMSIZE-1:0]        r_addr2;

  assign read_data1 = mem[r_addr1];
  assign read_data2 = mem[r_addr2];

  always @(posedge clk) begin
    if (mem_we1)
      mem[mem_addr1] <= write_data1;
    r_addr1 <= mem_addr1;
  end

  always @(posedge clk) begin
    // if (mem_we2)
    //   mem[mem_addr2] <= write_data2;
    r_addr2 <= mem_addr2;
  end

  initial
    for (int i = 0; i < WORDS; i++)
      mem[i] = 0;

endmodule

`endif
