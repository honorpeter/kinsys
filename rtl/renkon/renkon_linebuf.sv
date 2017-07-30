`include "renkon.svh"

module renkon_linebuf
 #( parameter MAXFIL = 5
  , parameter MAXIMG = 32
  , parameter MAXPAD = (MAXFIL-1)/2
  )
  ( input                      clk
  , input                      xrst
  , input                      buf_en
  , input  [LWIDTH-1:0]        img_size
  , input  [LWIDTH-1:0]        fil_size
  , input  [LWIDTH-1:0]        pad_size
  , input  signed [DWIDTH-1:0] buf_input
  , output signed [DWIDTH-1:0] buf_output [MAXFIL**2-1:0]
  );

  localparam BUFSIZE = MAXIMG + 2*MAXPAD + 1;
  localparam BUFLINE = MAXFIL + MAXPAD + 1;
  localparam SIZEWIDTH = $clog2(BUFSIZE);
  localparam LINEWIDTH = $clog2(BUFLINE);

  wire                      s_charge_end;
  wire                      s_active_end;
  wire [LWIDTH-1:0]         pad_both;
  wire [BUFLINE-1:0]        mem_linebuf_we;
  wire [SIZEWIDTH-1:0]      mem_linebuf_addr;
  wire signed [DWIDTH-1:0]  read_mem [LINEWIDTH-1:0];
  wire signed [DWIDTH-1:0]  mux [MAXFIL-1:0][BUFLINE+1-1:0];

  enum reg [2-1:0] {
    S_WAIT, S_CHARGE, S_ACTIVE
  } state$;
  reg [LINEWIDTH:0]       select$;
  reg [LINEWIDTH:0]       mem_count$;
  reg [SIZEWIDTH-1:0]     addr_count$;
  reg [SIZEWIDTH-1:0]     line_count$;
  reg signed [DWIDTH-1:0] buf_input$;
  reg signed [DWIDTH-1:0] pixel$ [MAXFIL**2-1:0];

//==========================================================
// core control
//==========================================================

  assign s_charge_end = mem_count$  == fil_size - 1
                     && addr_count$ == img_size - 1;

  assign s_active_end = line_count$ == img_size + pad_both
                     && addr_count$ == img_size + pad_both - 1;

  // equals to 2 * pad_size
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
        if (mem_count$ == BUFLINE-1)
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

  for (genvar i = 0; i < MAXFIL**2; i++)
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

  for (genvar i = 0; i < MAXFIL; i++)
    for (genvar k = -1; k < BUFLINE-1; k++)
      if (k == -1)
        assign mux[i][0]   = 0;
      else
        assign mux[i][k+1] = read_mem[(i + k) % (BUFLINE)];

  for (genvar i = 0; i < MAXFIL; i++)
    for (genvar j = 0; j < MAXFIL; j++)
      if (j == MAXFIL-1) begin
        wire in_row = pad_size <= line_count$ + i
                   && line_count$ + i < img_size + pad_size;
        wire in_col = pad_size <= addr_count$ + j
                   && addr_count$ + j < img_size + pad_size;
        wire in_img = in_row && in_col;

        always @(posedge clk)
          if (!xrst)
            pixel$[MAXFIL * i + j] <= 0;
          else if (in_img)
            pixel$[MAXFIL * i + j] <= mux[i][select$];
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

  assign mem_linebuf_addr = addr_count$;

  assign mem_linebuf_we = (state$ == S_CHARGE || state$ == S_ACTIVE)
                        ? (1 << mem_count$)
                        : 1'b0;

  always @(posedge clk)
    if (!xrst)
      buf_input$ <= 0;
    else
      buf_input$ <= buf_input;

  for (genvar i = 0; i < BUFLINE; i++)
    mem_sp #(DWIDTH, SIZEWIDTH) mem_buf(
      .mem_we     (mem_linebuf_we[i]),
      .mem_addr   (mem_linebuf_addr),
      .mem_wdata  (buf_input$),
      .mem_rdata  (read_mem[i]),
      .*
    );

endmodule
