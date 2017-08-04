`include "renkon.svh"

module renkon_linebuf_pad
 #( parameter MAXFIL = 5
  , parameter MAXIMG = 32
  )
  ( input                         clk
  , input                         xrst
  , input                         buf_wcol
  , input                         buf_rrow [MAXFIL-1:0]
  , input  [$clog2(MAXFIL+1):0]   buf_wsel
  , input  [$clog2(MAXFIL+1):0]   buf_rsel
  , input                         buf_we
  , input  [$clog2(MAXIMG+1)-1:0] buf_addr
  , input  signed [DWIDTH-1:0]    buf_input
  , output signed [DWIDTH-1:0]    buf_output [MAXFIL**2-1:0]
  );

  localparam MAXPAD = (MAXFIL-1)/2;
  localparam BUFSIZE = MAXIMG + 2*MAXPAD + 1;
  localparam BUFLINE = MAXFIL + 1;
  localparam SIZEWIDTH = $clog2(BUFSIZE);
  localparam LINEWIDTH = $clog2(BUFLINE);

  wire [BUFLINE-1:0]        mem_linebuf_we;
  wire [SIZEWIDTH-1:0]      mem_linebuf_addr;
  wire signed [DWIDTH-1:0]  mem_linebuf_wdata;
  wire signed [DWIDTH-1:0]  mem_linebuf_rdata [BUFLINE-1:0];
  wire signed [DWIDTH-1:0]  mux [MAXFIL-1:0][BUFLINE+1-1:0];

  reg signed [DWIDTH-1:0] buf_input$;
  reg signed [DWIDTH-1:0] pixel$ [MAXFIL**2-1:0];

//==========================================================
// select control
//==========================================================

  for (genvar i = 0; i < MAXFIL**2; i++)
    assign buf_output[i] = pixel$[i];

  for (genvar i = 0; i < MAXFIL; i++)
    for (genvar k = -1; k < BUFLINE; k++)
      if (k == -1)
        assign mux[i][0]   = 0;
      else
        assign mux[i][k+1] = mem_linebuf_rdata[(i + k) % BUFLINE];

  for (genvar i = 0; i < MAXFIL; i++)
    for (genvar j = 0; j < MAXFIL; j++)
      if (j == MAXFIL-1) begin
        always @(posedge clk)
          if (!xrst)
            pixel$[MAXFIL * i + j] <= 0;
          else if (buf_rrow)
            pixel$[MAXFIL * i + j] <= mux[i][buf_rsel];
          else
            pixel$[MAXFIL * i + j] <= 0;
      end
      else begin
        always @(posedge clk)
          if (!xrst)
            pixel$[MAXFIL * i + j] <= 0;
          else
            pixel$[MAXFIL * i + j] <= pixel$[MAXFIL * i + (j+1)];
      end

//==========================================================
// memory
//==========================================================

  assign mem_linebuf_addr   = buf_addr;
  assign mem_linebuf_wdata  = buf_input$;

  always @(posedge clk)
    if (!xrst)
      buf_input$ <= 0;
    else if (buf_wcol)
      buf_input$ <= buf_input;
    else
      buf_input$ <= 0;

  for (genvar i = 0; i < BUFLINE; i++) begin
    assign mem_linebuf_we[i] = buf_we
                            && buf_wsel == i + 1;

    mem_sp #(DWIDTH, SIZEWIDTH) mem_buf(
      .mem_we     (mem_linebuf_we[i]),
      .mem_addr   (mem_linebuf_addr),
      .mem_wdata  (buf_input$),
      .mem_rdata  (mem_linebuf_rdata[i]),
      .*
    );
  end

endmodule
