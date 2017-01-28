`include "gobou/gobou.svh"
`include "common/ctrl_bus.sv"

module ctrl
  ( input clk
  , input xrst
  , input req
  , output ack
  );

  ctrl_bus bus_core;
  ctrl_bus bus_mac;
  ctrl_bus bus_bias;
  ctrl_bus bus_relu;

  ctrl_core ctrl_core(
    .in_ctrl  (bus_relu),
    .out_ctrl (bus_core),
    .*
  );

  ctrl_mac ctrl_mac(
    .in_ctrl  (bus_core),
    .out_ctrl (bus_mac),
    .*
  );

  ctrl_bias ctrl_bias(
    .in_ctrl  (bus_mac),
    .out_ctrl (bus_bias),
    .*
  );

  ctrl_relu ctrl_relu(
    .in_ctrl  (bus_bias),
    .out_ctrl (bus_relu),
    .*
  );

endmodule
