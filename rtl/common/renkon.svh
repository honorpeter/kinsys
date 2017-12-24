`ifndef _RENKON_SVH_
`define _RENKON_SVH_

`include "common.svh"
`include "ctrl_bus.svh"

////////////////////////////////////////////////////////////
// User parameters ( $_ for substitution )
////////////////////////////////////////////////////////////
`ifdef DIST
parameter RENKON_CORE    = _;
parameter RENKON_CORELOG = _;
parameter RENKON_NETSIZE = _;
parameter RENKON_MAXIMG  = _;
`else
parameter RENKON_CORE    = 8;
parameter RENKON_CORELOG = 3;
parameter RENKON_NETSIZE = 11;
parameter RENKON_MAXIMG  = 32;
`endif

// expected max featuremap size (cf. $clog2(24x24))
parameter FACCUM  = $clog2(RENKON_MAXIMG**2);
parameter OUTSIZE = FACCUM;
parameter FSIZE   = 3;
// parameter PAD     = 0;
parameter PAD     = (FSIZE-1)/2;
parameter PSIZE   = 2;

////////////////////////////////////////////////////////////
// Delay of each modules
////////////////////////////////////////////////////////////
// max size (image height or width)
parameter D_PIXELBUF = RENKON_MAXIMG;
// max size (image height or width)
parameter D_POOLBUF  = RENKON_MAXIMG;
// FSIZE = 5
// parameter D_CONV     = 5;
// FSIZE = 3
parameter D_CONV     = 4;
parameter D_ACCUM    = 1;
parameter D_POOL     = 2;

`endif
