`include "gobou.svh"

module gobou_core
  ( input                     clk
  , input                     xrst
  , input                     mac_oe
  , input                     accum_rst
  , input                     accum_we
  , input                     breg_we
  , input                     bias_oe
  , input                     relu_oe
  , input signed [DWIDTH-1:0] pixel
  , input signed [DWIDTH-1:0] weight
  , output signed [DWIDTH-1:0] result
  );

  wire signed [DWIDTH-1:0] biased;
  wire signed [DWIDTH-1:0] dotted;

  gobou_mac mac(
    .out_en   (mac_oe),
    .accum_we (accum_we),
    .reset    (accum_rst),
    .x        (pixel),
    .w        (weight),
    .y        (dotted),
    .*
  );

  gobou_bias bias(
    .read_bias  (weight),
    .breg_we    (breg_we),
    .out_en     (bias_oe),
    .pixel_in   (dotted),
    .pixel_out  (biased),
    .*
  );

  gobou_relu relu(
    .out_en     (relu_oe),
    .pixel_in   (biased),
    .pixel_out  (result),
    .*
  );

endmodule
