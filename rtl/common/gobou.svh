`ifndef _GOBOU_SVH_
`define _GOBOU_SVH_

`include "common.svh"
`include "ctrl_bus.svh"

////////////////////////////////////////////////////////////
// User parameters ( _ for substitution )
////////////////////////////////////////////////////////////
`ifdef DIST
parameter GOBOU_CORE    = _;
parameter GOBOU_CORELOG = _;
parameter GOBOU_NETSIZE = _;
`else
// parameter GOBOU_CORE    = 16;
// parameter GOBOU_CORELOG = 4;
// parameter GOBOU_NETSIZE = 13;
parameter GOBOU_CORE    = 1024;
parameter GOBOU_CORELOG = 4;
parameter GOBOU_NETSIZE = 17;
`endif

////////////////////////////////////////////////////////////
// Delay of each modules
////////////////////////////////////////////////////////////
parameter D_MAC   = 3;

`endif
