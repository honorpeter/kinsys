`include "ninjin.svh"

module ninjin_s_axi_params
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
  wire [DATA_WIDTH-1:0] mux [PORT-1:0];

  reg                   r_awready;
  reg  [ADDR_WIDTH-1:0] r_awaddr;
  reg                   r_wready;
  reg                   r_bvalid;
  reg  [1:0]            r_bresp;
  reg                   r_arready;
  reg  [ADDR_WIDTH-1:0] r_araddr;
  reg                   r_rvalid;
  reg  [DATA_WIDTH-1:0] r_rdata;
  reg  [1:0]            r_rresp;
  reg  [DATA_WIDTH-1:0] r_port [PORT-1:0];

//==========================================================
// write address control
//==========================================================

  assign awready = r_awready;

  always @(posedge clk)
    if (!xrst)
      r_awready <= 0;
    else
      if (!r_awready && awvalid && wvalid)
        r_awready <= 1;
      else
        r_awready <= 0;

  always @(posedge clk)
    if (!xrst)
      r_awaddr <= 0;
    else
      if (!r_awready && awvalid && wvalid)
        r_awaddr <= awaddr;

//==========================================================
// write data control
//==========================================================

  assign wready = r_wready;

  always @(posedge clk)
    if (!xrst)
      r_wready <= 0;
    else
      if (!r_wready && awvalid && wvalid)
        r_wready <= 1;
      else
        r_wready <= 0;

//==========================================================
// write response control
//==========================================================

  assign bvalid = r_bvalid;
  assign bresp  = r_bresp;

  always @(posedge clk)
    if (!xrst)
      r_bvalid <= 0;
    else
      if (r_awready && awvalid && !r_bvalid && r_wready && wvalid)
        r_bvalid <= 1;
      else if (bready && r_bvalid)
        r_bvalid <= 0;

  always @(posedge clk)
    if (!xrst)
      r_bresp <= 0;
    else
      if (r_awready && awvalid && !r_bvalid && r_wready && wvalid)
        r_bresp <= 0; // "OKAY" response

//==========================================================
// read address control
//==========================================================

  assign arready = r_arready;

  always @(posedge clk)
    if (!xrst)
      r_arready <= 0;
    else
      if (!r_arready && arvalid)
        r_arready <= 1;
      else
        r_arready <= 0;

  always @(posedge clk)
    if (!xrst)
      r_araddr <= 0;
    else
      if (!r_arready && arvalid)
        r_araddr <= araddr;

//==========================================================
// read data control
//==========================================================

  assign rvalid = r_rvalid;
  assign rdata  = r_rdata;
  assign rresp  = r_rresp;

  always @(posedge clk)
    if (!xrst)
      r_rvalid <= 0;
    else
      if (r_arready && arvalid && !r_rvalid)
        r_rvalid <= 1;
      else if (rvalid && rready)
        r_rvalid <= 0;

  for (genvar i = 0; i < 2**(ADDR_WIDTH-LSB); i++)
    if (i < PORT)
      assign mux[i] = r_port[i];
    else
      assign mux[i] = 0;

  always @(posedge clk)
    if (!xrst)
      r_rdata <= 0;
    else if (port_re)
      r_rdata <= mux[r_araddr[ADDR_WIDTH-1:LSB]];

  always @(posedge clk)
    if (!xrst)
      r_rresp <= 0;
    else
      if (r_arready && arvalid && !r_rvalid)
        r_rresp <= 0; // "OKAY" response

//==========================================================
// port control
//==========================================================

  assign port_we = r_wready && wvalid && r_awready && awvalid;
  assign port_re = r_arready && arvalid && !r_rvalid;

  always @(posedge clk)
    if (!xrst) begin
      for (int i = 0; i < PORT; i++)
        r_port[i] <= 0;
    end
    else
      if (port_we) begin
        for (int i = 0; i < PORT; i++)
          if (r_awaddr[ADDR_WIDTH-1:LSB] == i) begin
            for (int b = 0; b < DATA_WIDTH/8; b++)
              if (wstrb[b])
                r_port[i][b*8 +: 8] <= wdata[b*8 +: 8];
          end
          else
            r_port[i] <= r_port[i];
      end
      else begin
        // PL->PS ports
        for (int i = PORT/2; i < PORT; i++)
          r_port[i] <= out_port[i];
      end

  // PS->PL ports
  for (genvar i = 0; i < PORT/2; i++)
    assign in_port[i] = r_port[i];

endmodule
