`include "renkon.svh"

module renkon_linebuf
 #( parameter MAXLINE = 5
  , parameter MAXSIZE = 32 + 4
  )
  ( input                      clk
  , input                      xrst
  , input                      buf_en
  , input  [LWIDTH-1:0]        img_size
  , input  [LWIDTH-1:0]        fil_size
  , input  [LWIDTH-1:0]        pad_size
  , input  signed [DWIDTH-1:0] buf_input
  , output signed [DWIDTH-1:0] buf_output [MAXLINE**2-1:0]
  );

  localparam BUFSIZE = $clog2(MAXSIZE+1);
  localparam BUFLINE = $clog2(MAXLINE+1);

  wire                      s_charge_end;
  wire                      s_active_end;
  wire  [LWIDTH-1:0]        pad_both;
  wire [MAXLINE:0]          mem_linebuf_we;
  wire [BUFSIZE-1:0]        mem_linebuf_addr;
  wire signed [DWIDTH-1:0]  read_mem [MAXLINE:0];
  wire signed [DWIDTH-1:0]  mux [MAXLINE-1:0][MAXLINE+2-1:0];

  enum reg [2-1:0] {
    S_WAIT, S_CHARGE, S_ACTIVE
  } state$;
  reg [BUFLINE:0]        select$;
  reg [BUFLINE:0]        mem_count$;
  reg [BUFSIZE-1:0]      addr_count$;
  reg [BUFSIZE-1:0]      line_count$;
  reg signed [DWIDTH-1:0]  buf_input$;
  reg signed [DWIDTH-1:0]  pixel$ [MAXLINE**2-1:0];

//==========================================================
// core control
//==========================================================

  assign s_charge_end = mem_count$  == fil_size - 1
                     && addr_count$ == img_size - 1;

  assign s_active_end = line_count$ == img_size + pad_both
                     && addr_count$ == img_size + pad_both - 1;

  // assign pad_both = 2 * pad_size;
  assign pad_both = pad_size << 1;

  always @(posedge clk)
    if (!xrst)
      state$ <= S_WAIT;
    else
      case (state$)
        S_WAIT:
          if (buf_en)
            state$ <= S_CHARGE;
        S_CHARGE:
          if (s_charge_end)
            state$ <= S_ACTIVE;
        S_ACTIVE:
          if (s_active_end)
            state$ <= S_WAIT;
        default:
          state$ <= S_WAIT;
      endcase

//==========================================================
// address control
//==========================================================

  always @(posedge clk)
    if (!xrst)
      addr_count$ <= 0;
    else if (state$ == S_WAIT)
      addr_count$ <= 0;
    else if (state$ == S_CHARGE || state$ == S_ACTIVE)
      if (addr_count$ == img_size + pad_both - 1)
        addr_count$ <= 0;
      else
        addr_count$ <= addr_count$ + 1;

  always @(posedge clk)
    if (!xrst)
      mem_count$ <= 0;
    else if  (state$ == S_WAIT)
      mem_count$ <= 0;
    else if (state$ == S_CHARGE || state$ == S_ACTIVE)
      if (addr_count$ == img_size + pad_both - 1)
        if (mem_count$ == MAXLINE)
          mem_count$ <= 0;
        else
          mem_count$ <= mem_count$ + 1;

  always @(posedge clk)
    if (!xrst)
      line_count$ <= 0;
    else if  (state$ == S_WAIT)
      line_count$ <= 0;
    else if (state$ == S_CHARGE || state$ == S_ACTIVE)
      if (addr_count$ == img_size + pad_both - 1)
        if (line_count$ == img_size + pad_both)
          line_count$ <= 0;
        else
          line_count$ <= line_count$ + 1;

//==========================================================
// select control
//==========================================================

  for (genvar i = 0; i < MAXLINE**2; i++)
    assign buf_output[i] = pixel$[i];

  always @(posedge clk)
    if (!xrst)
      select$ <= 0;
    else if (state$ == S_WAIT)
      select$ <= 0;
    else if (state$ == S_ACTIVE)
      if (addr_count$ == 0)
        if (mem_count$ == fil_size)
          select$ <= 1;
        else
          select$ <= select$+1;

  for (genvar i = 0; i < MAXLINE; i++)
    for (genvar k = -1; k < MAXLINE+1; k++)
      if (k == -1)
        assign mux[i][0]   = 0;
      else
        assign mux[i][k+1] = read_mem[(i + k) % (MAXLINE + 1)];

  for (genvar i = 0; i < MAXLINE; i++)
    for (genvar j = 0; j < MAXLINE; j++)
      if (j == MAXLINE-1) begin
        always @(posedge clk)
          if (!xrst)
            pixel$[MAXLINE * i + j] <= 0;
          else
            pixel$[MAXLINE * i + j] <= mux[i][select$];
      end
      else begin
        always @(posedge clk)
          if (!xrst)
            pixel$[MAXLINE * i + j] <= 0;
          else
            pixel$[MAXLINE * i + j] <= pixel$[MAXLINE * i + (j+1)];
      end

//==========================================================
// memory
//==========================================================

  assign mem_linebuf_addr = addr_count$;

  assign mem_linebuf_we = (state$ == S_CHARGE || state$ == S_ACTIVE)
                        ? (1 << mem_count$)
                        : 1'b0;

  // always @(posedge clk)
  //   if (!xrst)
  //     linebuf_we$ <= 0;
  //   else
  //
  // always @(posedge clk)
  //   if (!xrst)
  //     linebuf_addr$ <= 0;
  //   else

  // always @(posedge clk)
  //   if (!xrst)
  //     linebuf_wdata$ <= 0;
  //   else if (addr_count$ < pad_size || img_size < addr_count$)
  //     linebuf_wdata$ <= 0;
  //   else
  //     linebuf_wdata$ <= buf_input;

  always @(posedge clk)
    if (!xrst)
      buf_input$ <= 0;
    else
      buf_input$ <= buf_input;

  for (genvar i = 0; i < MAXLINE+1; i++)
    mem_sp #(DWIDTH, BUFSIZE) mem_buf(
      .mem_we     (mem_linebuf_we[i]),
      .mem_addr   (mem_linebuf_addr),
      .mem_wdata  (buf_input$),
      .mem_rdata  (read_mem[i]),
      .*
    );

endmodule
