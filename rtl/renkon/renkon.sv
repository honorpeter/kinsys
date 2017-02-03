`include "renkon.svh"
`include "mem_sp.sv"

module renkon
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
  , input [LWIDTH-1:0]        img_size
  , input [LWIDTH-1:0]        fil_size
  , input [LWIDTH-1:0]        pool_size
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

  wire signed [DWIDTH-1:0] read_net [CORE-1:0];

`ifndef DIST
  mem_sp #(DWIDTH, IMGSIZE) mem_img(
  );
`endif

  for (genvar i = 0; i < CORE; i++) begin : pe
    mem_sp #(DWIDTH, NETSIZE) mem_net(
      .read_data  (read_net[i]),
      .write_data (write_net),
      .mem_we     (mem_net_we[i]),
      .mem_addr   (mem_net_addr),
      .*
    );

    core core(
      .read_net     (read_net[i]),
      .pixel        (pixel),
      .pmap         (pmap[i]),
      .*
    );
  end : pe

  serial_mat serial(.*);

endmodule
