module mem_sp
 #( parameter DWIDTH  = 16
  , parameter MEMSIZE = 8
  )
  ( input                       clk
  , input                       mem_we
  , input         [MEMSIZE-1:0] mem_addr
  , input  signed [DWIDTH-1:0]  write_data
  , output signed [DWIDTH-1:0]  read_data
  );

  localparam WORDS = 2 ** MEMSIZE;

  reg signed [DWIDTH-1:0] mem [WORDS-1:0];
  reg [MEMSIZE-1:0]       r_addr;

  assign read_data = mem[r_addr];

  always @(posedge clk) begin
    if (mem_we)
      mem[mem_addr] <= write_data;
    r_addr <= mem_addr;
  end

  initial
    for (int i = 0; i < WORDS; i++)
      mem[i] = 0;

endmodule
