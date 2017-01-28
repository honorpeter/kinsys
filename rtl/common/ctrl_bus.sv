interface ctrl_bus;
  wire start;
  wire valid;
  wire stop;

  modport in  ( input start
              , input valid
              , input stop
              );
  modport out ( output start
              , output valid
              , output stop
              );
endinterface

typedef struct {
  reg start;
  reg valid;
  reg stop;
} ctrl_reg;
