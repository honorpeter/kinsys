`ifndef _GOBOU_SVH_
`define _GOBOU_SVH_

`timescale 1ns/1ps
`define DIST

parameter STEP    = 10;
parameter DWIDTH  = 16;
parameter LWIDTH  = 10;
parameter CORE    = 16;
parameter CORELOG = $clog2(CORE);
parameter IMGSIZE = 12;
parameter NETSIZE = 15;

parameter D_MAC   = 3;
parameter D_BIAS  = 2;
parameter D_RELU  = 2;

`endif
