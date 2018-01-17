`ifndef _COMMON_SVH_
`define _COMMON_SVH_

`default_nettype wire
`timescale 1 ns / 1 ps
// DIST will be defined when distributed
`undef DIST
`define QUANT

`ifndef DIST
`include "mem_sp.sv"
`include "mem_dp.sv"
`include "dequant.sv"
`endif

parameter STEP      = 10;
parameter DWIDTH    = 16;
parameter DWIDTHLOG = 4;
parameter LWIDTH    = 16;
// parameter QWIDTH    = 8;
parameter QWIDTH    = 16;

////////////////////////////////////////////////////////////
// User parameters
////////////////////////////////////////////////////////////
`ifdef DIST
parameter MEMSIZE = 31; // Number of DWIDTH entry
`else
// parameter MEMSIZE = BWIDTH - $clog2(DWIDTH/8);
parameter MEMSIZE = 15;
`endif


////////////////////////////////////////////////////////////
// Delay of common modules
////////////////////////////////////////////////////////////
parameter D_BIAS = 2;
parameter D_RELU = 2;

////////////////////////////////////////////////////////////
// utility definitions
////////////////////////////////////////////////////////////
function integer clogb2 (input integer bit_depth);
  begin
    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
      bit_depth = bit_depth >> 1;
  end
endfunction

`endif
