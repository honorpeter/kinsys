`ifndef _NINJIN_SVH_
`define _NINJIN_SVH_

`include "common.svh"

package renkon;
  `include "renkon.svh"
endpackage

package gobou;
  `include "gobou.svh"
endpackage

parameter PORT = 32;

parameter RENKON_CORE    = renkon::CORE;
parameter RENKON_CORELOG = renkon::CORELOG;
parameter RENKON_NETSIZE = renkon::NETSIZE;

parameter GOBOU_CORE    = gobou::CORE;
parameter GOBOU_CORELOG = gobou::CORELOG;
parameter GOBOU_NETSIZE = gobou::NETSIZE;

`endif
