`include "renkon.svh"

module ctrl_pool
  ( input               clk
  , input               xrst
  , input               in_begin
  , input               in_valid
  , input               in_end
  , input [LWIDTH-1:0]  w_fea_size
  , input [LWIDTH-1:0]  pool_size
  , output              buf_feat_en
  , output              out_begin
  , output              out_valid
  , output              out_end
  , output              pool_oe
  , output [LWIDTH-1:0] w_pool_size
  );

  wire pool_begin;
  wire pool_valid;
  wire pool_end;

  reg              r_state;
  reg [LWIDTH-1:0] r_fea_size;
  reg [LWIDTH-1:0] r_pool_size;
  reg [LWIDTH-1:0] r_d_poolbuf;
  reg [LWIDTH-1:0] r_pool_x;
  reg [LWIDTH-1:0] r_pool_y;
  reg [LWIDTH-1:0] r_pool_exec_x;
  reg [LWIDTH-1:0] r_pool_exec_y;
  reg              r_pool_begin_d [D_POOLBUF-1:0];
  reg              r_pool_valid_d [D_POOLBUF-1:0];
  reg              r_pool_end_d [D_POOLBUF-1:0];
  reg              r_out_begin_d [D_POOL-1:0];
  reg              r_out_valid_d [D_POOL-1:0];
  reg              r_out_end_d [D_POOL-1:0];
  reg              r_buf_feat_en;

//==========================================================
// main FSM
//==========================================================

  always @(posedge clk)
    if (!xrst)
      r_state <= S_WAIT;
    else
      case (r_state)
        S_WAIT:
          if (in_begin)
            r_state <= S_ACTIVE;
        S_ACTIVE:
          if (out_end)
            r_state <= S_WAIT;
      endcase

  assign w_pool_size = r_pool_size;

  always @(posedge clk)
    if (!xrst) begin
      r_fea_size  <= 0;
      r_pool_size <= 0;
      r_d_poolbuf <= 0;
    end
    else if (r_state == S_WAIT && in_begin) begin
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
          if (in_valid) begin
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
      r_buf_feat_en <= in_begin;

  assign pool_begin = r_pool_begin_d[r_d_poolbuf];
  assign pool_valid = r_pool_valid_d[r_d_poolbuf];
  assign pool_end   =   r_pool_end_d[r_d_poolbuf];

  <%- for n in ["begin", "valid", "end"] -%>
  <%-   for i in 0...$d_poolbuf -%>
  always @(posedge clk)
    <%- if i == 0 -%>
    if (!xrst)
      r_pool_<%=n%>_d[0] <= 0;
    else
      <%- case n -%>
      <%- when "begin" -%>
      r_pool_begin_d[0] <= (r_state == S_ACTIVE)
                            && r_pool_x == r_pool_size - 2
                            && r_pool_y == r_pool_size - 1;
      <%- when "valid" -%>
      r_pool_valid_d[0] <= (r_state == S_ACTIVE)
                            && r_pool_exec_x == r_pool_size - 1
                            && r_pool_exec_y == r_pool_size - 1;
      <%- when "end" -%>
      r_pool_end_d[0]   <= (r_state == S_ACTIVE)
                            && r_pool_x == r_fea_size - 1
                            && r_pool_y == r_fea_size - 1;
      <%- else -%>
      <%- end -%>
    <%- else -%>
    if (!xrst)
      r_pool_<%=n%>_d[<%=i%>] <= 0;
    else
      r_pool_<%=n%>_d[<%=i%>] <= r_pool_<%=n%>_d[<%=i-1%>];
    <%- end -%>
  <%-   end -%>
  <%- end -%>

//==========================================================
// output control
//==========================================================

  assign out_begin  = r_out_begin_d<%=$d_pool-1%>;
  assign out_valid  = r_out_valid_d<%=$d_pool-1%>;
  assign out_end    = r_out_end_d<%=$d_pool-1%>;

  assign pool_oe    = r_out_valid_d<%=$d_pool-2%>;

  for (genvar i = 0; i < D_POOL; i++)
    if (i == 0)
      always @(posedge clk)
        if (!xrst)
        else
    else
      always @(posedge clk)
        if (!xrst)
        else

  <%- for n in ["begin", "valid", "end"] -%>
  <%-   for i in 0...$d_pool -%>
  always @(posedge clk)
    <%- if i == 0 -%>
    if (!xrst)
      r_out_<%=n%>_d0 <= 0;
    else
      r_out_<%=n%>_d0 <= pool_<%=n%>;
    <%- else -%>
    if (!xrst)
      r_out_<%=n%>_d<%=i%> <= 0;
    else
      r_out_<%=n%>_d<%=i%> <= r_out_<%=n%>_d<%=i-1%>;
    <%- end -%>
  <%-   end -%>
  <%- end -%>

  assign buf_feat_en = r_buf_feat_en;

  always @(posedge clk)
    if (!xrst)
      r_buf_feat_en <= 0;
    else
      r_buf_feat_en <= in_begin;

endmodule
