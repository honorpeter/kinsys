`ifndef _NINJIN_SVH_
`define _NINJIN_SVH_

`include "common.svh"

parameter REGSIZE = 5;
parameter MEMSIZE = 10;
parameter BUFSIZE = 7;

parameter LSB   = 2;
parameter PORT  = 32;

/* which:
 *   0: renkon  (2D convolution)
 *   1: gobou   (1D linear)
 *   2: ninjin  (Interface)
 */
parameter WHICH_RENKON = 'd0;
parameter WHICH_GOBOU  = 'd1;
parameter WHICH_NINJIN = 'd2;

`endif
