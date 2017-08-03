`include "renkon.svh"

module renkon_ctrl_linebuf
 #( parameter MAXFIL = 5
  , parameter MAXIMG = 32

  , localparam BUFSIZE = MAXIMG + 1
  , localparam BUFLINE = MAXFIL + 1
  , localparam SIZEWIDTH = $clog2(BUFSIZE)
  , localparam LINEWIDTH = $clog2(BUFLINE)
  )
  ( input                   clk
  , input                   xrst
  , input  [LWIDTH-1:0]     img_size
  , input  [LWIDTH-1:0]     fil_size
  , input                   buf_req
  , output                  buf_ack
  , output                  buf_valid
  , output [LINEWIDTH:0]    buf_wsel
  , output [LINEWIDTH:0]    buf_rsel
  , output                  buf_we
  , output [SIZEWIDTH-1:0]  buf_addr
  );

  wire  s_charge_end;
  wire  s_active_end;
  wire  in_col;

  enum reg [2-1:0] {
    S_WAIT, S_CHARGE, S_ACTIVE
  } state$;
  reg [LINEWIDTH-1:0]     mem_count$;
  reg [SIZEWIDTH-1:0]     col_count$;
  reg [SIZEWIDTH-1:0]     row_count$;
  reg [LINEWIDTH:0]       buf_wsel$;
  reg [LINEWIDTH:0]       buf_rsel$ [2-1:0];
  reg                     buf_valid$ [3-1:0];
  reg                     linebuf_we$;
  reg [SIZEWIDTH-1:0]     linebuf_addr$;

//==========================================================
// core control
//==========================================================

  assign buf_ack = state$ == S_WAIT;

  assign s_charge_end = mem_count$ == fil_size - 1
                     && col_count$ == img_size - 1;

  assign s_active_end = row_count$ == img_size
                     && col_count$ == img_size - 1;

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
      if (col_count$ == img_size - 1)
        col_count$ <= 0;
      else
        col_count$ <= col_count$ + 1;

  always @(posedge clk)
    if (!xrst)
      row_count$ <= 0;
    else if  (state$ == S_WAIT)
      row_count$ <= 0;
    else if (col_count$ == img_size - 1)
      if (row_count$ == img_size)
        row_count$ <= 0;
      else
        row_count$ <= row_count$ + 1;

  always @(posedge clk)
    if (!xrst)
      mem_count$ <= 0;
    else if  (state$ == S_WAIT)
      mem_count$ <= 0;
    else if (col_count$ == img_size - 1)
      if (mem_count$ == BUFLINE-1)
        mem_count$ <= 0;
      else
        mem_count$ <= mem_count$ + 1;

//==========================================================
// select control
//==========================================================

  assign buf_wsel = buf_wsel$;
  assign buf_rsel = buf_rsel$[1];

  always @(posedge clk)
    if (!xrst)
      buf_wsel$ <= 0;
    else if (state$ == S_WAIT)
      buf_wsel$ <= 0;
    else
      buf_wsel$ <= mem_count$ + 1;

  for (genvar i = 0; i < 2; i++)
    if (i == 0) begin
      always @(posedge clk)
        if (!xrst)
          buf_rsel$[0] <= 0;
        else if (state$ == S_WAIT)
          buf_rsel$[0] <= 0;
        else if (state$ == S_ACTIVE && col_count$ == 0)
          if (buf_rsel$[0] == fil_size + 1)
            buf_rsel$[0] <= 1;
          else
            buf_rsel$[0] <= buf_rsel$[0] + 1;
    end
    else begin
      always @(posedge clk)
        if (!xrst)
          buf_rsel$[i] <= 0;
        else
          buf_rsel$[i] <= buf_rsel$[i-1];
    end

//==========================================================
// memory
//==========================================================

  assign buf_we   = linebuf_we$;
  assign buf_addr = linebuf_addr$;

  assign in_col = fil_size - 1 <= col_count$
               && col_count$ < img_size;

  assign buf_valid = buf_valid$[2];

  always @(posedge clk)
    if (!xrst)
      linebuf_addr$ <= 0;
    else if (state$ == S_WAIT)
      linebuf_addr$ <= 0;
    else
      linebuf_addr$ <= col_count$;

  always @(posedge clk)
    if (!xrst)
      linebuf_we$ <= 0;
    else if (state$ == S_WAIT)
      linebuf_we$ <= 0;
    else
      linebuf_we$ <= row_count$ < img_size;

  for (genvar i = 0; i < 3; i++)
    if (i == 0) begin
      always @(posedge clk)
        if (!xrst)
          buf_valid$[0] <= 0;
        else
          buf_valid$[0] <= state$ == S_ACTIVE && in_col;
    end
    else begin
      always @(posedge clk)
        if (!xrst)
          buf_valid$[i] <= 0;
        else
          buf_valid$[i] <= buf_valid$[i-1];
    end

endmodule
