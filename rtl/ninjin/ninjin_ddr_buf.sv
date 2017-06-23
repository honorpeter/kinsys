`include "ninjin.svh"

module ninjin_ddr_buf
  ( input                     clk
  , input                     xrst
  // meta inputs
  , input                     prefetch
  , input [IMGSIZE-1:0]       base_addr
  , input [LWIDTH-1:0]        total_len
  // memory ports
  , input                     mem_we
  , input [IMGSIZE-1:0]       mem_addr
  , input signed [DWIDTH-1:0] mem_wdata
  // m_axi ports (fed back)
  , input                     ddr_we
  , input [IMGSIZE-1:0]       ddr_waddr
  , input [BWIDTH-1:0]        ddr_wdata
  , input [IMGSIZE-1:0]       ddr_raddr
  // m_axi signals
  , output                      ddr_req
  , output                      ddr_mode
  , output [IMGSIZE-1:0]        ddr_base
  , output [LWIDTH-1:0]         ddr_len
  , output [BWIDTH-1:0]         ddr_rdata
  // memory data
  , output signed [DWIDTH-1:0]  mem_rdata
  );

  localparam  RATE = BWIDTH / DWIDTH;
  localparam  RATELOG = $clog2(RATE);

  localparam  M_IDLE  = 'd0,
              M_INCR  = 'd1,
              M_TRANS = 'd2;

  // localparam  ALPHA = 'd0,
  //             BRAVO = 'd1,
  //             PRE   = 'd2
  //             POST  - 'd3;

  typedef enum reg [1:0] {
    ALPHA=0, BRAVO=1, PRE=2, POST=3
  } reg_which;

  wire                        s_pref_end;
  wire                        s_read_end;
  wire                        s_write_end;
  wire                        s_pref_edge;
  wire                        s_read_edge;
  wire                        s_write_edge;
  wire [1:0]                  mode;
  wire                        txn_start;
  wire                        txn_stop;
  wire                        buf_we    [1:0];
  wire [BUFSIZE-1:0]          buf_addr  [1:0];
  wire signed [BWIDTH-1:0]    buf_wdata [1:0];
  wire [BWIDTH-1:0]           buf_rdata [1:0];
  wire                        pre_we;
  wire [BUFSIZE-1:0]          pre_addr;
  wire signed [BWIDTH-1:0]    pre_wdata;
  wire [BWIDTH-1:0]           pre_rdata;
  wire                        post_we;
  wire [BUFSIZE-1:0]          post_addr;
  wire signed [BWIDTH-1:0]    post_wdata;
  wire [BWIDTH-1:0]           post_rdata;
  wire                        switch_buf;
  wire signed [IMGSIZE-1:0]   addr_diff;
  wire signed [LWIDTH-1:0]    len_diff;
  wire [BUFSIZE+RATELOG-1:0]  addr_offset;
  wire [RATELOG-1:0]          word_offset;
  wire signed [DWIDTH-1:0]    alpha [RATE-1:0];
  wire signed [DWIDTH-1:0]    bravo [RATE-1:0];
  wire signed [DWIDTH-1:0]    pre   [RATE-1:0];
  wire signed [DWIDTH-1:0]    post  [RATE-1:0];
  wire                        mem_we_edge;
  wire [LWIDTH-1:0]           rest_len;

  enum reg [1:0] {
    S_IDLE=0, S_PREF=1, S_READ=2, S_WRITE=3
  } state$ [1:0];
  reg_which               which$;
  reg [1:0]               mode$;
  reg_which               mem_which$;
  reg                     mem_we$;
  reg [IMGSIZE-1:0]       mem_addr$;
  reg signed [DWIDTH-1:0] mem_wdata$;
  reg [LWIDTH-1:0]        mem_diff$;
  reg_which               ddr_which$;
  reg                     ddr_req$;
  reg                     ddr_mode$;
  reg [IMGSIZE-1:0]       ddr_base$;
  reg [LWIDTH-1:0]        ddr_len$;
  reg                     buf_we$;
  reg [IMGSIZE-1:0]       buf_addr$;
  reg signed [BWIDTH-1:0] buf_wdata$;
  reg [IMGSIZE-1:0]       buf_base$ [1:0];
  reg [RATE-1:0]          we_accum$;
  reg [LWIDTH-1:0]        total_len$;
  reg [LWIDTH-1:0]        count_len$;
  reg [LWIDTH-1:0]        count_inner$;
  reg [LWIDTH-1:0]        count_post$;
  reg [LWIDTH-1:0]        pref_len$;
  reg [IMGSIZE-1:0]       base_addr$;
  reg                     switch_buf$;
  reg_which               first_buf$;
  reg [RATELOG-1:0]       word_offset$;

  /*
   * When ddr_req asserts, ddr_mode and ddr_base are fetched.
   * Then m_axi starts streaming with ddr_stream channel.
   * The ddr_stream represents both reading and writing data stream
   * in context of ddr_mode.
   */

  wire java, not_java;
  assign java     = RATE*BURST_LEN < count_len$ && count_len$ <= 2*RATE*BURST_LEN
                 && count_inner$ == RATE * BURST_LEN - 1;
  assign not_java = count_post$ == count_len$;

//==========================================================
// core control
//==========================================================
// {{{

  assign s_pref_end  = state$[0] == S_PREF
                    && pre_we && pre_addr == pref_len$ - 1;
  assign s_read_end  = state$[0] == S_READ
                    && count_len$ != 0 && count_inner$ == count_len$;
  assign s_write_end = state$[0] == S_WRITE
                    && count_len$ != 0 && count_inner$ == count_len$;

  assign s_pref_edge  = state$[0] == S_PREF  && state$[1] != S_PREF;
  assign s_read_edge  = state$[0] == S_READ  && state$[1] != S_READ;
  assign s_write_edge = state$[0] == S_WRITE && state$[1] != S_WRITE;

  assign mode = addr_diff == 0 ? M_IDLE
              : addr_diff == 1 ? M_INCR
              : M_TRANS;

  assign addr_diff = mem_addr - mem_addr$;
  assign len_diff  = total_len - total_len$;

  for (genvar i = 0; i < 2; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst)
          state$[0] <= S_IDLE;
        else
          case (state$[0])
            S_IDLE:
              if (prefetch)
                state$[0] <= S_PREF;
              else if (mem_we$ && addr_diff == 1)
                state$[0] <= S_WRITE;
              else if (!mem_we$ && addr_diff == 1)
                state$[0] <= S_READ;
            S_PREF:
              if (s_pref_end)
                state$[0] <= S_IDLE;
            S_READ:
              if (s_read_end)
                state$[0] <= S_IDLE;
            S_WRITE:
              if (s_write_end)
                state$[0] <= S_IDLE;
            default:
              state$[0] <= S_IDLE;
          endcase
      else
        always @(posedge clk)
          if (!xrst)
            state$[i] <= S_IDLE;
          else
            state$[i] <= state$[i-1];

  always @(posedge clk)
    if (!xrst)
      mode$ <= M_IDLE;
    else
      mode$ <= mode;

  always @(posedge clk)
    if (!xrst)
      which$ <= PRE;
    else
      case (which$)
        ALPHA:
          if (s_read_end || s_write_end)
            which$ <= PRE;
          else if (java)
            which$ <= POST;
          else if (switch_buf)
            which$ <= BRAVO;
          // else if (s_pref_edge)
          //   which$ <= PRE;

        BRAVO:
          if (s_read_end || s_write_end)
            which$ <= PRE;
          else if (java)
            which$ <= POST;
          else if (switch_buf)
            which$ <= ALPHA;
          // else if (s_pref_edge)
          //   which$ <= PRE;

        PRE:
          // if (s_write_edge)
          if (txn_start && mem_we)
            which$ <= first_buf$;
          else if (switch_buf)
            which$ <= first_buf$;

        POST:
          if (not_java)
            which$ <= PRE;

        default:
          which$ <= PRE;
      endcase

  always @(posedge clk)
    if (!xrst)
      total_len$ <= 0;
    else
      total_len$ <= total_len;

  always @(posedge clk)
    if (!xrst)
      base_addr$ <= 0;
    else
      base_addr$ <= base_addr;

  always @(posedge clk)
    if (!xrst)
      mem_diff$ <= 0;
    else if (state$[0] == S_IDLE)
      mem_diff$ <= 0;
    else if (switch_buf)
      mem_diff$ <= mem_diff$ + BURST_LEN * (RATE-1);

  always @(posedge clk)
    if (!xrst)
      count_len$ <= 0;
    else if (state$[0] == S_IDLE)
      count_len$ <= 0;
    else if (s_pref_edge || s_read_edge || s_write_edge)
      count_len$ <= total_len$;
    else if (switch_buf)
      count_len$ <= count_len$ - RATE*BURST_LEN;

  always @(posedge clk)
    if (!xrst)
      count_inner$ <= 0;
    else
      case (state$[0])
        S_IDLE:
          if (txn_start && !mem_we$)
            count_inner$ <= 2;
          else
            count_inner$ <= 0;
        S_WRITE:
          if (count_inner$ == RATE * BURST_LEN-1)
            count_inner$ <= 0;
          else
            count_inner$ <= count_inner$ + 1;
        S_PREF:
          if (ddr_we)
            count_inner$ <= count_inner$ + 1;
        S_READ:
          if (count_inner$ == RATE * (count_len$ > BURST_LEN ? BURST_LEN : count_len$)-1)
            count_inner$ <= 0;
          else
            count_inner$ <= count_inner$ + txn_start + (addr_diff == 1 ? 1 : 0);
      endcase

// }}}
//==========================================================
// memory control
//==========================================================
// {{{

  assign mem_we_edge  = mem_we && !mem_we$;
  assign addr_offset  = mem_addr - base_addr$;
  assign word_offset  = addr_offset[RATELOG-1:0];

  assign txn_start  = count_len$ == 0
                   && ( mode == M_INCR  && mode$ == M_IDLE
                     || mode == M_INCR  && mode$ == M_TRANS
                   );

  assign txn_stop   = mode == M_IDLE  && mode$ == M_INCR
                   || mode == M_TRANS && mode$ == M_INCR;

  for (genvar i = 0; i < RATE; i++) begin
    assign alpha[i] = buf_rdata[ALPHA][(i+1)*DWIDTH-1:i*DWIDTH];
    assign bravo[i] = buf_rdata[BRAVO][(i+1)*DWIDTH-1:i*DWIDTH];
    assign pre[i]   = pre_rdata[(i+1)*DWIDTH-1:i*DWIDTH];
    assign post[i]  = post_rdata[(i+1)*DWIDTH-1:i*DWIDTH];
  end

  assign mem_rdata  = mem_we$             ? mem_wdata$
                    : mem_which$ == ALPHA ? alpha[word_offset$]
                    : mem_which$ == BRAVO ? bravo[word_offset$]
                    : mem_which$ == PRE   ? pre[word_offset$]
                    : mem_which$ == POST  ? post[word_offset$]
                    : 0;

  always @(posedge clk)
    if (!xrst)
      word_offset$ <= 0;
    else
      word_offset$ <= word_offset;

  always @(posedge clk)
    if (!xrst)
      mem_addr$ <= 0;
    else
      mem_addr$ <= mem_addr;

  always @(posedge clk)
    if (!xrst)
      mem_we$ <= 0;
    else
      mem_we$ <= mem_we;

  always @(posedge clk)
    if (!xrst)
      mem_wdata$ <= 0;
    else
      mem_wdata$ <= mem_wdata;

  always @(posedge clk)
    if (!xrst)
      mem_which$ <= PRE;
    else
      mem_which$ <= which$;

// }}}
//==========================================================
// ddr control
//==========================================================
// {{{

  assign ddr_req  = ddr_req$;
  assign ddr_mode = ddr_mode$;
  assign ddr_base = ddr_base$;
  assign ddr_len  = ddr_len$;

  assign ddr_rdata  = ddr_which$ == ALPHA ? buf_rdata[BRAVO]
                    : ddr_which$ == BRAVO ? buf_rdata[ALPHA]
                    : ddr_which$ == PRE   ? pre_rdata
                    : ddr_which$ == POST  ? post_rdata
                    : 0;

  always @(posedge clk)
    if (!xrst)
      ddr_req$ <= 0;
    else
      case (state$[0])
        S_IDLE:
          ddr_req$ <= 0;
        S_PREF:
          ddr_req$ <= s_pref_edge;
        S_READ:
          ddr_req$ <= s_read_edge
                    || RATE*BURST_LEN < count_len$ && switch_buf$;
        S_WRITE:
          ddr_req$ <= switch_buf;
        default:
          ddr_req$ <= 0;
      endcase

  always @(posedge clk)
    if (!xrst)
      ddr_mode$ <= 0;
    else
      case (state$[0])
        S_IDLE:
          ddr_mode$ <= 0;
        S_PREF:
          ddr_mode$ <= DDR_READ;
        S_READ:
          ddr_mode$ <= DDR_READ;
        S_WRITE:
          ddr_mode$ <= DDR_WRITE;
        default:
          ddr_mode$ <= 0;
      endcase

  always @(posedge clk)
    if (!xrst)
      ddr_base$ <= 0;
    else
      case (state$[0])
        S_IDLE:
          ddr_base$ <= 0;
        S_PREF:
          ddr_base$ <= base_addr$;
        S_READ:
          case (which$)
            ALPHA:    ddr_base$ <= buf_base$[ALPHA] + BURST_LEN;
            BRAVO:    ddr_base$ <= buf_base$[BRAVO] + BURST_LEN;
            PRE:      ddr_base$ <= base_addr$       + BURST_LEN;
            POST:     ddr_base$ <= 0;
            default:  ddr_base$ <= 0;
          endcase
        S_WRITE:
          case (which$)
            ALPHA:    ddr_base$ <= buf_base$[ALPHA];
            BRAVO:    ddr_base$ <= buf_base$[BRAVO];
            PRE:      ddr_base$ <= base_addr$;
            POST:     ddr_base$ <= 0;
            default:  ddr_base$ <= 0;
          endcase
        default:
          ddr_base$ <= 0;
      endcase

  assign rest_len = count_len$ - RATE*BURST_LEN;
  always @(posedge clk)
    if (!xrst)
      ddr_len$ <= 0;
    else
      case (state$[0])
        S_IDLE:
          ddr_len$ <= 0;

        S_PREF:
          if (0 < count_len$ && count_len$ <= RATE*BURST_LEN)
            ddr_len$ <= count_len$[LWIDTH-1:RATELOG]
                      +| count_len$[RATELOG-1:0];
          else
            ddr_len$ <= BURST_LEN;

        S_READ:
          if (RATE*BURST_LEN < count_len$ && count_len$ <= 2*RATE*BURST_LEN)
            ddr_len$ <= rest_len[LWIDTH-1:RATELOG]
                      +| rest_len[RATELOG-1:0];
          else
            ddr_len$ <= BURST_LEN;

        S_WRITE:
          if (0 < count_len$ && count_len$ <= RATE*BURST_LEN)
            ddr_len$ <= count_len$[LWIDTH-1:RATELOG]
                      +| count_len$[RATELOG-1:0];
          else
            ddr_len$ <= BURST_LEN;

        default:
          ddr_len$ <= 0;
      endcase

  always @(posedge clk)
    if (!xrst)
      ddr_which$ <= PRE;
    else
      ddr_which$ <= which$;

// }}}
//==========================================================
// prefetcher
//==========================================================
// {{{

  assign pre_we     = gen_pre_we(mem_we, ddr_we);
  assign pre_addr   = gen_pre_addr(mem_addr, ddr_waddr, base_addr$);
  assign pre_wdata  = gen_pre_wdata(mem_wdata, ddr_wdata);

  always @(posedge clk)
    if (!xrst)
      pref_len$ <= 0;
    else if (total_len$ < BURST_LEN)
      pref_len$ <= rest_len;
    else
      pref_len$ <= BURST_LEN;

  mem_sp #(BWIDTH, BUFSIZE) mem_pre(
    .mem_we     (pre_we),
    .mem_addr   (pre_addr),
    .mem_wdata  (pre_wdata),
    .mem_rdata  (pre_rdata),
    .*
  );

  function gen_pre_we
    ( input mem_we
    , input ddr_we
    );

    case (which$)
      PRE:
        if (state$[0] == S_PREF)
          gen_pre_we = ddr_we;
        else
          // gen_pre_we = mem_we;
          gen_pre_we = 0;
      default:
        gen_pre_we = 0;
    endcase
  endfunction

  function [BUFSIZE-1:0] gen_pre_addr
    ( input [IMGSIZE-1:0] mem_addr
    , input [IMGSIZE-1:0] ddr_waddr
    , input [IMGSIZE-1:0] base_addr$
    );

    case (which$)
      PRE:
        if (state$[0] == S_PREF)
          gen_pre_addr = ddr_waddr - base_addr$;
        else
          gen_pre_addr = mem_addr - base_addr$ >> RATELOG;
      default:
        gen_pre_addr = 0;
    endcase
  endfunction

  function signed [BWIDTH-1:0] gen_pre_wdata
    ( input signed [DWIDTH-1:0] mem_wdata
    , input signed [BWIDTH-1:0] ddr_wdata
    );

    case (which$)
      PRE:
        if (state$[0] == S_PREF)
          gen_pre_wdata = ddr_wdata;
        else
          gen_pre_wdata = mem_wdata;
      default:
        gen_pre_wdata = 0;
    endcase
  endfunction

// }}}
//==========================================================
// buffer control
//==========================================================
// {{{

  assign switch_buf = count_len$ > RATE*BURST_LEN
                   && count_inner$ == RATE * BURST_LEN - 1;
  // assign switch_buf = switch_buf$;

  always @(posedge clk)
    if (!xrst)
      switch_buf$ <= 0;
    else if (count_len$ > RATE*BURST_LEN && count_inner$ == RATE * BURST_LEN - 1)
      switch_buf$ <= 1;
    else
      switch_buf$ <= 0;

  always @(posedge clk)
    if (!xrst)
      first_buf$ <= ALPHA;
    else if (java)
      case (which$)
        ALPHA:    first_buf$ <= BRAVO;
        BRAVO:    first_buf$ <= ALPHA;
        default:  first_buf$ <= ALPHA;
      endcase

  always @(posedge clk)
    if (!xrst)
      we_accum$ <= 0;
    else if (mem_we$)
      if (we_accum$ == RATE - 1)
        we_accum$ <= 0;
      else
        we_accum$ <= we_accum$ + 1;

  always @(posedge clk)
    if (!xrst)
      buf_we$ <= 0;
    else
      buf_we$ <= mem_we$ && we_accum$ == RATE-1;

  always @(posedge clk)
    if (!xrst)
      buf_addr$ <= 0;
    else if (state$[0] == S_IDLE)
      buf_addr$ <= 0;
    else
      buf_addr$ <= mem_addr$ - (buf_base$[which$[0]] + mem_diff$)
                 >> RATELOG;

  always @(posedge clk)
    if (!xrst)
      buf_wdata$ <= 0;
    else
      buf_wdata$ <= {buf_wdata$[BWIDTH-DWIDTH-1:0], mem_wdata$};

  // one is for user interface, other is for ddr interface
  // roles switch for each burst
  for (genvar i = 0; i < 2; i++) begin : double
    assign buf_we[i]    = gen_buf_we(i, buf_we$, ddr_we);
    assign buf_addr[i]  = gen_buf_addr(i, buf_addr$, ddr_waddr, ddr_raddr, mem_addr, buf_base$, mem_diff$);
    assign buf_wdata[i] = gen_buf_wdata(i, buf_wdata$, ddr_wdata);

    always @(posedge clk)
      if (!xrst)
        buf_base$[i] <= 0;
      else if (mem_we$ && txn_start)
        buf_base$[i] <= mem_addr$;
      else if (!mem_we$ && txn_start)
        buf_base$[i] <= mem_addr$ + BURST_LEN;
      else if (which$ == reg_which'((i+1)%2) && switch_buf)
        buf_base$[i] <= buf_base$[(i+1)%2] + BURST_LEN;

    mem_sp #(BWIDTH, BUFSIZE) mem_buf(
      .mem_we     (buf_we[i]),
      .mem_addr   (buf_addr[i]),
      .mem_wdata  (buf_wdata[i]),
      .mem_rdata  (buf_rdata[i]),
      .*
    );
  end : double

  function gen_buf_we
    ( input integer i
    , input buf_we$
    , input ddr_we
    );

    if (reg_which'(i) == ALPHA)
      case (which$)
        ALPHA:
          gen_buf_we = buf_we$;
        BRAVO:
          gen_buf_we = ddr_we;
        PRE:
          if (first_buf$ == ALPHA && state$[0] != S_PREF)
            gen_buf_we = ddr_we;
          else
            gen_buf_we = 0;
        POST:
          gen_buf_we = 0;
        default:
          gen_buf_we = 0;
      endcase
    else
      case (which$)
        BRAVO:
          gen_buf_we = buf_we$;
        ALPHA:
          gen_buf_we = ddr_we;
        PRE:
          if (first_buf$ == BRAVO && state$[0] != S_PREF)
            gen_buf_we = ddr_we;
          else
            gen_buf_we = 0;
        POST:
          gen_buf_we = 0;
        default:
          gen_buf_we = 0;
      endcase
  endfunction

  function [BUFSIZE-1:0] gen_buf_addr
    ( input integer i
    , input [BUFSIZE-1:0] buf_addr$
    , input [IMGSIZE-1:0] ddr_waddr
    , input [IMGSIZE-1:0] ddr_raddr
    , input [IMGSIZE-1:0] mem_addr
    , input [IMGSIZE-1:0] buf_base$ [1:0]
    , input [LWIDTH-1:0]  mem_diff$
    );

    if (reg_which'(i) == ALPHA)
      case (which$)
        ALPHA:
          if (state$[0] == S_READ)
            gen_buf_addr = mem_addr - (buf_base$[i] + mem_diff$) >> RATELOG;
          else
            gen_buf_addr = buf_addr$;
        BRAVO:
          if (state$[0] == S_WRITE)
            gen_buf_addr = ddr_raddr - buf_base$[i];
          else
            gen_buf_addr = ddr_waddr - buf_base$[i];
        PRE:
          if (first_buf$ == ALPHA && state$[0] != S_PREF)
            gen_buf_addr = ddr_waddr - buf_base$[i];
          else
            gen_buf_addr = 0;
        POST:
          gen_buf_addr = 0;
        default:
          gen_buf_addr = 0;
      endcase
    else
      case (which$)
        BRAVO:
          if (state$[0] == S_READ)
            gen_buf_addr = mem_addr - (buf_base$[i] + mem_diff$) >> RATELOG;
          else
            gen_buf_addr = buf_addr$;
        ALPHA:
          if (state$[0] == S_WRITE)
            gen_buf_addr = ddr_raddr - buf_base$[i];
          else
            gen_buf_addr = ddr_waddr - buf_base$[i];
        PRE:
          if (first_buf$ == BRAVO && state$[0] != S_PREF)
            gen_buf_addr = ddr_waddr - buf_base$[i];
          else
            gen_buf_addr = 0;
        POST:
          gen_buf_addr = 0;
        default:
          gen_buf_addr = 0;
      endcase
  endfunction

  function signed [BWIDTH-1:0] gen_buf_wdata
    ( input integer i
    , input [BWIDTH-1:0] buf_wdata$
    , input [BWIDTH-1:0] ddr_wdata
    );

    if (reg_which'(i) == ALPHA)
      case (which$)
        ALPHA:
          gen_buf_wdata = buf_wdata$;
        BRAVO:
          gen_buf_wdata = ddr_wdata;
        PRE:
          if (first_buf$ == ALPHA && state$[0] != S_PREF)
            gen_buf_wdata = ddr_wdata;
          else
            gen_buf_wdata = 0;
        POST:
          gen_buf_wdata = 0;
        default:
          gen_buf_wdata = 0;
      endcase
    else
      case (which$)
        BRAVO:
          gen_buf_wdata = buf_wdata$;
        ALPHA:
          gen_buf_wdata = ddr_wdata;
        PRE:
          if (first_buf$ == BRAVO && state$[0] != S_PREF)
            gen_buf_wdata = ddr_wdata;
          else
            gen_buf_wdata = 0;
        POST:
          gen_buf_wdata = 0;
        default:
          gen_buf_wdata = 0;
      endcase
  endfunction

// }}}
//==========================================================
// post process
//==========================================================
// {{{

  assign post_we     = gen_post_we(mem_we, ddr_we);
  assign post_addr   = gen_post_addr(mem_addr, ddr_addr, base_addr$);
  assign post_wdata  = gen_post_wdata(mem_wdata, ddr_wdata);

  mem_sp #(BWIDTH, BUFSIZE) mem_post(
    .mem_we     (post_we),
    .mem_addr   (post_addr),
    .mem_wdata  (post_wdata),
    .mem_rdata  (post_rdata),
    .*
  );

  always @(posedge clk)
    if (!xrst)
      count_post$ <= 0;
    else if (java)
      count_post$ <= 1;
    else if (count_post$ > 0)
      if (count_post$ == RATE*BURST_LEN-1)
        count_post$ <= 0;
      else
        count_post$ <= count_post$ + 1;

  function gen_post_we
    ( input mem_we
    , input ddr_we
    );

    case (which$)
      POST:
        if (state$[0] == S_PREF)
          gen_post_we = ddr_we;
        else
          // gen_post_we = mem_we;
          gen_post_we = 0;
      default:
        gen_post_we = 0;
    endcase
  endfunction

  function [BUFSIZE-1:0] gen_post_addr
    ( input [IMGSIZE-1:0] mem_addr
    , input [IMGSIZE-1:0] ddr_addr
    , input [IMGSIZE-1:0] base_addr$
    );

    case (which$)
      POST:
        if (state$[0] == S_PREF)
          gen_post_addr = ddr_addr - base_addr$;
        else
          gen_post_addr = mem_addr - base_addr$ >> RATELOG;
      default:
        gen_post_addr = 0;
    endcase
  endfunction

  function signed [BWIDTH-1:0] gen_post_wdata
    ( input signed [DWIDTH-1:0] mem_wdata
    , input signed [BWIDTH-1:0] ddr_wdata
    );

    case (which$)
      POST:
        if (state$[0] == S_PREF)
          gen_post_wdata = ddr_wdata;
        else
          gen_post_wdata = mem_wdata;
      default:
        gen_post_wdata = 0;
    endcase
  endfunction

// }}}
endmodule
