`include "ninjin.svh"

module ninjin_ddr_buf
  ( input                     clk
  , input                     xrst
  // meta inputs
  , input                     pre_req
  , input [WORDSIZE-1:0]      pre_base
  , input [LWIDTH-1:0]        read_len
  , input [LWIDTH-1:0]        write_len
  // memory ports
  , input                     mem_we
  , input [MEMSIZE-1:0]       mem_addr
  , input signed [DWIDTH-1:0] mem_wdata
  // m_axi ports (fed back)
  , input                     ddr_we
  , input [WORDSIZE-1:0]      ddr_waddr
  , input [BWIDTH-1:0]        ddr_wdata
  , input [WORDSIZE-1:0]      ddr_raddr
  // meta outputs
  , output                      pre_ack
  // m_axi signals
  , output                      ddr_req
  , output                      ddr_mode
  , output [WORDSIZE+LSB-1:0]   ddr_base
  , output [LWIDTH-1:0]         ddr_len
  , output [BWIDTH-1:0]         ddr_rdata
  // memory data
  , output signed [DWIDTH-1:0]  mem_rdata
  );

  localparam  M_IDLE  = 'd0,
              M_INCR  = 'd1,
              M_TRANS = 'd2;

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
  wire [BWIDTH-1:0]           buf_wdata [1:0];
  wire [BWIDTH-1:0]           buf_rdata [1:0];
  wire                        pre_req_edge;
  wire                        pre_we;
  wire [BUFSIZE-1:0]          pre_addr;
  wire [BWIDTH-1:0]           pre_wdata;
  wire [BWIDTH-1:0]           pre_rdata;
  wire                        post_we;
  wire [BUFSIZE-1:0]          post_addr;
  wire [BWIDTH-1:0]           post_wdata;
  wire [BWIDTH-1:0]           post_rdata;
  wire                        switch_buf;
  wire                        switch_post_main;
  wire                        switch_post_sub;
  wire signed [MEMSIZE-1:0]   addr_diff;
  wire [BUFSIZE+RATELOG-1:0]  addr_offset;
  wire [RATELOG-1:0]          word_offset;
  wire signed [DWIDTH-1:0]    alpha [RATE-1:0];
  wire signed [DWIDTH-1:0]    bravo [RATE-1:0];
  wire signed [DWIDTH-1:0]    pre   [RATE-1:0];
  wire [LWIDTH-1:0]           burst_len;
  wire [LWIDTH-1:0]           rest_len;

  typedef enum reg [1:0] {
    ALPHA=0, BRAVO=1, PRE=2, POST=3
  } reg_which;

  enum reg [1:0] {
    S_IDLE=0, S_PREF=1, S_READ=2, S_WRITE=3
  } state$ [1:0];
  reg_which               which$;
  reg [1:0]               mode$;
  reg_which               mem_which$;
  reg                     mem_we$;
  reg [MEMSIZE-1:0]       mem_addr$;
  reg signed [DWIDTH-1:0] mem_wdata$;
  reg_which               ddr_which$;
  reg                     ddr_req$;
  reg                     ddr_mode$;
  reg [WORDSIZE+LSB-1:0]  ddr_base$;
  reg [LWIDTH-1:0]        ddr_len$;
  reg                     buf_we$;
  reg [BUFSIZE-1:0]       buf_addr$;
  reg [BWIDTH-1:0]        buf_wdata$;
  reg [WORDSIZE-1:0]      buf_base$ [1:0];
  reg                     pre_req$;
  reg                     pre_ack$;
  reg [WORDSIZE-1:0]      pre_base$;
  reg [WORDSIZE-1:0]      post_base$;
  reg [RATE-1:0]          we_accum$;
  reg [MEMSIZE-1:0]       read_len$;
  reg [MEMSIZE-1:0]       write_len$;
  reg [MEMSIZE-1:0]       count_len$;
  reg [LWIDTH-1:0]        count_buf$;
  reg [LWIDTH-1:0]        count_post$;
  reg                     switch_buf$;
  reg_which               first_buf$;
  reg [RATELOG-1:0]       word_offset$;
  reg [BUFSIZE-1:0]       post_addr$;
  reg [LWIDTH-1:0]        post_len$;

//==========================================================
// core control
//==========================================================
// {{{

  assign s_pref_end  = state$[0] == S_PREF
                    && burst_len != 0 && count_buf$ == burst_len-1;
  assign s_read_end  = state$[0] == S_READ
                    && count_len$ != 0 && count_buf$ == count_len$-1;
  assign s_write_end = state$[0] == S_WRITE
                    && count_len$ != 0 && count_buf$ == count_len$-1;

  assign s_pref_edge  = state$[0] == S_PREF  && state$[1] != S_PREF;
  assign s_read_edge  = state$[0] == S_READ  && state$[1] != S_READ;
  assign s_write_edge = state$[0] == S_WRITE && state$[1] != S_WRITE;

  assign pre_ack      = pre_ack$;
  assign pre_req_edge = pre_req && !pre_req$;

  assign addr_diff = mem_addr - mem_addr$;

  assign mode = addr_diff == 0 ? M_IDLE
              : addr_diff == 1 ? M_INCR
              : M_TRANS;

  for (genvar i = 0; i < 2; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst)
          state$[0] <= S_IDLE;
        else
          case (state$[0])
            S_IDLE:
              if (pre_req_edge)
                state$[0] <= S_PREF;
              else if (txn_start)
                if (mem_we$)
                  state$[0] <= S_WRITE;
                else
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
      pre_req$ <= 0;
    else
      pre_req$ <= pre_req;

  always @(posedge clk)
    if (!xrst)
      pre_ack$ <= 1;
    else if (pre_req_edge)
      pre_ack$ <= 0;
    else if (s_pref_end)
      pre_ack$ <= 1;

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
          else if (switch_post_main)
            which$ <= POST;
          else if (switch_buf)
            which$ <= BRAVO;

        BRAVO:
          if (s_read_end || s_write_end)
            which$ <= PRE;
          else if (switch_post_main)
            which$ <= POST;
          else if (switch_buf)
            which$ <= ALPHA;

        PRE:
          if (txn_start && mem_we$)
            if (write_len$ <= RATE*BURST_MAX)
              which$ <= POST;
            else
              which$ <= first_buf$;
          else if (switch_buf)
            which$ <= first_buf$;

        POST:
          if (s_write_end)
            which$ <= PRE;

        default:
          which$ <= PRE;
      endcase

// }}}
//==========================================================
// counter control
//==========================================================
// {{{

  assign burst_len = count_len$ > RATE*BURST_MAX ? BURST_MAX : count_len$ >> RATELOG;

  always @(posedge clk)
    if (!xrst) begin
      read_len$   <= 0;
      write_len$  <= 0;
    end
    else if (pre_req_edge) begin
      read_len$   <= read_len;
      write_len$  <= write_len;
    end

  always @(posedge clk)
    if (!xrst)
      count_len$ <= 0;
    else if (s_pref_end || s_read_end || s_write_end)
      count_len$ <= 0;
    else if (pre_req_edge)
      count_len$ <= read_len;
    else if (txn_start)
      if (mem_we$)
        count_len$ <= write_len$;
      else
        count_len$ <= read_len$;
    else if (switch_buf)
      count_len$ <= count_len$ - RATE*BURST_MAX;

  always @(posedge clk)
    if (!xrst)
      count_buf$ <= 0;
    else
      case (state$[0])
        S_IDLE:
          if (txn_start && !mem_we$)
            count_buf$ <= 2;
          else
            count_buf$ <= 0;
        S_WRITE:
          // if (mem_we$)
            if (count_buf$ == RATE*BURST_MAX-1)
              count_buf$ <= 0;
            else
              count_buf$ <= count_buf$ + 1;
        S_PREF:
          if (pre_we)
            if (count_buf$ == RATE*burst_len-1)
              count_buf$ <= 0;
            else
              count_buf$ <= count_buf$ + 1;
        S_READ:
          if (s_read_end)
            count_buf$ <= 0;
          else if (mode == M_INCR)
            if (count_buf$ == RATE*burst_len-1)
              count_buf$ <= 0;
            else
              count_buf$ <= count_buf$ + txn_start + 1;
      endcase

// }}}
//==========================================================
// memory control
//==========================================================
// {{{

  // assign addr_offset  = mem_addr - pre_base$;
  assign addr_offset  = mem_addr - (pre_base$ << RATELOG);
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
  end

  assign mem_rdata  = mem_we$             ? mem_wdata$
                    : mem_which$ == ALPHA ? alpha[word_offset$]
                    : mem_which$ == BRAVO ? bravo[word_offset$]
                    : mem_which$ == PRE   ? pre[word_offset$]
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
    else if (mode == M_INCR)
      mem_which$ <= which$;
    else if (state$[0] == S_IDLE)
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
                    : ddr_which$ == POST  ? post_rdata
                    : 0;

  always @(posedge clk)
    if (!xrst)
      ddr_req$ <= 0;
    else if (ddr_which$ != POST && switch_post_sub)
      ddr_req$ <= 1;
    else
      case (state$[0])
        S_IDLE:
          ddr_req$ <= 0;
        S_PREF:
          ddr_req$ <= s_pref_edge;
        S_READ:
          ddr_req$ <= (read_len$ > RATE*BURST_MAX ? s_read_edge : 0)
                   || switch_buf$ && RATE*BURST_MAX < count_len$;
        S_WRITE:
          ddr_req$ <= (write_len$ > RATE*BURST_MAX ? 0 : s_write_end)
                   || switch_buf;
        default:
          ddr_req$ <= 0;
      endcase

  always @(posedge clk)
    if (!xrst)
      ddr_mode$ <= 0;
    else if (ddr_which$ != POST && switch_post_sub)
      ddr_mode$ <= DDR_WRITE;
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
    else if (ddr_which$ != POST && switch_post_sub)
      ddr_base$ <= post_base$ << LSB;
    else
      case (state$[0])
        S_IDLE:
          ddr_base$ <= 0;
        S_PREF:
          ddr_base$ <= pre_base$ << LSB;
        S_READ:
          case (which$)
            ALPHA:    ddr_base$ <= (buf_base$[ALPHA] + BURST_MAX) << LSB;
            BRAVO:    ddr_base$ <= (buf_base$[BRAVO] + BURST_MAX) << LSB;
            PRE:      ddr_base$ <= (pre_base$        + BURST_MAX) << LSB;
            default:  ddr_base$ <= 0;
          endcase
        S_WRITE:
          case (which$)
            ALPHA:    ddr_base$ <= buf_base$[ALPHA] << LSB;
            BRAVO:    ddr_base$ <= buf_base$[BRAVO] << LSB;
            POST:     ddr_base$ <= post_base$       << LSB;
            default:  ddr_base$ <= 0;
          endcase
        default:
          ddr_base$ <= 0;
      endcase

  assign rest_len = count_len$ - RATE*BURST_MAX;
  always @(posedge clk)
    if (!xrst)
      ddr_len$ <= 0;
    else if (ddr_which$ != POST && switch_post_sub)
      ddr_len$ <= (post_len$ >> RATELOG) + |post_len$[RATELOG-1:0];
    else
      case (state$[0])
        S_IDLE:
          ddr_len$ <= 0;

        S_PREF:
          if (0 < read_len$ && read_len$ <= RATE*BURST_MAX)
            ddr_len$ <= (read_len$ >> RATELOG) + |read_len$[RATELOG-1:0];
          else
            ddr_len$ <= BURST_MAX;

        S_READ:
          if (RATE*BURST_MAX < count_len$ && count_len$ <= 2*RATE*BURST_MAX)
            ddr_len$ <= (rest_len >> RATELOG) + |rest_len[RATELOG-1:0];
          else
            ddr_len$ <= BURST_MAX;

        S_WRITE:
          if (0 < count_len$ && count_len$ <= RATE*BURST_MAX)
            ddr_len$ <= (count_len$ >> RATELOG) + |count_len$[RATELOG-1:0];
          else
            ddr_len$ <= BURST_MAX;

        default:
          ddr_len$ <= 0;
      endcase

  always @(posedge clk)
    if (!xrst)
      ddr_which$ <= PRE;
    else if (switch_post_main)
      if (write_len$ <= RATE*BURST_MAX)
        ddr_which$ <= POST;
      else
        case (ddr_which$)
          ALPHA:    ddr_which$ <= BRAVO;
          BRAVO:    ddr_which$ <= ALPHA;
          default:  ddr_which$ <= ddr_which$;
        endcase
    else if (switch_post_sub)
      if (write_len$ <= RATE*BURST_MAX)
        ddr_which$ <= which$;
      else
        case (ddr_which$)
          POST:     ddr_which$ <= which$;
          default:  ddr_which$ <= POST;
        endcase
    else if (ddr_which$ != POST && count_post$ == 0)
      ddr_which$ <= which$;

// }}}
//==========================================================
// prefetcher
//==========================================================
// {{{

  assign pre_we     = gen_pre_we(ddr_we);
  assign pre_addr   = gen_pre_addr(mem_addr, ddr_waddr, pre_base$);
  assign pre_wdata  = gen_pre_wdata(ddr_wdata);

  always @(posedge clk)
    if (!xrst)
      pre_base$ <= 0;
    else
      pre_base$ <= pre_base;

  mem_sp #(BWIDTH, BUFSIZE) mem_pre(
    .mem_we     (pre_we),
    .mem_addr   (pre_addr),
    .mem_wdata  (pre_wdata),
    .mem_rdata  (pre_rdata),
    .*
  );

  function gen_pre_we
    ( input ddr_we
    );

    case (which$)
      PRE:
        if (state$[0] == S_PREF)
          gen_pre_we = ddr_we;
        else
          gen_pre_we = 0;
      default:
        gen_pre_we = 0;
    endcase
  endfunction

  function [BUFSIZE-1:0] gen_pre_addr
    ( input [MEMSIZE-1:0]  mem_addr
    , input [WORDSIZE-1:0] ddr_waddr
    , input [WORDSIZE-1:0] pre_base$
    );

    case (which$)
      PRE:
        if (state$[0] == S_PREF)
          gen_pre_addr = ddr_waddr - pre_base$;
        else
          gen_pre_addr = (mem_addr >> RATELOG) - pre_base$;
      default:
        gen_pre_addr = 0;
    endcase
  endfunction

  function [BWIDTH-1:0] gen_pre_wdata
    ( input [BWIDTH-1:0] ddr_wdata
    );

    case (which$)
      PRE:
        if (state$[0] == S_PREF)
          gen_pre_wdata = ddr_wdata;
        else
          gen_pre_wdata = 0;
      default:
        gen_pre_wdata = 0;
    endcase
  endfunction

// }}}
//==========================================================
// buffer control
//==========================================================
// {{{

  assign switch_buf = mode == M_INCR && count_len$ > RATE*BURST_MAX
                   && count_buf$ == RATE * BURST_MAX - 1;

  always @(posedge clk)
    if (!xrst)
      switch_buf$ <= 0;
    else
      switch_buf$ <= switch_buf;

  always @(posedge clk)
    if (!xrst)
      first_buf$ <= ALPHA;
    else if (switch_post_main)
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
    else
      buf_addr$ <= (mem_addr$ >> RATELOG) - buf_base$[which$[0]];

  always @(posedge clk)
    if (!xrst)
      buf_wdata$ <= 0;
    else
      buf_wdata$ <= {mem_wdata$, buf_wdata$[BWIDTH-1:DWIDTH]};

  // one is for user interface, other is for ddr interface
  // roles switch for each burst
  for (genvar i = 0; i < 2; i++) begin : double
    int j = (i + 1) % 2;

    assign buf_we[i]    = gen_buf_we(i, buf_we$, ddr_we);
    assign buf_addr[i]  = gen_buf_addr(i, buf_addr$, ddr_waddr, ddr_raddr, mem_addr, buf_base$);
    assign buf_wdata[i] = gen_buf_wdata(i, buf_wdata$, ddr_wdata);

    always @(posedge clk)
      if (!xrst)
        buf_base$[i] <= 0;
      else if (txn_start && (count_post$ == 0 || ddr_which$ != reg_which'(j)))
        if (mem_we$)
          buf_base$[i] <= (mem_addr$ >> RATELOG);
        else
          buf_base$[i] <= (mem_addr$ >> RATELOG) + BURST_MAX;
      else if (count_post$ == RATE*BURST_MAX-1 && ddr_which$ == reg_which'(j))
        buf_base$[i] <= buf_base$[j];
      else if (switch_buf && which$ == reg_which'(j))
        buf_base$[i] <= buf_base$[j] + BURST_MAX;

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
          if (state$[0] == S_READ && first_buf$ == ALPHA)
            gen_buf_we = ddr_we;
          else
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
          if (state$[0] == S_READ && first_buf$ == BRAVO)
            gen_buf_we = ddr_we;
          else
            gen_buf_we = 0;
        default:
          gen_buf_we = 0;
      endcase
  endfunction

  function [BUFSIZE-1:0] gen_buf_addr
    ( input integer i
    , input [BUFSIZE-1:0]  buf_addr$
    , input [WORDSIZE-1:0] ddr_waddr
    , input [WORDSIZE-1:0] ddr_raddr
    , input [MEMSIZE-1:0]  mem_addr
    , input [WORDSIZE-1:0] buf_base$ [1:0]
    );

    if (reg_which'(i) == ALPHA)
      if (count_post$ > 0 && ddr_which$ == BRAVO)
        gen_buf_addr = ddr_raddr - buf_base$[i];
      else
        case (which$)
          ALPHA:
            if (state$[0] == S_READ)
              gen_buf_addr = (mem_addr >> RATELOG) - buf_base$[i];
            else
              gen_buf_addr = buf_addr$;
          BRAVO:
            if (state$[0] == S_READ)
              gen_buf_addr = ddr_waddr - buf_base$[i];
            else
              gen_buf_addr = ddr_raddr - buf_base$[i];
          PRE:
            if (state$[0] == S_READ && first_buf$ == ALPHA)
              gen_buf_addr = ddr_waddr - buf_base$[i];
            else
              gen_buf_addr = 0;
          default:
            gen_buf_addr = 0;
        endcase
    else
      if (count_post$ > 0 && ddr_which$ == ALPHA)
        gen_buf_addr = ddr_raddr - buf_base$[i];
      else
        case (which$)
          BRAVO:
            if (state$[0] == S_READ)
              gen_buf_addr = (mem_addr >> RATELOG) - buf_base$[i];
            else
              gen_buf_addr = buf_addr$;
          ALPHA:
            if (state$[0] == S_READ)
              gen_buf_addr = ddr_waddr - buf_base$[i];
            else
              gen_buf_addr = ddr_raddr - buf_base$[i];
          PRE:
            if (state$[0] == S_READ && first_buf$ == BRAVO)
              gen_buf_addr = ddr_waddr - buf_base$[i];
            else
              gen_buf_addr = ddr_raddr - buf_base$[i];
          default:
            gen_buf_addr = 0;
        endcase
  endfunction

  function [BWIDTH-1:0] gen_buf_wdata
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
          if (state$[0] == S_READ && first_buf$ == ALPHA)
            gen_buf_wdata = ddr_wdata;
          else
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
          if (state$[0] == S_READ && first_buf$ == BRAVO)
            gen_buf_wdata = ddr_wdata;
          else
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

  assign post_we     = gen_post_we(buf_we$);
  assign post_addr   = gen_post_addr(post_addr$, ddr_raddr, post_base$);
  assign post_wdata  = gen_post_wdata(buf_wdata$);

  assign switch_post_main = state$[0] == S_WRITE
                          && ((
                            write_len$ > RATE*BURST_MAX
                            && RATE*BURST_MAX < count_len$ && count_len$ <= 2*RATE*BURST_MAX
                            && count_buf$ == RATE * BURST_MAX - 1
                          ) || (
                            write_len$ <= RATE*BURST_MAX
                            && count_buf$ == count_len$ - 1
                          ));


  assign switch_post_sub  = write_len$ > RATE*BURST_MAX
                          && count_post$ == RATE * BURST_MAX - 1;

  always @(posedge clk)
    if (!xrst)
      count_post$ <= 0;
    else if (switch_post_main)
      count_post$ <= 1;
    else if (ddr_which$ == POST && count_post$ == 0)
      count_post$ <= 1;
    else if (count_post$ > 0)
      if (count_post$ == RATE*BURST_MAX-1)
        count_post$ <= 0;
      else
        count_post$ <= count_post$ + 1;

  always @(posedge clk)
    if (!xrst)
      post_base$ <= 0;
    else if (txn_start && mem_we$ && write_len$ <= RATE*BURST_MAX)
      post_base$ <= mem_addr$ >> RATELOG;
    else if (switch_post_main)
      post_base$ <= buf_base$[which$[0]] + BURST_MAX;

  always @(posedge clk)
    if (!xrst)
      post_len$ <= 0;
    else if (switch_post_main)
      post_len$ <= count_len$ - RATE*BURST_MAX;

  always @(posedge clk)
    if (!xrst)
      post_addr$ <= 0;
    else
      post_addr$ <= (mem_addr$ >> RATELOG) - post_base$;

  mem_sp #(BWIDTH, BUFSIZE) mem_post(
    .mem_we     (post_we),
    .mem_addr   (post_addr),
    .mem_wdata  (post_wdata),
    .mem_rdata  (post_rdata),
    .*
  );

  function gen_post_we
    ( input buf_we$
    );

    case (which$)
      POST:
        gen_post_we = buf_we$;
      default:
        gen_post_we = 0;
    endcase
  endfunction

  function [BUFSIZE-1:0] gen_post_addr
    ( input [WORDSIZE-1:0] post_addr$
    , input [WORDSIZE-1:0] ddr_raddr
    , input [WORDSIZE-1:0] post_base$
    );

    case (which$)
      POST:
        gen_post_addr = post_addr$;
      default:
        if (ddr_which$ == POST)
          gen_post_addr = ddr_raddr - post_base$;
        else
          gen_post_addr = 0;
    endcase
  endfunction

  function [BWIDTH-1:0] gen_post_wdata
    ( input [BWIDTH-1:0] buf_wdata$
    );

    case (which$)
      POST:
        gen_post_wdata = buf_wdata$;
      default:
        gen_post_wdata = 0;
    endcase
  endfunction

// }}}
endmodule

