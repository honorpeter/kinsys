`include "gobou.svh"

module gobou_core
  ( input                       clk
  , input                       xrst
  , input                       mac_oe
  , input                       accum_rst
  , input                       accum_we
  , input                       breg_we
  , input                       bias_oe
  , input                       relu_oe
  , input  signed [DWIDTH-1:0]  pixel
  , input  signed [DWIDTH-1:0]  weight
  , output signed [DWIDTH-1:0]  avec
  );

  wire signed [DWIDTH-1:0] fvec;
  wire signed [DWIDTH-1:0] bvec;

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
    .read_bias  (weight),
    .breg_we    (breg_we),
    .out_en     (bias_oe),
    .pixel_in   (fvec),
    .pixel_out  (bvec),
    .*
  );

  gobou_relu relu(
    .out_en     (relu_oe),
    .pixel_in   (bvec),
    .pixel_out  (avec),
    .*
  );

endmodule
