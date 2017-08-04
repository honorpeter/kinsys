`include "renkon.svh"

module renkon_ctrl_pool
  ( input               clk
  , input               xrst
  , ctrl_bus.slave      in_ctrl
  , input  [LWIDTH-1:0] w_fea_size
  , input  [LWIDTH-1:0] pool_size
  , ctrl_bus.master     out_ctrl
  , output              pool_oe
  , output [LWIDTH-1:0] w_pool_size
  , output [$clog2(PSIZE+1):0]        buf_feat_wsel
  , output [$clog2(PSIZE+1):0]        buf_feat_rsel
  , output                            buf_feat_we
  , output [$clog2(D_POOLBUF+1)-1:0]  buf_feat_addr
  );

  ctrl_bus pool_ctrl();

  wire                            buf_feat_req;
  wire                            buf_feat_ack;
  wire                            buf_feat_start;
  wire                            buf_feat_valid;
  wire                            buf_feat_stop;

  enum reg {
    S_WAIT, S_ACTIVE
  } state$;
  reg              buf_feat_req$;
  reg [LWIDTH-1:0] fea_size$;
  reg [LWIDTH-1:0] pool_size$;
  reg [LWIDTH-1:0] d_poolbuf$;
  reg [LWIDTH-1:0] pool_x$;
  reg [LWIDTH-1:0] pool_y$;
  reg [LWIDTH-1:0] pool_exec_x$;
  reg [LWIDTH-1:0] pool_exec_y$;
  ctrl_reg         pool_ctrl$  [D_POOLBUF-1:0];
  ctrl_reg         out_ctrl$   [D_POOL-1:0];

  // To avoid below:
  //   > Index xxxxxxxxxx into array dimension [32:0] is out of bounds.
  initial d_poolbuf$ = 0;

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

  assign w_pool_size = pool_size$;

  // TODO: parameterize
  initial d_poolbuf$ = 0;
  always @(posedge clk)
    if (!xrst) begin
      fea_size$  <= 0;
      pool_size$ <= 0;
      d_poolbuf$ <= 0;
    end
    else if (state$ == S_WAIT && in_ctrl.start) begin
      fea_size$  <= w_fea_size;
      pool_size$ <= pool_size;
      d_poolbuf$ <= w_fea_size + 2;
    end

  always @(posedge clk)
    if (!xrst) begin
      pool_x$ <= 0;
      pool_y$ <= 0;
      pool_exec_x$ <= 0;
      pool_exec_y$ <= 0;
    end
    else
      case (state$)
        S_WAIT: begin
          pool_x$ <= 0;
          pool_y$ <= 0;
          pool_exec_x$ <= 0;
          pool_exec_y$ <= 0;
        end
        S_ACTIVE:
          if (in_ctrl.valid) begin
            if (pool_x$ == fea_size$ - 1) begin
              pool_x$ <= 0;
              if (pool_y$ == fea_size$ - 1)
                pool_y$ <= 0;
              else
                pool_y$ <= pool_y$ + 1;
              if (pool_exec_y$ == pool_size$ - 1)
                pool_exec_y$ <= 0;
              else
                pool_exec_y$ <= pool_exec_y$ + 1;
            end
            else
              pool_x$ <= pool_x$ + 1;
            if (pool_exec_x$ == pool_size$ - 1)
              pool_exec_x$ <= 0;
            else
              pool_exec_x$ <= pool_exec_x$ + 1;
          end
      endcase

  reg [LWIDTH-1:0] temp_x$;
  reg [LWIDTH-1:0] temp_y$;
  reg [LWIDTH-1:0] temp_exec_x$;
  reg [LWIDTH-1:0] temp_exec_y$;
  always @(posedge clk)
    if (!xrst) begin
      temp_x$ <= 0;
      temp_y$ <= 0;
      temp_exec_x$ <= 0;
      temp_exec_y$ <= 0;
    end
    else if (buf_feat_ack) begin
      temp_x$      <= 0;
      temp_y$      <= 0;
      temp_exec_x$ <= 0;
      temp_exec_y$ <= 0;
    end
    else begin
      if (temp_x$ == fea_size$ - pool_size$) begin
        temp_x$ <= 0;

        if (temp_y$ == fea_size$ - pool_size$)
          temp_y$ <= 0;
        else
          temp_y$ <= temp_y$ + 1;

        if (temp_exec_y$ == pool_size$ - 1)
          temp_exec_y$ <= 0;
        else
          temp_exec_y$ <= temp_exec_y$ + 1;
      end
      else if (buf_feat_valid)
        temp_x$ <= temp_x$ + 1;

      if (temp_exec_x$ == pool_size$ - 1)
        temp_exec_x$ <= 0;
      else if (buf_feat_valid)
        temp_exec_x$ <= temp_exec_x$ + 1;
    end

//==========================================================
// pool control
//==========================================================

  assign buf_feat_req = in_ctrl.start;
  // assign buf_feat_req = buf_feat_req$;

  // assign pool_ctrl.start = temp_ctrl$.start;
  // assign pool_ctrl.valid = temp_ctrl$.valid;
  // assign pool_ctrl.stop  = temp_ctrl$.stop;

  assign pool_ctrl.start = pool_ctrl$[d_poolbuf$].start;
  assign pool_ctrl.valid = pool_ctrl$[d_poolbuf$].valid;
  assign pool_ctrl.stop  = pool_ctrl$[d_poolbuf$].stop;

  always @(posedge clk)
    if (!xrst)
      buf_feat_req$ <= 0;
    else
      buf_feat_req$ <= in_ctrl.start;

  reg buf_feat_valid$;
  always @(posedge clk)
    buf_feat_valid$ <= buf_feat_valid;
  wire buf_feat_valid_edge = buf_feat_valid && !buf_feat_valid$;

  ctrl_reg         temp_ctrl$;
  wire temp_ctrl$_start = buf_feat_start;
  wire temp_ctrl$_valid = buf_feat_valid
                       && temp_exec_x$ == 0 && temp_exec_y$ == 0;
  wire temp_ctrl$_stop  = buf_feat_stop;
  always @(posedge clk)
    if (!xrst) begin
      temp_ctrl$.start <= 0;
      temp_ctrl$.valid <= 0;
      temp_ctrl$.stop  <= 0;
    end
    else begin
      assert (temp_ctrl$_start == pool_ctrl.start);
      assert (temp_ctrl$_valid == pool_ctrl.valid);
      assert (temp_ctrl$_stop  == pool_ctrl.stop);
      temp_ctrl$.start <= state$ == S_ACTIVE
                       && buf_feat_start;

      temp_ctrl$.valid <= state$ == S_ACTIVE
                       && temp_exec_x$ == 0
                       && temp_exec_y$ == 0
                       && buf_feat_valid;

      temp_ctrl$.stop  <= state$ == S_ACTIVE
                       && buf_feat_stop;
    end

  for (genvar i = 0; i < D_POOLBUF; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst) begin
          pool_ctrl$[0].start <= 0;
          pool_ctrl$[0].valid <= 0;
          pool_ctrl$[0].stop  <= 0;
        end
        else begin
          pool_ctrl$[0].start <= state$ == S_ACTIVE
                              && pool_x$ == pool_size$ - 2
                              && pool_y$ == pool_size$ - 1;

          pool_ctrl$[0].valid <= state$ == S_ACTIVE
                              && pool_exec_x$ == pool_size$ - 1
                              && pool_exec_y$ == pool_size$ - 1;

          pool_ctrl$[0].stop  <= state$ == S_ACTIVE
                              && pool_x$ == fea_size$ - 1
                              && pool_y$ == fea_size$ - 1;
        end
    else
      always @(posedge clk)
        if (!xrst) begin
          pool_ctrl$[i].start <= 0;
          pool_ctrl$[i].valid <= 0;
          pool_ctrl$[i].stop  <= 0;
        end
        else begin
          pool_ctrl$[i].start <= pool_ctrl$[i-1].start;
          pool_ctrl$[i].valid <= pool_ctrl$[i-1].valid;
          pool_ctrl$[i].stop  <= pool_ctrl$[i-1].stop;
        end

  renkon_ctrl_linebuf #(PSIZE, D_POOLBUF) ctrl_buf_feat(
    .img_size   (w_fea_size),
    .fil_size   (w_pool_size),

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

//==========================================================
// output control
//==========================================================

  assign out_ctrl.start = out_ctrl$[D_POOL-1].start;
  assign out_ctrl.valid = out_ctrl$[D_POOL-1].valid;
  assign out_ctrl.stop  = out_ctrl$[D_POOL-1].stop;
  assign pool_oe        = out_ctrl$[D_POOL-2].valid;

  for (genvar i = 0; i < D_POOL; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst) begin
          out_ctrl$[0].start <= 0;
          out_ctrl$[0].valid <= 0;
          out_ctrl$[0].stop  <= 0;
        end
        else begin
          // out_ctrl$[0].start <= pool_ctrl.start;
          // out_ctrl$[0].valid <= pool_ctrl.valid;
          // out_ctrl$[0].stop  <= pool_ctrl.stop;
          out_ctrl$[0].start <= buf_feat_start;
          out_ctrl$[0].valid <= buf_feat_valid
                             && temp_exec_x$ == 0 && temp_exec_y$ == 0;
          out_ctrl$[0].stop  <= buf_feat_stop;
        end
    else
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

endmodule
