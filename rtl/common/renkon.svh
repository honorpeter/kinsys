`ifndef _RENKON_SVH_
`define _RENKON_SVH_

`include "common.svh"
`include "ctrl_bus.svh"
////////////////////////////////////////////////////////////
// User parameters ( $_ for substitution )
////////////////////////////////////////////////////////////
`ifdef DIST
parameter RENKON_CORE     = _;
parameter RENKON_CORELOG  = _;
parameter RENKON_NETSIZE  = _;
parameter RENKON_IMGH_MAX = _;
parameter RENKON_IMGW_MAX = _;
parameter RENKON_FEAH_MAX = _;
parameter RENKON_FEAW_MAX = _;
parameter RENKON_OUTH_MAX = _;
parameter RENKON_OUTW_MAX = _;
`else
parameter RENKON_CORE     = 8;
parameter RENKON_CORELOG  = 3;
parameter RENKON_NETSIZE  = 11;
parameter RENKON_IMGH_MAX = 32;
parameter RENKON_IMGW_MAX = 32;
parameter RENKON_FEAH_MAX = 28;
parameter RENKON_FEAW_MAX = 28;
parameter RENKON_OUTH_MAX = 14;
parameter RENKON_OUTW_MAX = 14;
`endif

// parameter CONV_MAX   = 3;
parameter CONV_MAX   = 5;
// parameter POOL_MAX   = 2;
parameter POOL_MAX   = 3;

// expected max featuremap size (cf. $clog2(24x24))
parameter FEASIZE = $clog2(RENKON_FEAH_MAX * RENKON_FEAW_MAX);
parameter OUTSIZE = $clog2(RENKON_OUTH_MAX * RENKON_OUTW_MAX);

////////////////////////////////////////////////////////////
// Delay of each modules
////////////////////////////////////////////////////////////
// max size (image height or width)
parameter D_PIXELBUF = RENKON_IMGW_MAX;
// max size (image height or width)
parameter D_POOLBUF  = RENKON_IMGW_MAX;
// CONV_MAX = 5
parameter D_CONV     = 5;
// CONV_MAX = 3
// parameter D_CONV     = 4;
parameter D_ACCUM    = 1;
parameter D_POOL     = 2;

`endif
