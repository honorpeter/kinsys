`include "renkon.svh"

module renkon_ctrl_pool
  ( input                             clk
  , input                             xrst
  , input                             _pool_en
  , ctrl_bus.slave                    in_ctrl
  , input  [LWIDTH-1:0]               _fea_size
  , input  [LWIDTH-1:0]               _out_size
  , input  [LWIDTH-1:0]               _pool_kern
  , input  [LWIDTH-1:0]               _pool_pad
  , ctrl_bus.master                   out_ctrl
  , output                            pool_oe
  , output                            buf_feat_wcol
  , output                            buf_feat_rrow [PSIZE-1:0]
  , output [$clog2(PSIZE+1):0]        buf_feat_wsel
  , output [$clog2(PSIZE+1):0]        buf_feat_rsel
  , output                            buf_feat_we
  , output [$clog2(D_POOLBUF+1)-1:0]  buf_feat_addr
  );

  wire buf_feat_req;
  wire buf_feat_ack;
  wire buf_feat_start;
  wire buf_feat_valid;
  wire buf_feat_ready;
  wire buf_feat_stop;

  enum reg {
    S_WAIT, S_ACTIVE
  } state$;
  reg              buf_feat_req$;
  reg [LWIDTH-1:0] fea_size$;
  reg [LWIDTH-1:0] out_size$;
  reg [LWIDTH-1:0] pool_kern$;
  reg [LWIDTH-1:0] pool_pad$;
  reg [LWIDTH-1:0] pool_x$;
  reg [LWIDTH-1:0] pool_y$;
  reg [LWIDTH-1:0] pool_exec_x$;
  reg [LWIDTH-1:0] pool_exec_y$;
  ctrl_reg         out_ctrl$   [D_POOL-1:0];

//==========================================================
// main FSM
//==========================================================

  always @(posedge clk)
    if (!xrst)
      state$ <= S_WAIT;
    else
      case (state$)
        S_WAIT:
          if (in_ctrl.start)
            state$ <= S_ACTIVE;
        S_ACTIVE:
          if (out_ctrl.stop)
            state$ <= S_WAIT;
      endcase

  always @(posedge clk)
    if (!xrst) begin
      fea_size$  <= 0;
      pool_kern$ <= 0;
      pool_pad$  <= 0;
      out_size$  <= 0;
    end
    else if (state$ == S_WAIT && in_ctrl.start) begin
      fea_size$  <= _fea_size;
      pool_kern$ <= _pool_kern;
      pool_pad$  <= _pool_pad;
      out_size$  <= _out_size;
    end

  always @(posedge clk)
    if (!xrst) begin
      pool_x$ <= 0;
      pool_y$ <= 0;
      pool_exec_x$ <= 0;
      pool_exec_y$ <= 0;
    end
    else if (buf_feat_ack) begin
      pool_x$      <= 0;
      pool_y$      <= 0;
      pool_exec_x$ <= 0;
      pool_exec_y$ <= 0;
    end
    else begin
      // if (pool_x$ == fea_size$ - pool_kern$) begin
      if (pool_x$ == out_size$ - 1) begin
        pool_x$ <= 0;

        // if (pool_y$ == fea_size$ - pool_kern$)
        if (pool_y$ == out_size$ - 1)
          pool_y$ <= 0;
        else
          pool_y$ <= pool_y$ + 1;

        if (pool_exec_y$ == pool_kern$ - 1)
          pool_exec_y$ <= 0;
        else
          pool_exec_y$ <= pool_exec_y$ + 1;
      end
      else if (buf_feat_valid)
        pool_x$ <= pool_x$ + 1;

      if (pool_exec_x$ == pool_kern$ - 1)
        pool_exec_x$ <= 0;
      else if (buf_feat_valid)
        pool_exec_x$ <= pool_exec_x$ + 1;
    end

//==========================================================
// pool control
//==========================================================

  assign buf_feat_req = _pool_en ? in_ctrl.start : 0;
  // assign buf_feat_req = buf_feat_req$;

  always @(posedge clk)
    if (!xrst)
      buf_feat_req$ <= 0;
    else
      buf_feat_req$ <= in_ctrl.start;

if (0)
  renkon_ctrl_linebuf #(PSIZE, D_POOLBUF) ctrl_buf_feat(
    .img_size   (fea_size$),
    .fil_size   (pool_kern$),

    .buf_req    (buf_feat_req),
    .buf_ack    (buf_feat_ack),
    .buf_start  (buf_feat_start),
    .buf_valid  (buf_feat_valid),
    .buf_stop   (buf_feat_stop),

    .buf_wsel   (buf_feat_wsel),
    .buf_rsel   (buf_feat_rsel),
    .buf_we     (buf_feat_we),
    .buf_addr   (buf_feat_addr),
    .*
  );
else
  renkon_ctrl_linebuf_pad #(PSIZE, D_POOLBUF) ctrl_buf_feat(
    .img_size   (fea_size$),
    .fil_size   (pool_kern$),
    .pad_size   (pool_pad$),
    .buf_req    (buf_feat_req),
    .buf_delay  (in_ctrl.delay),

    .buf_ack    (buf_feat_ack),
    .buf_start  (buf_feat_start),
    .buf_valid  (buf_feat_valid),
    .buf_ready  (buf_feat_ready),
    .buf_stop   (buf_feat_stop),

    .buf_wcol   (buf_feat_wcol),
    .buf_rrow   (buf_feat_rrow),
    .buf_wsel   (buf_feat_wsel),
    .buf_rsel   (buf_feat_rsel),
    .buf_we     (buf_feat_we),
    .buf_addr   (buf_feat_addr),
    .*
  );

//==========================================================
// output control
//==========================================================

  assign in_ctrl.ready  = buf_feat_ready;
  assign out_ctrl.delay = in_ctrl.delay + D_POOL;

  assign out_ctrl.start = _pool_en
                        ? out_ctrl$[D_POOL-1].start
                        : out_ctrl$[0].start;
  assign out_ctrl.valid = _pool_en
                        ? out_ctrl$[D_POOL-1].valid
                        : out_ctrl$[0].valid;
  assign out_ctrl.stop  = _pool_en
                        ? out_ctrl$[D_POOL-1].stop
                        : out_ctrl$[0].stop;

  assign pool_oe        = out_ctrl$[D_POOL-2].valid;

  for (genvar i = 0; i < D_POOL; i++)
    if (i == 0) begin
      always @(posedge clk)
        if (!xrst) begin
          out_ctrl$[0].start <= 0;
          out_ctrl$[0].valid <= 0;
          out_ctrl$[0].stop  <= 0;
        end
        else if (!_pool_en) begin
          out_ctrl$[0].start <= in_ctrl.start;
          out_ctrl$[0].valid <= in_ctrl.valid;
          out_ctrl$[0].stop  <= in_ctrl.stop;
        end
        else begin
          out_ctrl$[0].start <= buf_feat_start;
          out_ctrl$[0].valid <= buf_feat_valid
                             && pool_exec_x$ == 0
                             && pool_exec_y$ == 0;
          out_ctrl$[0].stop  <= buf_feat_stop;
        end
    end
    else begin
      always @(posedge clk)
        if (!xrst) begin
          out_ctrl$[i].start <= 0;
          out_ctrl$[i].valid <= 0;
          out_ctrl$[i].stop  <= 0;
        end
        else begin
          out_ctrl$[i].start <= out_ctrl$[i-1].start;
          out_ctrl$[i].valid <= out_ctrl$[i-1].valid;
          out_ctrl$[i].stop  <= out_ctrl$[i-1].stop;
        end
    end

endmodule
