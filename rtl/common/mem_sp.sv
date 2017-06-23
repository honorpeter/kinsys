`ifndef _MEM_SP_SV_
`define _MEM_SP_SV_

// Standard single port memory definition
module mem_sp
 #( parameter DWIDTH  = 16
  , parameter MEMSIZE = 8
  )
  ( input                       clk
  , input                       mem_we
  , input         [MEMSIZE-1:0] mem_addr
  , input  signed [DWIDTH-1:0]  mem_wdata
  , output signed [DWIDTH-1:0]  mem_rdata
  );

  localparam WORDS = 2 ** MEMSIZE;

  reg signed [DWIDTH-1:0] mem [WORDS-1:0];
  reg [MEMSIZE-1:0]       addr$;

  assign mem_rdata = mem[addr$];

  always @(posedge clk) begin
    if (mem_we)
      mem[mem_addr] <= mem_wdata;
    addr$ <= mem_addr;
  end

  initial
    for (int i = 0; i < WORDS; i++)
      mem[i] = 0;

endmodule

`endif
