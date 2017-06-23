////////////////////////////////////////////////////////////
// !!! This module is no longer maintenanced.
// !!! Use upward compatible version.
////////////////////////////////////////////////////////////

`include "ninjin.svh"

module ninjin_s_axi_lite
 #( parameter DATA_WIDTH  = 32
  , parameter ADDR_WIDTH  = 7
  )
  ( input                     clk
  , input                     xrst
  , input  [ADDR_WIDTH-1:0]   awaddr
  , input  [2:0]              awprot
  , input                     awvalid
  , input  [DATA_WIDTH-1:0]   wdata
  , input  [DATA_WIDTH/8-1:0] wstrb
  , input                     wvalid
  , input                     bready
  , input                     arvalid
  , input  [ADDR_WIDTH-1:0]   araddr
  , input  [2:0]              arprot
  , input                     rready
  , input  [DATA_WIDTH-1:0]   out_port[PORT-1:PORT/2]
  , output                    awready
  , output                    wready
  , output                    bvalid
  , output [1:0]              bresp
  , output                    arready
  , output                    rvalid
  , output [DATA_WIDTH-1:0]   rdata
  , output [1:0]              rresp
  , output [DATA_WIDTH-1:0]   in_port[PORT/2-1:0]
  );

  wire                  port_we;
  wire                  port_re;
  wire [DATA_WIDTH-1:0] mux [ADDR_WIDTH-LSB-1:0];

  reg                   awready$;
  reg  [ADDR_WIDTH-1:0] awaddr$;
  reg                   wready$;
  reg                   bvalid$;
  reg  [1:0]            bresp$;
  reg                   arready$;
  reg  [ADDR_WIDTH-1:0] araddr$;
  reg                   rvalid$;
  reg  [DATA_WIDTH-1:0] rdata$;
  reg  [1:0]            rresp$;
  reg  [DATA_WIDTH-1:0] port$ [PORT-1:0];

//==========================================================
// write address control
//==========================================================

  assign awready = awready$;

  always @(posedge clk)
    if (!xrst)
      awready$ <= 0;
    else
      if (!awready$ && awvalid && wvalid)
        awready$ <= 1;
      else
        awready$ <= 0;

  always @(posedge clk)
    if (!xrst)
      awaddr$ <= 0;
    else
      if (!awready$ && awvalid && wvalid)
        awaddr$ <= awaddr;

//==========================================================
// write data control
//==========================================================

  assign wready = wready$;

  always @(posedge clk)
    if (!xrst)
      wready$ <= 0;
    else
      if (!wready$ && awvalid && wvalid)
        wready$ <= 1;
      else
        wready$ <= 0;

//==========================================================
// write response control
//==========================================================

  assign bvalid = bvalid$;
  assign bresp  = bresp$;

  always @(posedge clk)
    if (!xrst)
      bvalid$ <= 0;
    else
      if (awready$ && awvalid && !bvalid$ && wready$ && wvalid)
        bvalid$ <= 1;
      else if (bready && bvalid$)
        bvalid$ <= 0;

  always @(posedge clk)
    if (!xrst)
      bresp$ <= 0;
    else
      if (awready$ && awvalid && !bvalid$ && wready$ && wvalid)
        bresp$ <= 0; // "OKAY" response

//==========================================================
// read address control
//==========================================================

  assign arready = arready$;

  always @(posedge clk)
    if (!xrst)
      arready$ <= 0;
    else
      if (!arready$ && arvalid)
        arready$ <= 1;
      else
        arready$ <= 0;

  always @(posedge clk)
    if (!xrst)
      araddr$ <= 0;
    else
      if (!arready$ && arvalid)
        araddr$ <= araddr;

//==========================================================
// read data control
//==========================================================

  assign rvalid = rvalid$;
  assign rdata  = rdata$;
  assign rresp  = rresp$;

  always @(posedge clk)
    if (!xrst)
      rvalid$ <= 0;
    else
      if (arready$ && arvalid && !rvalid$)
        rvalid$ <= 1;
      else if (rvalid && rready)
        rvalid$ <= 0;

  for (genvar i = 0; i < 2**(ADDR_WIDTH-LSB); i++)
    if (i < PORT)
      assign mux[i] = port$[i];
    else
      assign mux[i] = 0;

  always @(posedge clk)
    if (!xrst)
      rdata$ <= 0;
    else if (port_re)
      rdata$ <= mux[araddr$[ADDR_WIDTH-1:LSB]];

  always @(posedge clk)
    if (!xrst)
      rresp$ <= 0;
    else
      if (arready$ && arvalid && !rvalid$)
        rresp$ <= 0; // "OKAY" response

//==========================================================
// port control
//==========================================================

  assign port_we = wready$ && wvalid && awready$ && awvalid;
  assign port_re = arready$ && arvalid && !rvalid$;

  always @(posedge clk)
    if (!xrst) begin
      for (int i = 0; i < PORT; i++)
        port$[i] <= 0;
    end
    else
      if (port_we) begin
        for (int i = 0; i < PORT; i++)
          if (awaddr$[ADDR_WIDTH-1:LSB] == i) begin
            for (int b = 0; b < DATA_WIDTH/8; b++)
              if (wstrb[b])
                port$[i][b*8 +: 8] <= wdata[b*8 +: 8];
          end
          else
            port$[i] <= port$[i];
      end
      else begin
        // PL->PS ports
        for (int i = PORT/2; i < PORT; i++)
          port$[i] <= out_port[i];
      end

  // PS->PL ports
  for (genvar i = 0; i < PORT/2; i++)
    assign in_port[i] = port$[i];

endmodule
