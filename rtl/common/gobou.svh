`ifndef _GOBOU_SVH_
`define _GOBOU_SVH_

`include "common.svh"

parameter CORE    = 16;
parameter CORELOG = $clog2(CORE);
// parameter NETSIZE = 14;
parameter NETSIZE = 15;

// Delay for each module (corresponds to the number of stages)
parameter D_MAC   = 3;
parameter D_BIAS  = 2;
parameter D_RELU  = 2;

`endif
