`ifndef _CTRL_BUS_SVH_
`define _CTRL_BUS_SVH_

interface ctrl_bus;
  wire start;
  wire valid;
  wire stop;

  modport slave ( input start
                , input valid
                , input stop
                );
  modport master ( output start
                 , output valid
                 , output stop
                 );
endinterface

typedef struct {
  reg start;
  reg valid;
  reg stop;
} ctrl_reg;

`endif
