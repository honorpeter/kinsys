`ifndef _COMMON_SVH_
`define _COMMON_SVH_

`default_nettype wire
`timescale 1 ns / 1 ps
// `define DIST

parameter STEP    = 10;
parameter DWIDTH  = 16;
parameter LWIDTH  = 16;
`ifndef DIST
parameter IMGSIZE = 16;
`else
// parameter IMGSIZE = BWIDTH - $clog2(DWIDTH/8);
parameter IMGSIZE = 31; // Number of DWIDTH entry
`endif


parameter D_BIAS     = 2;
parameter D_RELU     = 2;

function integer clogb2 (input integer bit_depth);
  begin
    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
      bit_depth = bit_depth >> 1;
  end
endfunction

`endif
