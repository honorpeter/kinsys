`ifndef _GOBOU_SVH_
`define _GOBOU_SVH_

`include "common.svh"
`include "ctrl_bus.svh"
`ifndef DIST
`include "mem_sp.sv"
`endif

parameter GOBOU_CORE    = 16;
// parameter integer GOBOU_CORELOG = $clog2(GOBOU_CORE);
parameter GOBOU_CORELOG = 4;
parameter GOBOU_NETSIZE = 10;

// Delay for each module (corresponds to the number of stages)
parameter D_MAC   = 3;

`endif
