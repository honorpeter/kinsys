`ifndef _CTRL_BUS_SVH_
`define _CTRL_BUS_SVH_

interface ctrl_bus;
  integer delay;
  wire start;
  wire valid;
  wire ready;
  wire stop;

  modport slave ( input delay
                , input start
                , input valid
                , output ready
                , input stop
                );
  modport master ( output delay
                 , output start
                 , output valid
                 , input ready
                 , output stop
                 );
endinterface

typedef struct {
  reg start;
  reg valid;
  reg stop;
} ctrl_reg;

`endif
