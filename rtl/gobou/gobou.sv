module gobou
  ( input                     clk
  , input                     xrst
  , input                     req
  , input                     img_we
  , input [IMGSIZE-1:0]       input_addr
  , input [IMGSIZE-1:0]       output_addr
  , input signed [DWIDTH-1:0] write_img
  , input [CORELOG:0]         net_we
  , input [NETSIZE-1:0]       net_addr
  , input signed [DWIDTH-1:0] write_net
  , input [LWIDTH-1:0]        total_out
  , input [LWIDTH-1:0]        total_in
`ifdef DIST
  , input signed [DWIDTH-1:0] read_img
`endif
  , output                      ack
`ifdef DIST
  , output                      mem_img_we
  , output [IMGSIZE-1:0]        mem_img_addr
  , output signed [DWIDTH-1:0]  write_mem_img
`else
  , output signed [DWIDTH-1:0]  read_img
`endif
  );

endmodule
