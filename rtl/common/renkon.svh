`ifndef _RENKON_SVH_
`define _RENKON_SVH_

`include "common.svh"
`include "ctrl_bus.svh"
`ifndef DIST
`include "mem_sp.sv"
`include "mem_dp.sv"
`endif

parameter RENKON_CORE    = 8;
// parameter integer RENKON_CORELOG = $clog2(RENKON_CORE);
parameter RENKON_CORELOG = 3;
parameter RENKON_NETSIZE = 10;
parameter FACCUM  = 10; // expected max featuremap size (cf. $clog2(24x24))
parameter OUTSIZE = 10; // expected max output size (cf. $clog2(4x4x32))
parameter FSIZE   = 5;
parameter PSIZE   = 2;

// Delay for each module (corresponds to the number of stages)
parameter D_PIXELBUF = 32; // max size (image height or width)
parameter D_POOLBUF  = 32; // max size (image height or width)
parameter D_CONV     = 5;
parameter D_ACCUM    = 1;
parameter D_POOL     = 2;

`endif
