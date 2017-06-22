`ifndef _NINJIN_SVH_
`define _NINJIN_SVH_

`include "common.svh"
`ifndef DIST
`include "mem_sp.sv"
`include "mem_dp.sv"
`endif

// BWIDTH ~ base width (memory bandwidth for host system.)
parameter BWIDTH  = 32;
parameter REGSIZE = 5;

parameter LSB   = 2;
// parameter PORT  = 2 ** REGSIZE;
parameter PORT  = 32;

parameter BURST_LEN = 16;
parameter BUFSIZE   = 4;
// parameter BURST_LEN = 256;
// parameter BUFSIZE   = 8;
// parameter BUFSIZE   = $clog2(BURST_LEN);

parameter DDR_READ = 'd0;
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
