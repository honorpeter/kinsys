`include "renkon.svh"

module renkon_ctrl_linebuf_pad
 #( parameter MAXFIL = 5
  , parameter MAXIMG = 32

  , localparam MAXPAD = (MAXFIL-1)/2
  , localparam BUFSIZE = MAXIMG + 1
  , localparam BUFLINE = MAXFIL + 1
  , localparam SIZEWIDTH = $clog2(BUFSIZE)
  , localparam LINEWIDTH = $clog2(BUFLINE)
  )
  ( input                   clk
  , input                   xrst
  , input  [LWIDTH-1:0]     img_size
  , input  [LWIDTH-1:0]     fil_size
  , input  [LWIDTH-1:0]     pad_size
  , input                   buf_req
  , output                  buf_ack
  , output                  buf_start
  , output                  buf_valid
  , output                  buf_ready
  , output                  buf_stop
  , output                  buf_wcol
  , output                  buf_rrow [MAXFIL-1:0]
  , output [LINEWIDTH:0]    buf_wsel
  , output [LINEWIDTH:0]    buf_rsel
  , output                  buf_we
  , output [SIZEWIDTH-1:0]  buf_addr
  );

  wire                      s_charge_end;
  wire                      s_active_end;
  wire [LWIDTH-1:0]         pad_both;

  enum reg [2-1:0] {
    S_WAIT, S_CHARGE, S_ACTIVE
  } state$;
  reg [LINEWIDTH:0]   mem_count$;
  reg [SIZEWIDTH-1:0] col_count$;
  reg [SIZEWIDTH-1:0] row_count$;
  reg                 buf_ack$ [3-1:0];
  reg                 buf_start$ [3-1:0];
  reg                 buf_valid$ [3-1:0];
  reg                 buf_stop$ [3-1:0];
  reg                 buf_wcol$;
  reg                 buf_rrow$ [2-1:0][MAXFIL-1:0];
  reg [LINEWIDTH:0]   buf_wsel$;
  reg [LINEWIDTH:0]   buf_rsel$ [2-1:0];
  reg                 buf_we$;
  reg [SIZEWIDTH-1:0] buf_addr$;

//==========================================================
// core control
//==========================================================

  assign buf_ack = state$ == S_WAIT && buf_ack$[2];

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

  for (genvar i = 0; i < 3; i++)
    if (i == 0) begin
      always @(posedge clk)
        if (!xrst)
          buf_ack$[0] <= 0;
        else
          buf_ack$[0] <= state$ == S_WAIT;
    end
    else begin
      always @(posedge clk)
        if (!xrst)
          buf_ack$[i] <= 0;
        else
          buf_ack$[i] <= buf_ack$[i-1];
    end

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

  assign buf_wcol = buf_wcol$;
  assign buf_rrow = buf_rrow$[1];

  assign buf_wsel = buf_wsel$;
  assign buf_rsel = buf_rsel$[1];

  always @(posedge clk)
    if (!xrst)
      buf_wcol$ <= 0;
    else
      buf_wcol$ <= buf_ready;

  for (genvar i = 0; i < 2; i++)
    for (genvar j = 0; j < MAXFIL; j++)
      if (i == 0) begin
        always @(posedge clk)
          if (!xrst)
            buf_rrow$[0][j] <= 0;
          else
            buf_rrow$[0][j] <= fil_size - pad_size <= row_count$ + j
                            && row_count$ + j < img_size + fil_size;
        end
      else begin
        always @(posedge clk)
          if (!xrst)
            buf_rrow$[i][j] <= 0;
          else
            buf_rrow$[i][j] <= buf_rrow$[i-1][j];
      end

  always @(posedge clk)
    if (!xrst)
      buf_wsel$ <= 0;
    else if (state$ == S_WAIT)
      buf_wsel$ <= 0;
    else
      buf_wsel$ <= mem_count$ + 1;

  for (genvar i = 0; i < 2; i++)
    if (i == 0) begin
      // TODO: need refactoring
      always @(posedge clk)
        if (!xrst)
          buf_rsel$[0] <= 0;
        else if (state$ == S_WAIT)
          buf_rsel$[0] <= 0;
        else if (state$ == S_ACTIVE && col_count$ == 0)
          if (buf_rsel$[0] == 0)
            buf_rsel$[0] <= pad_size == 0
                          ? 1
                          : BUFLINE - (pad_size - 1);
          else if (buf_rsel$[0] == fil_size + 1)
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

  assign buf_ready = state$ != S_WAIT
                  && 0        <= row_count$ && row_count$ < img_size
                  && pad_size <= col_count$ && col_count$ < img_size + pad_size;

  assign buf_we   = buf_we$;
  assign buf_addr = buf_addr$;

  assign buf_start = buf_start$[2];
  assign buf_valid = buf_valid$[2];
  assign buf_stop  = buf_stop$[2];

  always @(posedge clk)
    if (!xrst)
      buf_we$ <= 0;
    else if (state$ == S_WAIT)
      buf_we$ <= 0;
    else
      buf_we$ <= row_count$ < img_size + pad_size;

  always @(posedge clk)
    if (!xrst)
      buf_addr$ <= 0;
    else if (state$ == S_WAIT)
      buf_addr$ <= 0;
    else
      buf_addr$ <= col_count$;

  for (genvar i = 0; i < 3; i++)
    if (i == 0) begin
      always @(posedge clk)
        if (!xrst) begin
          buf_start$[0] <= 0;
          buf_valid$[0] <= 0;
          buf_stop$[0]  <= 0;
        end
        else begin
          buf_start$[0] <= state$ == S_ACTIVE
                        && row_count$ == fil_size - pad_size
                        && col_count$ == fil_size - 2;

          buf_valid$[0] <= state$ == S_ACTIVE
                        && fil_size - 1 <= col_count$
                        && col_count$ < img_size + pad_both;

          buf_stop$[0]  <= state$ == S_ACTIVE
                        && row_count$ == img_size + pad_size
                        && col_count$ == img_size + pad_both - 1;
        end
    end
    else begin
      always @(posedge clk)
        if (!xrst) begin
          buf_start$[i] <= 0;
          buf_valid$[i] <= 0;
          buf_stop$[i]  <= 0;
        end
        else begin
          buf_start$[i] <= buf_start$[i-1];
          buf_valid$[i] <= buf_valid$[i-1];
          buf_stop$[i]  <= buf_stop$[i-1];
        end
    end

endmodule
