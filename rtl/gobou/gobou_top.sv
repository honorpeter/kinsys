`include "gobou.svh"

module gobou_top
  ( input                       clk
  , input                       xrst
  , input                       req
  , input  [DWIDTHLOG-1:0]      qbits
`ifdef QUANT
  , input  signed [DWIDTH-1:0]  w_scale
  , input  signed [DWIDTH-1:0]  w_offset
  , input  signed [DWIDTH-1:0]  b_scale
  , input  signed [DWIDTH-1:0]  b_offset
`endif
  , input  signed [DWIDTH-1:0]  img_rdata
  , input  [GOBOU_CORELOG-1:0]  net_sel
  , input                       net_we
  , input  [GOBOU_NETSIZE-1:0]  net_addr
`ifdef QUANT
  , input  [QWIDTH-1:0]         net_wdata
  // , input  signed [QWIDTH-1:0]  net_wdata
`else
  , input  signed [DWIDTH-1:0]  net_wdata
`endif
  , input  [MEMSIZE-1:0]        in_offset
  , input  [MEMSIZE-1:0]        out_offset
  , input  [GOBOU_NETSIZE-1:0]  net_offset

  // Network parameters
  , input  [LWIDTH-1:0]         total_out
  , input  [LWIDTH-1:0]         total_in
  , input                       bias_en
  , input                       relu_en

  , output                      ack
  , output                      img_we
  , output [MEMSIZE-1:0]        img_addr
  , output signed [DWIDTH-1:0]  img_wdata
  );

  wire [GOBOU_CORE-1:0]     mem_net_we;
  wire [GOBOU_NETSIZE-1:0]  mem_net_addr;
  wire signed [DWIDTH-1:0]  net_rdata [GOBOU_CORE-1:0];
  wire signed [DWIDTH-1:0]  result    [GOBOU_CORE-1:0];
  wire signed [DWIDTH-1:0]  out_wdata;
  wire                      breg_we;
  wire                      serial_we;
  wire                      mac_oe;
  wire                      accum_we;
  wire                      accum_rst;
  wire [DWIDTHLOG-1:0]      _qbits;
  wire                      _bias_en;
  wire                      bias_oe;
  wire                      _relu_en;
  wire                      relu_oe;

`ifdef QUANT
  wire signed [DWIDTH-1:0]  net_quant [GOBOU_CORE-1:0];
`endif

  gobou_ctrl ctrl(.*);

  for (genvar i = 0; i < GOBOU_CORE; i++) begin : pe
`ifdef QUANT
    mem_sp #(QWIDTH, GOBOU_NETSIZE) mem_net(
      .mem_we     (mem_net_we[i]),
      .mem_addr   (mem_net_addr),
      .mem_wdata  (net_wdata),
      .mem_rdata  (net_quant[i]),
      .*
    );

    dequant #(DWIDTH, QWIDTH) deq(
      .which  (breg_we),
      .x      (net_quant[i]),
      .y      (net_rdata[i]),
      .*
    );
`else
    mem_sp #(DWIDTH, GOBOU_NETSIZE) mem_net(
      .mem_we     (mem_net_we[i]),
      .mem_addr   (mem_net_addr),
      .mem_wdata  (net_wdata),
      .mem_rdata  (net_rdata[i]),
      .*
    );
`endif

    gobou_core core(
      .pixel  (img_rdata),
      .weight (net_rdata[i]),
      .result (result[i]),
      .*
    );
  end : pe

  gobou_serial_vec serial(
    .in_data  (result),
    .out_data (out_wdata),
    .*
  );

endmodule
