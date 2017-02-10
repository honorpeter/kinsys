`ifndef _RENKON_SVH_
`define _RENKON_SVH_

`timescale 1ns/1ps
`define DIST

parameter STEP    = 10;
parameter DWIDTH  = 16;
parameter LWIDTH  = 10;
parameter CORE    = 16;
parameter CORELOG = $clog2(CORE);
parameter IMGSIZE = 12;
parameter NETSIZE = 14;
parameter FACCUM  = 10; // expected max featuremap size (cf. $clog2(24x24))
parameter OUTSIZE = 8; // expected max output size (cf. $clog2(4x4x32))
parameter FSIZE   = 5;
parameter PSIZE   = 2;

// Delay for each module (corresponds to the number of stages)
parameter D_PIXELBUF = 32;
parameter D_POOLBUF  = 32;
parameter D_CONV     = 5;
parameter D_ACCUM    = 1;
parameter D_BIAS     = 2;
parameter D_RELU     = 2;
parameter D_POOL     = 2;

`endif
