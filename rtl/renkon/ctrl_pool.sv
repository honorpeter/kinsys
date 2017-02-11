`include "renkon.svh"
`include "ctrl_bus.svh"

module ctrl_pool
  ( input               clk
  , input               xrst
  , ctrl_bus.in         in_ctrl
  , input  [LWIDTH-1:0] w_fea_size
  , input  [LWIDTH-1:0] pool_size
  , output              buf_feat_en
  , ctrl_bus.out        out_ctrl
  , output              pool_oe
  , output [LWIDTH-1:0] w_pool_size
  );

  ctrl_bus pool_ctrl();

  enum reg {
    S_WAIT, S_ACTIVE
  } r_state;
  reg              r_buf_feat_en;
  reg [LWIDTH-1:0] r_fea_size;
  reg [LWIDTH-1:0] r_pool_size;
  reg [LWIDTH-1:0] r_d_poolbuf;
  reg [LWIDTH-1:0] r_pool_x;
  reg [LWIDTH-1:0] r_pool_y;
  reg [LWIDTH-1:0] r_pool_exec_x;
  reg [LWIDTH-1:0] r_pool_exec_y;
  ctrl_reg         r_pool_ctrl  [D_POOLBUF-1:0];
  ctrl_reg         r_out_ctrl   [D_POOL-1:0];

//==========================================================
// main FSM
//==========================================================

  always @(posedge clk)
    if (!xrst)
      r_state <= S_WAIT;
    else
      case (r_state)
        S_WAIT:
          if (in_ctrl.start)
            r_state <= S_ACTIVE;
        S_ACTIVE:
          if (out_ctrl.stop)
            r_state <= S_WAIT;
      endcase

  assign w_pool_size = r_pool_size;

  always @(posedge clk)
    if (!xrst) begin
      r_fea_size  <= 0;
      r_pool_size <= 0;
      r_d_poolbuf <= 0;
    end
    else if (r_state == S_WAIT && in_ctrl.start) begin
      r_fea_size  <= w_fea_size;
      r_pool_size <= pool_size;
      r_d_poolbuf <= w_fea_size - pool_size + 8 - 1;
    end

  always @(posedge clk)
    if (!xrst) begin
      r_pool_x <= 0;
      r_pool_y <= 0;
      r_pool_exec_x <= 0;
      r_pool_exec_y <= 0;
    end
    else
      case (r_state)
        S_WAIT: begin
          r_pool_x <= 0;
          r_pool_y <= 0;
          r_pool_exec_x <= 0;
          r_pool_exec_y <= 0;
        end
        S_ACTIVE:
          if (in_ctrl.valid) begin
            if (r_pool_x == r_fea_size - 1) begin
              r_pool_x <= 0;
              if (r_pool_y == r_fea_size - 1)
                r_pool_y <= 0;
              else
                r_pool_y <= r_pool_y + 1;
              if (r_pool_exec_y == r_pool_size - 1)
                r_pool_exec_y <= 0;
              else
                r_pool_exec_y <= r_pool_exec_y + 1;
            end
            else
              r_pool_x <= r_pool_x + 1;
            if (r_pool_exec_x == r_pool_size - 1)
              r_pool_exec_x <= 0;
            else
              r_pool_exec_x <= r_pool_exec_x + 1;
          end
      endcase

//==========================================================
// pool control
//==========================================================

  assign buf_feat_en = r_buf_feat_en;

  always @(posedge clk)
    if (!xrst)
      r_buf_feat_en <= 0;
    else
      r_buf_feat_en <= in_ctrl.start;

  assign pool_ctrl.start = r_pool_ctrl[r_d_poolbuf].start;
  assign pool_ctrl.valid = r_pool_ctrl[r_d_poolbuf].valid;
  assign pool_ctrl.stop  = r_pool_ctrl[r_d_poolbuf].stop ;

  for (genvar i = 0; i < D_POOLBUF; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst)
          r_pool_ctrl[0] <= '{0, 0, 0};
        else begin
          r_pool_ctrl[0].start <= r_state == S_ACTIVE
                                    && r_pool_x == r_pool_size - 2
                                    && r_pool_y == r_pool_size - 1;
          r_pool_ctrl[0].valid <= r_state == S_ACTIVE
                                    && r_pool_exec_x == r_pool_size - 1
                                    && r_pool_exec_y == r_pool_size - 1;
          r_pool_ctrl[0].stop  <= r_state == S_ACTIVE
                                    && r_pool_x == r_fea_size - 1
                                    && r_pool_y == r_fea_size - 1;
        end
    else
      always @(posedge clk)
        if (!xrst)
          r_pool_ctrl[0] <= '{0, 0, 0};
        else begin
          r_pool_ctrl[i].start <= r_pool_ctrl[i-1].start;
          r_pool_ctrl[i].valid <= r_pool_ctrl[i-1].valid;
          r_pool_ctrl[i].stop  <= r_pool_ctrl[i-1].stop;
        end

//==========================================================
// output control
//==========================================================

  assign out_ctrl.start = r_out_ctrl[D_POOL-1].start;
  assign out_ctrl.valid = r_out_ctrl[D_POOL-1].valid;
  assign out_ctrl.stop  = r_out_ctrl[D_POOL-1].stop;
  assign pool_oe        = r_out_ctrl[D_POOL-2].valid;

  for (genvar i = 0; i < D_POOL; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst)
          r_out_ctrl[0] <= '{0, 0, 0};
        else begin
          r_out_ctrl[0].start <= pool_ctrl.start;
          r_out_ctrl[0].valid <= pool_ctrl.valid;
          r_out_ctrl[0].stop  <= pool_ctrl.stop;
        end
    else
      always @(posedge clk)
        if (!xrst)
          r_out_ctrl[i] <= '{0, 0, 0};
        else begin
          r_out_ctrl[i].start <= r_out_ctrl[i-1].start;
          r_out_ctrl[i].valid <= r_out_ctrl[i-1].valid;
          r_out_ctrl[i].stop  <= r_out_ctrl[i-1].stop;
        end

  assign buf_feat_en = r_buf_feat_en;

  always @(posedge clk)
    if (!xrst)
      r_buf_feat_en <= 0;
    else
      r_buf_feat_en <= in_ctrl.start;

endmodule
