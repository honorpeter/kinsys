`timescale 1ns/1ps
// `define DIST

parameter STEP    = 10;
parameter DWIDTH  = 16;
parameter LWIDTH  = 12;
parameter CORE    = 8;
parameter CORELOG = $clog2(CORE);
parameter IMGSIZE = 12;
parameter NETSIZE = 14;

parameter D_MAC   = 3;
parameter D_BIAS  = 2;
parameter D_RELU  = 2;
