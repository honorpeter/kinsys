`include "renkon.svh"

module renkon_ctrl_linebuf_pad
 #( parameter MAXFIL    = 3
  , parameter MAXIMG    = 32
  , parameter COVER_ALL = 1'b1
  // , parameter COVER_ALL = 1'b0
  , parameter MAXDELAY  = 8

  , localparam MAXPAD = (MAXFIL-1)/2
  , localparam BUFSIZE = MAXIMG + 1
  , localparam BUFLINE = MAXFIL + 1
  , localparam SIZEWIDTH = $clog2(BUFSIZE)
  , localparam LINEWIDTH = $clog2(BUFLINE)
  )
  ( input                   clk
  , input                   xrst
  , input  [LWIDTH-1:0]     size
  , input  [LWIDTH-1:0]     kern
  , input  [LWIDTH-1:0]     stride
  , input  [LWIDTH-1:0]     pad
  , input                   buf_req
  , input  integer          buf_delay

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
  wire [LINEWIDTH:0]        mem_count;
  wire [SIZEWIDTH-1:0]      col_count;
  wire [SIZEWIDTH-1:0]      row_count;
  wire [SIZEWIDTH-1:0]      str_x_count;
  wire [SIZEWIDTH-1:0]      str_y_count;

  enum reg [2-1:0] {
    S_WAIT, S_CHARGE, S_ACTIVE
  } state$;
  reg [LINEWIDTH:0]   mem_count$ [MAXDELAY-1:0];
  reg [SIZEWIDTH-1:0] col_count$ [MAXDELAY-1:0];
  reg [SIZEWIDTH-1:0] row_count$ [MAXDELAY-1:0];
  reg [SIZEWIDTH-1:0] str_x_count$ [MAXDELAY-1:0];
  reg [SIZEWIDTH-1:0] str_y_count$ [MAXDELAY-1:0];
  reg                 buf_ack$    [3-1:0];
  reg                 buf_start$  [3-1:0];
  reg                 buf_valid$  [3-1:0];
  reg                 buf_stop$   [3-1:0];
  reg                 buf_wcol$;
  reg                 buf_rrow$   [2-1:0][MAXFIL-1:0];
  reg [LINEWIDTH:0]   buf_wsel$;
  reg [LINEWIDTH:0]   buf_rsel$   [2-1:0];
  reg                 buf_we$;
  reg [SIZEWIDTH-1:0] buf_addr$;

//==========================================================
// core control
//==========================================================

  assign buf_ack = state$ == S_WAIT && buf_ack$[2];

  assign s_charge_end = mem_count == kern - pad - 1
                     && col_count == make_size(size, kern, stride, pad) - 1;

  assign s_active_end = row_count == make_size(size, kern, stride, pad) - pad
                     && col_count == make_size(size, kern, stride, pad) - 1;


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

  assign col_count = col_count$[buf_delay-1];
  assign mem_count = mem_count$[buf_delay-1];
  assign row_count = row_count$[buf_delay-1];
  assign str_x_count = str_x_count$[buf_delay-1];
  assign str_y_count = str_y_count$[buf_delay-1];

  always @(posedge clk)
    if (!xrst)
      col_count$[0] <= 0;
    else if (state$ == S_WAIT)
      col_count$[0] <= 0;
    else
      if (col_count$[0] == make_size(size, kern, stride, pad) - 1)
        col_count$[0] <= 0;
      else
        col_count$[0] <= col_count$[0] + 1;

  always @(posedge clk)
    if (!xrst)
      mem_count$[0] <= 0;
    else if  (state$ == S_WAIT)
      mem_count$[0] <= 0;
    else if (col_count$[0] == make_size(size, kern, stride, pad) - 1)
      if (mem_count$[0] == BUFLINE-1)
        mem_count$[0] <= 0;
      else
        mem_count$[0] <= mem_count$[0] + 1;

  always @(posedge clk)
    if (!xrst)
      row_count$[0] <= 0;
    else if  (state$ == S_WAIT)
      row_count$[0] <= 0;
    else if (col_count$[0] == make_size(size, kern, stride, pad) - 1)
      if (row_count$[0] == make_size(size, kern, stride, pad))
        row_count$[0] <= 0;
      else
        row_count$[0] <= row_count$[0] + 1;

  always @(posedge clk)
    if (!xrst)
      str_x_count$[0] <= 0;
    else if  (state$ == S_WAIT)
      str_x_count$[0] <= 0;
    else
      if (str_x_count$[0] == stride-1)
        str_x_count$[0] <= 0;
      else
        str_x_count$[0] <= str_x_count$[0] + 1;

  always @(posedge clk)
    if (!xrst)
      str_y_count$[0] <= 0;
    else if  (state$ == S_WAIT)
      str_y_count$[0] <= 0;
    else if (col_count$[0] == make_size(size, kern, stride, pad) - 1)
      if (str_y_count$[0] == stride-1)
        str_y_count$[0] <= 0;
      else
        str_y_count$[0] <= str_y_count$[0] + 1;

  for (genvar i = 1; i < MAXDELAY; i++)
    always @(posedge clk)
      if (!xrst) begin
        col_count$[i] <= 0;
        mem_count$[i] <= 0;
        row_count$[i] <= 0;
        str_x_count$[i] <= 0;
        str_y_count$[i] <= 0;
      end
      else begin
        col_count$[i] <= col_count$[i-1];
        mem_count$[i] <= mem_count$[i-1];
        row_count$[i] <= row_count$[i-1];
        str_x_count$[i] <= str_x_count$[i-1];
        str_y_count$[i] <= str_y_count$[i-1];
      end

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
    else if (state$ == S_WAIT)
      buf_wcol$ <= 0;
    else
      buf_wcol$ <= 0   <= row_count && row_count < size
                && pad <= col_count && col_count < size + pad;

  for (genvar i = 0; i < 2; i++)
    for (genvar j = 0; j < MAXFIL; j++)
      if (i == 0) begin
        always @(posedge clk)
          if (!xrst)
            buf_rrow$[0][j] <= 0;
          else
            buf_rrow$[0][j] <= kern <= row_count+j && row_count+j < size + kern;
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
      buf_wsel$ <= mem_count + 1;

  for (genvar i = 0; i < 2; i++)
    if (i == 0) begin
      // TODO: need refactoring
      always @(posedge clk)
        if (!xrst)
          buf_rsel$[0] <= 0;
        else if (state$ == S_WAIT)
          buf_rsel$[0] <= 0;
        else if (state$ == S_ACTIVE && col_count == 0)
          if (buf_rsel$[0] == 0)
            buf_rsel$[0] <= pad == 0
                          ? 1
                          : BUFLINE - (pad - 1);
          else if (buf_rsel$[0] == kern + 1)
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
                  && 0   <= row_count$[0] && row_count$[0] < size
                  && pad <= col_count$[0] && col_count$[0] < size + pad;

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
      buf_we$ <= row_count < size + pad;

  always @(posedge clk)
    if (!xrst)
      buf_addr$ <= 0;
    else if (state$ == S_WAIT)
      buf_addr$ <= 0;
    else
      buf_addr$ <= col_count;

  // TODO: to doit precisely -> kern % stride - 1
  wire [LWIDTH-1:0] str_x_start;
  wire [LWIDTH-1:0] str_y_start;
  assign str_x_start = stride == 1 ? 0
                     : (kern-stride) > 0 ? kern-stride-1
                     : stride-1;
  assign str_y_start = 0;
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
                        && row_count == kern - pad
                        && col_count == kern - 2;

          buf_valid$[0] <= state$ == S_ACTIVE
                        && kern - 1 <= col_count
                        && col_count < make_size(size, kern, stride, pad)
                        && str_x_count == str_x_start
                        && str_y_count == str_y_start;

          buf_stop$[0]  <= state$ == S_ACTIVE
                        && row_count == size + pad
                        && col_count == make_size(size, kern, stride, pad) - 1;
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

//==========================================================
//  Function
//==========================================================
// {{{

  wire [LWIDTH-1:0] own_size = make_size(size, kern, stride, pad);

  function [LWIDTH-1:0] make_size
    ( input [LWIDTH-1:0] size
    , input [LWIDTH-1:0] kern
    , input [LWIDTH-1:0] stride
    , input [LWIDTH-1:0] pad
    );

    // equals to 2 * pad
    if (COVER_ALL)
      make_size = size + (pad << 1) + stride - 1;
    else
      make_size = size + (pad << 1);
  endfunction

// }}}
endmodule
