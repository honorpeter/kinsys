`ifndef _DEQUANT_SV_
`define _DEQUANT_SV_

module dequant
 #( parameter DWIDTH  = 16
  , parameter QWIDTH  = 8
  )
  ( input                       clk
  , input                       xrst
  , input                       req
  , input                       which
  , input  signed [DWIDTH-1:0]  w_scale
  , input  signed [DWIDTH-1:0]  w_offset
  , input  signed [DWIDTH-1:0]  b_scale
  , input  signed [DWIDTH-1:0]  b_offset
  // , input  [QWIDTH-1:0]         x
  , input  signed [QWIDTH-1:0]  x
  , output signed [DWIDTH-1:0]  y
  );

  localparam QBITS = 8;
  wire signed [DWIDTH+QWIDTH-1:0] z;

  wire signed [DWIDTH-1:0]  scale;
  wire signed [DWIDTH-1:0]  offset;

  reg  signed [DWIDTH-1:0]  scale$ [1:0];
  reg  signed [DWIDTH-1:0]  offset$ [1:0];

  assign scale  = scale$[which];
  assign offset = offset$[which];

  assign z = x * scale;
  assign y = (z >>> QBITS) + offset;

  always @(posedge clk)
    if (!xrst) begin
      scale$[0]  <= 0;
      offset$[0] <= 0;
      scale$[1]  <= 0;
      offset$[1] <= 0;
    end
    else begin
      scale$[0]  <= w_scale;
      offset$[0] <= w_offset;
      scale$[1]  <= b_scale;
      offset$[1] <= b_offset;
    end

endmodule

`endif
