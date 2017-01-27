module core
 #( parameter DWIDTH = 16
  )
  (
  , output signed [DWIDTH-1:0] result
  );

  mac mac(
    .out_en   (mac_oe),
    .accum_we (accum_we),
    .reset    (accum_rst),
    .x        (pixel[DWIDTH-1:0]),
    .w        (weight[DWIDTH-1:0]),
    .y        (dotted[DWIDTH-1:0]),
    .*
  );

  bias bias(
    .read_bias  (weight[DWIDTH-1:0]),
    .breg_we    (breg_we),
    .out_en     (bias_oe),
    .pixel_in   (dotted[DWIDTH-1:0]),
    .pixel_out  (biased[DWIDTH-1:0]),
    .*
  );

  relu relu(
    .out_en     (relu_oe),
    .pixel_in   (biased[DWIDTH-1:0]),
    .pixel_out  (result[DWIDTH-1:0]),
    .*
  );

endmodule
