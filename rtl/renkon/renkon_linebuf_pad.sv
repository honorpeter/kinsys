`include "renkon.svh"

module renkon_linebuf_pad
 #( parameter MAXFIL = 5
  , parameter MAXIMG = 32
  )
  ( input                       clk
  , input                       xrst
  , input                       buf_req
  , input  [LWIDTH-1:0]         img_size
  , input  [LWIDTH-1:0]         fil_size
  , input  [LWIDTH-1:0]         pad_size
  , input  signed [DWIDTH-1:0]  buf_input
  , output                      buf_ack
  , output                      buf_valid
  , output                      buf_ready
  , output signed [DWIDTH-1:0]  buf_output [MAXFIL**2-1:0]
  );

  localparam MAXPAD = (MAXFIL-1)/2;
  localparam BUFSIZE = MAXIMG + 2*MAXPAD + 1;
  localparam BUFLINE = MAXFIL + 1;
  localparam SIZEWIDTH = $clog2(BUFSIZE);
  localparam LINEWIDTH = $clog2(BUFLINE);

  wire                      s_charge_end;
  wire                      s_active_end;
  wire [LWIDTH-1:0]         pad_both;
  wire [BUFLINE-1:0]        mem_linebuf_we;
  wire [SIZEWIDTH-1:0]      mem_linebuf_addr;
  wire signed [DWIDTH-1:0]  read_mem [BUFLINE-1:0];
  wire signed [DWIDTH-1:0]  mux [MAXFIL-1:0][BUFLINE+1-1:0];

  enum reg [2-1:0] {
    S_WAIT, S_CHARGE, S_ACTIVE
  } state$;
  reg [LINEWIDTH:0]       mem_count$;
  reg [SIZEWIDTH-1:0]     col_count$;
  reg [SIZEWIDTH-1:0]     row_count$;
  reg signed [DWIDTH-1:0] buf_input$;
  reg [LINEWIDTH:0]       select$ [2-1:0];
  reg                     buf_valid$ [3-1:0];
  reg signed [DWIDTH-1:0] pixel$ [MAXFIL**2-1:0];

//==========================================================
// core control
//==========================================================

  assign buf_ack = state$ == S_WAIT;

  assign s_charge_end = mem_count$ == fil_size - pad_size - 1
                     && col_count$ == img_size + pad_both - 1;

  assign s_active_end = row_count$ == img_size + pad_size
                     && col_count$ == img_size + pad_both - 1;

  // equals to 2 * pad_size
  assign pad_both = pad_size << 1;

  always @(posedge clk)
    if (!xrst)
      state$ <= S_WAIT;
    else
      case (state$)
        S_WAIT:
          if (buf_req)
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
      col_count$ <= 0;
    else if (state$ == S_WAIT)
      col_count$ <= 0;
    else
      if (col_count$ == img_size + pad_both - 1)
        col_count$ <= 0;
      else
        col_count$ <= col_count$ + 1;

  always @(posedge clk)
    if (!xrst)
      mem_count$ <= 0;
    else if  (state$ == S_WAIT)
      mem_count$ <= 0;
    else if (col_count$ == img_size + pad_both - 1)
      if (mem_count$ == BUFLINE-1)
        mem_count$ <= 0;
      else
        mem_count$ <= mem_count$ + 1;

  always @(posedge clk)
    if (!xrst)
      row_count$ <= 0;
    else if  (state$ == S_WAIT)
      row_count$ <= 0;
    else if (col_count$ == img_size + pad_both - 1)
      if (row_count$ == img_size + pad_both)
        row_count$ <= 0;
      else
        row_count$ <= row_count$ + 1;

//==========================================================
// select control
//==========================================================

  for (genvar i = 0; i < MAXFIL**2; i++)
    assign buf_output[i] = pixel$[i];

  for (genvar i = 0; i < 2; i++)
    if (i == 0) begin
      // TODO: need refactoring
      always @(posedge clk)
        if (!xrst)
          select$[0] <= 0;
        else if (state$ == S_WAIT)
          select$[0] <= 0;
        else if (state$ == S_ACTIVE && col_count$ == 0)
          if (select$[0] == 0)
            select$[0] <= pad_size == 0
                        ? 1
                        : BUFLINE - (pad_size - 1);
          else if (select$[0] == fil_size + 1)
            select$[0] <= 1;
          else
            select$[0] <= select$[0] + 1;
    end
    else begin
      always @(posedge clk)
        if (!xrst)
          select$[i] <= 0;
        else
          select$[i] <= select$[i-1];
    end

  for (genvar i = 0; i < MAXFIL; i++)
    for (genvar k = -1; k < BUFLINE; k++)
      if (k == -1)
        assign mux[i][0]   = 0;
      else
        assign mux[i][k+1] = read_mem[(i + k) % BUFLINE];

  for (genvar i = 0; i < MAXFIL; i++) begin : block
    reg in_row$[2-1:0];
    always @(posedge clk)
      if (!xrst) begin
        in_row$[0] <= 0;
        in_row$[1] <= 0;
      end
      else begin
        in_row$[0] <= fil_size - pad_size <= row_count$ + i
                   && row_count$ + i < img_size + fil_size;
        in_row$[1] <= in_row$[0];
      end

    for (genvar j = 0; j < MAXFIL; j++)
      if (j == MAXFIL-1) begin
        always @(posedge clk)
          if (!xrst)
            pixel$[MAXFIL * i + j] <= 0;
          else if (in_row$[1])
            pixel$[MAXFIL * i + j] <= mux[i][select$[1]];
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
  end : block

//==========================================================
// memory
//==========================================================

  wire in_col = fil_size - 1 <= col_count$ && col_count$ < img_size + pad_both;

  assign buf_ready = state$ != S_WAIT
                  && 0 <= row_count$ && row_count$ < img_size
                  && pad_size <= col_count$ && col_count$ < img_size + pad_size;

  assign buf_valid = buf_valid$[2];

  // assign mem_linebuf_addr = col_count$;
  reg [SIZEWIDTH-1:0] linebuf_addr$;
  assign mem_linebuf_addr = linebuf_addr$;
  always @(posedge clk)
    if (!xrst)
      linebuf_addr$ <= 0;
    else if (state$ == S_WAIT)
      linebuf_addr$ <= 0;
    else
      linebuf_addr$ <= col_count$;

  // assign mem_linebuf_we = state$ != S_WAIT
  //                       ? 1 << mem_count$
  //                       : 1'b0;
  reg [BUFLINE-1:0] linebuf_we$;
  assign mem_linebuf_we = linebuf_we$;
  always @(posedge clk)
    if (!xrst)
      linebuf_we$ <= 0;
    else if (state$ == S_WAIT)
      linebuf_we$ <= 0;
    else
      linebuf_we$ <= 1 << mem_count$;

  for (genvar i = 0; i < 3; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst)
          buf_valid$[0] <= 0;
        else
          buf_valid$[0] <= state$ == S_ACTIVE && in_col;
    else
      always @(posedge clk)
        if (!xrst)
          buf_valid$[i] <= 0;
        else
          buf_valid$[i] <= buf_valid$[i-1];

  always @(posedge clk)
    if (!xrst)
      buf_input$ <= 0;
    else if (buf_ready)
      buf_input$ <= buf_input;
    else
      buf_input$ <= 0;

  for (genvar i = 0; i < BUFLINE; i++)
    mem_sp #(DWIDTH, SIZEWIDTH) mem_buf(
      .mem_we     (mem_linebuf_we[i]),
      .mem_addr   (mem_linebuf_addr),
      .mem_wdata  (buf_input$),
      .mem_rdata  (read_mem[i]),
      .*
    );

endmodule
