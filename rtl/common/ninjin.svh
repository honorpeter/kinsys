`ifndef _NINJIN_SVH_
`define _NINJIN_SVH_

`include "common.svh"

// BWIDTH ~ base width (memory bandwidth for host system.)
parameter BWIDTH  = 32;

// parameter RATE    = BWIDTH / DWIDTH;
parameter RATE    = 2;
// parameter RATELOG = $clog2(RATE);
parameter RATELOG = 1;

parameter REGSIZE = 6;
// parameter PORT  = 2 ** REGSIZE;
parameter PORT    = 64;

parameter LSB     = 2;
`ifndef DIST
parameter WORDSIZE = MEMSIZE - RATELOG;
`else
// parameter WORDSIZE = MEMSIZE - RATELOG;
parameter WORDSIZE = 30;
`endif

parameter BUFSIZE   = 8;
parameter BURST_MAX = 256;
// parameter BURST_MAX = 2 ** BUFSIZE;
// parameter BUFSIZE   = $clog2(BURST_MAX);

parameter DDR_READ  = 'd0;
parameter DDR_WRITE = 'd1;

/* which:
 *   0: renkon  (2D convolution)
 *   1: gobou   (1D linear)
 *   2: ninjin  (Interface)
 */
parameter WHICH_RENKON = 'd0;
parameter WHICH_GOBOU  = 'd1;
parameter WHICH_NINJIN = 'd2;

`endif
