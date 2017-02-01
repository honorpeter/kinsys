`include "gobou.svh"
`include "mem_sp.sv"

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

`ifndef DIST
  wire                      mem_img_we;
  wire        [IMGSIZE-1:0] mem_img_addr;
  wire signed [DWIDTH-1:0]  write_mem_img;
`endif

  wire         [CORE-1:0]   mem_net_we;
  wire        [NETSIZE-1:0] mem_net_addr;
  wire signed [DWIDTH-1:0]  read_net   [CORE-1:0];
  wire signed [DWIDTH-1:0]  result     [CORE-1:0];
  wire signed [DWIDTH-1:0]  write_result;
  wire                      breg_we;
  wire                      serial_we;
  wire                      mac_oe;
  wire                      accum_we;
  wire                      accum_rst;
  wire                      bias_oe;
  wire                      relu_oe;

  ctrl ctrl(.*);

`ifndef DIST
  mem_sp #(DWIDTH, IMGSIZE) mem_img(
    .read_data  (read_img),
    .write_data (write_mem_img),
    .mem_we     (mem_img_we),
    .mem_addr   (mem_img_addr),
    .*
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
      .pixel  (read_img),
      .weight (read_net[i]),
      .result (result[i]),
      .*
    );
  end : pe

  serial_vec serial(
    .in_data  (result),
    .out_data (write_result),
    .*
  );

endmodule
