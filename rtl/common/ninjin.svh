`ifndef _NINJIN_SVH_
`define _NINJIN_SVH_

`timescale 1 ns / 1 ps

parameter PORT = 32;

package renkon;
  `include "renkon.svh"
  `include "renkon/renkon.sv"
  `include "renkon/ctrl.sv"
  `include "renkon/ctrl_core.sv"
  `include "renkon/ctrl_conv.sv"
  `include "renkon/ctrl_bias.sv"
  `include "renkon/ctrl_relu.sv"
  `include "renkon/ctrl_pool.sv"
  `include "renkon/linebuf.sv"
  `include "renkon/core.sv"
  `include "renkon/conv.sv"
  `include "renkon/conv_tree25.sv"
  `include "renkon/conv_wreg.sv"
  `include "renkon/accum.sv"
  `include "renkon/bias.sv"
  `include "renkon/relu.sv"
  `include "renkon/pool.sv"
  `include "renkon/pool_max4.sv"
  `include "renkon/serial_mat.sv"
  `include "renkon/mux_output.sv"
endpackage

package gobou;
  `include "gobou.svh"
  `include "gobou/gobou.sv"
  `include "gobou/ctrl.sv"
  `include "gobou/ctrl_core.sv"
  `include "gobou/ctrl_mac.sv"
  `include "gobou/ctrl_bias.sv"
  `include "gobou/ctrl_relu.sv"
  `include "gobou/core.sv"
  `include "gobou/mac.sv"
  `include "gobou/bias.sv"
  `include "gobou/relu.sv"
  `include "gobou/serial_vec.sv"
endpackage

package common;
  `include "mem_sp.sv"
  `include "mem_dp.sv"
endpackage

`endif
