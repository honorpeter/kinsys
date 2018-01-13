`include "gobou.svh"

module gobou_core
  ( input                       clk
  , input                       xrst
  , input                       mac_oe
  , input                       accum_rst
  , input                       accum_we
  , input  [DWIDTHLOG-1:0]      _qbits
  , input                       _bias_en
  , input                       breg_we
  , input                       bias_oe
  , input                       _relu_en
  , input                       relu_oe
  , input  signed [DWIDTH-1:0]  pixel
  , input  signed [DWIDTH-1:0]  weight
  , output signed [DWIDTH-1:0]  result
  );

  wire signed [DWIDTH-1:0] fvec;
  wire signed [DWIDTH-1:0] bvec;
  wire signed [DWIDTH-1:0] avec;

  assign result = avec;

  gobou_mac mac(
    .out_en   (mac_oe),
    .accum_we (accum_we),
    .reset    (accum_rst),
    .x        (pixel),
    .w        (weight),
    .y        (fvec),
    .*
  );

  gobou_bias bias(
    .enable     (_bias_en),
    .read_bias  (weight),
    .breg_we    (breg_we),
    .out_en     (bias_oe),
    .pixel_in   (fvec),
    .pixel_out  (bvec),
    .*
  );

  gobou_relu relu(
    .enable     (_relu_en),
    .out_en     (relu_oe),
    .pixel_in   (bvec),
    .pixel_out  (avec),
    .*
  );

endmodule
