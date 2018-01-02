`include "renkon.svh"
`include "ninjin.svh"

// `define SAIF
// `define NINJIN
`define DIRECT

int N_OUT = 32;
int N_IN  = 16;
int IMG_SIZE = 12;
// int N_OUT = 16;
// int N_IN  = 1;
// int IMG_SIZE = 28;

int CONV_STRID  = 1;
int CONV_PAD    = 1;
int FEA_SIZE    = (IMG_SIZE+2*CONV_PAD-CONV_KERN)/CONV_STRID + 1;
int POOL_STRID  = 2;
int POOL_PAD    = 0;
int OUT_SIZE    = (FEA_SIZE+2*POOL_PAD-POOL_KERN+POOL_STRID-1)/POOL_STRID + 1;
// int OUT_SIZE    = FEA_SIZE;

int IN_OFFSET   = 100;
int OUT_OFFSET  = 5000;
int NET_OFFSET  = 0;

int DO_BIAS = 1;
int DO_RELU = 1;
int DO_POOL = 1;

module test_renkon_top;

  reg                       clk;
  reg                       xrst;
  reg                       req;
  reg [RENKON_CORELOG-1:0]  net_sel;
  reg                       net_we;
  reg [RENKON_NETSIZE-1:0]  net_addr;
  reg signed [DWIDTH-1:0]   net_wdata;
  reg [MEMSIZE-1:0]         in_offset;
  reg [MEMSIZE-1:0]         out_offset;
  reg [RENKON_NETSIZE-1:0]  net_offset;

  reg [LWIDTH-1:0]          total_out;
  reg [LWIDTH-1:0]          total_in;
  reg [LWIDTH-1:0]          img_size;
  reg [LWIDTH-1:0]          conv_kern;
  reg [LWIDTH-1:0]          conv_strid;
  reg [LWIDTH-1:0]          conv_pad;
  reg                       bias_en;
  reg                       relu_en;
  reg                       pool_en;
  reg [LWIDTH-1:0]          pool_kern;
  reg [LWIDTH-1:0]          pool_strid;
  reg [LWIDTH-1:0]          pool_pad;

  wire                      ack;

  reg                       img_we;
  reg [MEMSIZE-1:0]         img_addr;
  reg signed [DWIDTH-1:0]   img_wdata;

  wire                      mem_img_we;
  wire [MEMSIZE-1:0]        mem_img_addr;
  wire signed [DWIDTH-1:0]  mem_img_wdata;
  wire signed [DWIDTH-1:0]  mem_img_rdata;

  wire                      renkon_img_we;
  wire [MEMSIZE-1:0]        renkon_img_addr;
  wire signed [DWIDTH-1:0]  renkon_img_wdata;
  wire signed [DWIDTH-1:0]  renkon_img_rdata;

  bit signed [DWIDTH-1:0]   mem_i [2**MEMSIZE-1:0];
  bit signed [DWIDTH-1:0]   mem_n [RENKON_CORE-1:0][2**RENKON_NETSIZE-1:0];

  int req_time = 2**30;
  int now_time = 0;

  assign mem_img_we     = ack ? img_we    : renkon_img_we;
  assign mem_img_addr   = ack ? img_addr  : renkon_img_addr;
  assign mem_img_wdata  = ack ? img_wdata : renkon_img_wdata;

  assign renkon_img_rdata = mem_img_rdata;

`ifdef NINJIN
/// {{{
  reg                     pre_req;
  reg [WORDSIZE-1:0]      pre_base;
  reg [LWIDTH-1:0]        read_len;
  reg [LWIDTH-1:0]        write_len;
  reg                     ddr_we;
  reg [WORDSIZE-1:0]      ddr_waddr;
  reg [BWIDTH-1:0]        ddr_wdata;
  reg [WORDSIZE-1:0]      ddr_raddr;
  wire                    pre_ack;
  wire                    ddr_req;
  wire                    ddr_mode;
  wire [WORDSIZE+LSB-1:0] ddr_base;
  wire [LWIDTH-1:0]       ddr_len;
  wire [BWIDTH-1:0]       ddr_rdata;
  wire [2-1:0]            probe_state;
  integer _ddr_base [1:0];
  integer _ddr_len [1:0];
  ninjin_ddr_buf mem_img(
    .mem_we     (mem_img_we),
    .mem_addr   (mem_img_addr),
    .mem_wdata  (mem_img_wdata),
    .mem_rdata  (mem_img_rdata),
    .*
  );
  always @(posedge ddr_req) begin
    #(STEP/2-1);
    if (ddr_mode == DDR_READ) begin
      _ddr_base[DDR_READ] = ddr_base;
      _ddr_len[DDR_READ]  = ddr_len;
      #(STEP);
      for (int i = 0; i < _ddr_len[DDR_READ]; i++) begin
        ddr_we    = 1;
        ddr_waddr = i + (_ddr_base[DDR_READ] >> LSB);
        ddr_wdata = {
          mem_i[2*(ddr_waddr-(IN_OFFSET >> RATELOG))+1],
          mem_i[2*(ddr_waddr-(IN_OFFSET >> RATELOG))]
        };
        #(STEP);
      end
      ddr_we    = 0;
      ddr_waddr = 0;
      ddr_wdata = 0;
      #(STEP);
    end
    #(STEP/2+1);
  end

  always @(posedge ddr_req) begin
    #(STEP/2-1);
    if (ddr_mode == DDR_WRITE) begin
      _ddr_base[DDR_WRITE] = ddr_base;
      _ddr_len[DDR_WRITE]  = ddr_len;
      #(STEP);
      for (int i = 0; i < _ddr_len[DDR_WRITE]; i++) begin
        ddr_raddr = i + (_ddr_base[DDR_WRITE] >> LSB);
        #(STEP);
      end
      ddr_raddr = 0;
      #(STEP);
    end
    #(STEP/2+1);
  end
// }}}
`else
  mem_sp #(DWIDTH, MEMSIZE) mem_img(
    .mem_we     (mem_img_we),
    .mem_addr   (mem_img_addr),
    .mem_wdata  (mem_img_wdata),
    .mem_rdata  (mem_img_rdata),
    .*
  );
`endif

  renkon_top dut(
    .img_we     (renkon_img_we),
    .img_addr   (renkon_img_addr),
    .img_wdata  (renkon_img_wdata),
    .img_rdata  (renkon_img_rdata),
    .*
  );

`ifdef DIRECT
`ifndef NINJIN
  always @*
    for (int i = 0; i < 2**MEMSIZE; i++)
      if (i < IN_OFFSET)
        mem_img.mem[i] = 0;
      else
        mem_img.mem[i] = mem_i[i-IN_OFFSET];
`endif

  // This statement is for direct assignment for generated modules
  for (genvar n = 0; n < RENKON_CORE; n++)
    always @*
      for (int i = 0; i < 2**RENKON_NETSIZE; i++)
        if (i < NET_OFFSET)
          dut.pe[n].mem_net.mem[i] = 0;
        else
          dut.pe[n].mem_net.mem[i] = mem_n[n][i-NET_OFFSET];
`endif

  // clock
  initial begin
    clk = 0;
    forever
      #(STEP/2) clk = ~clk;
  end

  // flow
  initial begin
`ifdef SAIF
    $set_toggle_region(test_renkon_top.dut);
`endif

    xrst = 0;
    #(STEP);

    xrst        = 1;
    req         = 0;
    net_sel     = 0;
    net_we      = 0;
    net_addr    = 0;
    net_wdata   = 0;
    in_offset   = IN_OFFSET;
    out_offset  = OUT_OFFSET;
    net_offset  = NET_OFFSET;
    total_out   = N_OUT;
    total_in    = N_IN;
    img_size    = IMG_SIZE;
    conv_kern   = CONV_KERN;
    conv_strid  = CONV_STRID;
    conv_pad    = CONV_PAD;
    bias_en     = DO_BIAS;
    relu_en     = DO_RELU;
    pool_en     = DO_POOL;
    pool_kern   = POOL_KERN;
    pool_strid  = POOL_STRID;
    pool_pad    = POOL_PAD;

    img_we    = 0;
    img_addr  = 0;
    img_wdata = 0;

    mem_clear;
`ifdef DIRECT
    read_input_direct;
    read_params_direct;
`else
    read_input;
    read_params;
`endif

`ifdef NINJIN
    pre_req   = 0;
    pre_base  = 0;
    read_len  = 0;
    write_len = 0;
    ddr_we    = 0;
    ddr_waddr = 0;
    ddr_wdata = 0;
    ddr_raddr = 0;
    #(STEP);

    pre_req   = 1;
    pre_base  = IN_OFFSET >> RATELOG;
    read_len  = N_IN * IMG_SIZE * IMG_SIZE;
    write_len = RENKON_CORE * OUT_SIZE * OUT_SIZE;
    #(STEP);
    pre_req = 0;
    #(STEP);

    while (!pre_ack) #(STEP);
    #(STEP);
`endif
`ifdef SAIF
    $toggle_start();
`endif
    #(STEP);

    req = 1;
    req_time = $time/STEP;
    #(STEP);
    req = 0;

    while(!ack) #(STEP);
    // #(STEP*20000);

    #(STEP*10);

    req_time = 2**30;

`ifdef SAIF
    $toggle_stop();
    $toggle_report(
      "renkon_top.saif",
      1.0e-9,
      "test_renkon_top.dut"
    );
`endif

    write_output;
    $finish();
  end

  task mem_clear;
    begin // {{{
      for (int i = 0; i < 2**MEMSIZE; i++)
        mem_i[i] = 0;

      for (int n = 0; n < RENKON_CORE; n++)
        for (int i = 0; i < 2**RENKON_NETSIZE; i++)
          mem_n[n][i] = 0;
    end // }}}
  endtask

  task read_input;
    int idx;
    int fd;
    int r;
    begin // {{{
      idx = 0;
      fd = $fopen("../../data/renkon/input_renkon_top.dat", "r");

      for (int m = 0; m < N_IN; m++)
        for (int i = 0; i < IMG_SIZE; i++)
          for (int j = 0; j < IMG_SIZE; j++) begin
            r = $fscanf(fd, "%x", mem_i[idx]);
            idx++;
          end

      $fclose(fd);
      #(STEP);

      for (int i = 0; i < 2**MEMSIZE; i++) begin
        img_we    = 1;
        img_addr  = i + IN_OFFSET;
        img_wdata = mem_i[i];
        #(STEP);
      end

      img_we    = 0;
      img_addr  = 0;
      img_wdata = 0;
      #(STEP);
    end // }}}
  endtask

  task read_input_direct;
    int idx;
    int fd;
    int r;
    begin // {{{
      idx = 0;
      fd = $fopen("../../data/renkon/input_renkon_top.dat", "r");

      for (int m = 0; m < N_IN; m++)
        for (int i = 0; i < IMG_SIZE; i++)
          for (int j = 0; j < IMG_SIZE; j++) begin
            r = $fscanf(fd, "%x", mem_i[idx]);
            idx++;
          end

      $fclose(fd);
    end // }}}
  endtask

  task read_params;
    int idx[RENKON_CORE-1:0];
    int wd, bd;
    int r;
    begin // {{{
      for (int dn = 0; dn < RENKON_CORE; dn++)
        idx[dn] = 0;
      wd = $fopen("../../data/renkon/weight_renkon_top.dat", "r");
      bd = $fopen("../../data/renkon/bias_renkon_top.dat", "r");

      // reading iterations for normal weight sets
      for (int n = 0; n < N_OUT/RENKON_CORE; n++)
        for (int dn = 0; dn < RENKON_CORE; dn++) begin
          for (int m = 0; m < N_IN; m++) begin
            for (int i = 0; i < CONV_KERN; i++)
              for (int j = 0; j < CONV_KERN; j++) begin
                r = $fscanf(wd, "%x", mem_n[dn][idx[dn]]);
                idx[dn]++;
              end
          end
          r = $fscanf(bd, "%x", mem_n[dn][idx[dn]]);
          idx[dn]++;
        end

      // reading iteration for a boundary weight set (if exists)
      if (N_OUT % RENKON_CORE != 0)
        for (int dn = 0; dn < RENKON_CORE; dn++) begin
          // put remainder weights to cores
          if ((RENKON_CORE * (N_OUT/RENKON_CORE) + dn) < N_OUT) begin
            for (int m = 0; m < N_IN; m++) begin
              for (int i = 0; i < CONV_KERN; i++)
                for (int j = 0; j < CONV_KERN; j++) begin
                  r = $fscanf(wd, "%x", mem_n[dn][idx[dn]]);
                  idx[dn]++;
                end
            end
            r = $fscanf(bd, "%x", mem_n[dn][idx[dn]]);
            idx[dn]++;
          end
          // put null (zero) values to unused cores
          else begin
            for (int m = 0; m < N_IN; m++) begin
              for (int i = 0; i < CONV_KERN; i++)
                for (int j = 0; j < CONV_KERN; j++) begin
                  mem_n[dn][idx[dn]] = 0;
                  idx[dn]++;
                end
            end
            mem_n[dn][idx[dn]] = 0;
            idx[dn]++;
          end
        end

      $fclose(wd);
      $fclose(bd);

      for (int n = 0; n < RENKON_CORE; n++) begin
        for (int i = 0; i < 2**RENKON_NETSIZE; i++) begin
          net_sel   = n;
          net_we    = 1;
          net_addr  = i;
          net_wdata = mem_n[n][i];
          #(STEP);
        end

        net_sel   = 0;
        net_we    = 0;
        net_addr  = 0;
        net_wdata = 0;
        #(STEP);
      end
    end // }}}
  endtask

  task read_params_direct;
    int idx[RENKON_CORE-1:0];
    int wd, bd;
    int r;
    begin // {{{
      for (int dn = 0; dn < RENKON_CORE; dn++)
        idx[dn] = 0;
      wd = $fopen("../../data/renkon/weight_renkon_top.dat", "r");
      bd = $fopen("../../data/renkon/bias_renkon_top.dat", "r");

      for (int dn = 0; dn < RENKON_CORE; dn++)
        idx[dn] = 0;
      wd = $fopen("../../data/renkon/weight_renkon_top.dat", "r");
      bd = $fopen("../../data/renkon/bias_renkon_top.dat", "r");

      // reading iterations for normal weight sets
      for (int n = 0; n < N_OUT/RENKON_CORE; n++)
        for (int dn = 0; dn < RENKON_CORE; dn++) begin
          for (int m = 0; m < N_IN; m++) begin
            for (int i = 0; i < CONV_KERN; i++)
              for (int j = 0; j < CONV_KERN; j++) begin
                r = $fscanf(wd, "%x", mem_n[dn][idx[dn]]);
                idx[dn]++;
              end
          end
          r = $fscanf(bd, "%x", mem_n[dn][idx[dn]]);
          idx[dn]++;
        end

      // reading iteration for a boundary weight set (if exists)
      if (N_OUT % RENKON_CORE != 0)
        for (int dn = 0; dn < RENKON_CORE; dn++) begin
          // put remainder weights to cores
          if ((RENKON_CORE * (N_OUT/RENKON_CORE) + dn) < N_OUT) begin
            for (int m = 0; m < N_IN; m++) begin
              for (int i = 0; i < CONV_KERN; i++)
                for (int j = 0; j < CONV_KERN; j++) begin
                  r = $fscanf(wd, "%x", mem_n[dn][idx[dn]]);
                  idx[dn]++;
                end
            end
            r = $fscanf(bd, "%x", mem_n[dn][idx[dn]]);
            idx[dn]++;
          end
          // put null (zero) values to unused cores
          else begin
            for (int m = 0; m < N_IN; m++) begin
              for (int i = 0; i < CONV_KERN; i++)
                for (int j = 0; j < CONV_KERN; j++) begin
                  mem_n[dn][idx[dn]] = 0;
                  idx[dn]++;
                end
            end
            mem_n[dn][idx[dn]] = 0;
            idx[dn]++;
          end
        end

      $fclose(wd);
      $fclose(bd);
    end // }}}
  endtask

  task write_output;
    int fd;
    int out_size;
    begin // {{{
      fd = $fopen("../../data/renkon/output_renkon_top.dat", "w");
      out_size = N_OUT * OUT_SIZE**2;

      for (int i = 0; i < out_size; i++) begin
        img_addr = i + OUT_OFFSET;
        #(STEP*2);
        `ifdef NINJIN
        `else
        assert (mem_img.mem[img_addr] == mem_img_rdata);
        `endif
        $fdisplay(fd, "%0d", mem_img_rdata);
      end

      img_addr = 0;
      #(STEP);

      $fclose(fd);
    end // }}}
  endtask

  // display
  initial begin
    forever begin // {{{
      #(STEP/2-1);
      now_time = $time/STEP;
      if (now_time >= req_time)
      begin
        $display(
          // "%5d: ", now_time - req_time,
          // "%d ",  req,
          // "%d ",  ack,
          "*%d ", dut.ctrl.ctrl_core.state$,
          // "*%d ", dut.ctrl.ctrl_conv.core_state$,
          // "*%d ", dut.ctrl.ctrl_conv.state$,
          "| ",
          "%2d ", dut.ctrl.ctrl_core.count_out$,
          "%2d ", dut.ctrl.ctrl_core.count_in$,
          "%2d ", dut.ctrl.ctrl_core.weight_x$,
          "%2d ", dut.ctrl.ctrl_core.weight_y$,
          ": ",
          "%2d ", dut.ctrl.ctrl_conv._conv_strid,
          "%2d ", dut.ctrl.ctrl_conv.conv_x$,
          "%2d ", dut.ctrl.ctrl_conv.conv_y$,
          "| ",
          "%1d ", mem_img_we,
          "%4d ", mem_img_addr,
          "%5d ", mem_img_wdata,
          "%5d ", mem_img_rdata,
          // "| ",
          // "%1d ", dut.pe[0].mem_net.mem_we,
          // "%4d ", dut.pe[0].mem_net.mem_addr,
          // "%5d ", dut.pe[0].mem_net.mem_wdata,
          // "%5d ", dut.pe[0].mem_net.mem_rdata,
          // "| ",
          // "%1d ", dut.pe[0].core.conv.mem_feat_rst,
          // "%1d ", dut.pe[0].core.conv.mem_feat_we,
          // "%4d ", dut.pe[0].core.conv.mem_feat_waddr,
          // "%5d ", dut.pe[0].core.conv.mem_feat_wdata,
          // "%4d ", dut.pe[0].core.conv.mem_feat_raddr,
          // "%5d ", dut.pe[0].core.conv.mem_feat_rdata,
          "| ",
          "%1b ", dut.ctrl.ctrl_core.buf_pix_req,
          "%1b ", dut.ctrl.ctrl_core.buf_pix_ack,
          "%1b ", dut.ctrl.ctrl_core.buf_pix_start,
          "%1b ", dut.ctrl.ctrl_core.buf_pix_valid,
          "%1b ", dut.ctrl.ctrl_core.buf_pix_ready,
          "%1b ", dut.ctrl.ctrl_core.buf_pix_stop,
          "| ",
          "%1b ", dut.ctrl.ctrl_pool.buf_feat_req,
          "%1b ", dut.ctrl.ctrl_pool.buf_feat_ack,
          "%1b ", dut.ctrl.ctrl_pool.buf_feat_start,
          "%1b ", dut.ctrl.ctrl_pool.buf_feat_valid,
          "%1b ", dut.ctrl.ctrl_pool.buf_feat_ready,
          "%1b ", dut.ctrl.ctrl_pool.buf_feat_stop,
          // "| ",
          // "%4d", dut.pe[0].core.pixel[0],
          // "%4d", dut.pe[0].core.pixel[1],
          // "%4d", dut.pe[0].core.pixel[2],
          // "; ",
          // "%4d", dut.pe[0].core.pixel[3],
          // "%4d", dut.pe[0].core.pixel[4],
          // "%4d", dut.pe[0].core.pixel[5],
          // "; ",
          // "%4d", dut.pe[0].core.pixel[6],
          // "%4d", dut.pe[0].core.pixel[7],
          // "%4d", dut.pe[0].core.pixel[8],
          "| ",
          // "%1d ", dut.ctrl.bus_core.delay,
          // "%1d ", dut.ctrl.bus_conv.delay,
          // "%1d ", dut.ctrl.bus_bias.delay,
          // "%1d ", dut.ctrl.bus_relu.delay,
          // "%1d ", dut.ctrl.bus_pool.delay,
          // ": ",
          "%5d ", dut.pe[0].core.fmap,
          "%5d ", dut.pe[0].core.bmap,
          "%4d ", dut.pe[0].core.amap,
          "%4d ", dut.pe[0].core.pmap,
          ": ",
          // "%4d ", dut.pe[0].core.pool.pixel_feat[0],
          // "%4d ", dut.pe[0].core.pool.pixel_feat[3],
          "%1d ", dut.pe[0].core.conv_oe,
          "%1d ", dut.pe[0].core.bias_oe,
          "%1d ", dut.pe[0].core.relu_oe,
          "%1d ", dut.pe[0].core.pool_oe,
          "| ",
          "%1b%1b%1b%1b ", dut.ctrl.ctrl_core.out_ctrl.start,
                           dut.ctrl.ctrl_core.out_ctrl.valid,
                           dut.ctrl.ctrl_core.out_ctrl.ready,
                           dut.ctrl.ctrl_core.out_ctrl.stop,
          "%1b%1b%1b%1b ", dut.ctrl.ctrl_conv.out_ctrl.start,
                           dut.ctrl.ctrl_conv.out_ctrl.valid,
                           dut.ctrl.ctrl_conv.out_ctrl.ready,
                           dut.ctrl.ctrl_conv.out_ctrl.stop,
          "%1b%1b%1b%1b ", dut.ctrl.ctrl_bias.out_ctrl.start,
                           dut.ctrl.ctrl_bias.out_ctrl.valid,
                           dut.ctrl.ctrl_bias.out_ctrl.ready,
                           dut.ctrl.ctrl_bias.out_ctrl.stop,
          "%1b%1b%1b%1b ", dut.ctrl.ctrl_relu.out_ctrl.start,
                           dut.ctrl.ctrl_relu.out_ctrl.valid,
                           dut.ctrl.ctrl_relu.out_ctrl.ready,
                           dut.ctrl.ctrl_relu.out_ctrl.stop,
          "%1b%1b%1b%1b ", dut.ctrl.ctrl_pool.out_ctrl.start,
                           dut.ctrl.ctrl_pool.out_ctrl.valid,
                           dut.ctrl.ctrl_pool.out_ctrl.ready,
                           dut.ctrl.ctrl_pool.out_ctrl.stop,
          "| ",
          "%2d ", dut.ctrl.ctrl_pool.ctrl_buf_feat.row_count,
          // "%2d ", dut.ctrl.ctrl_pool.ctrl_buf_feat.mem_count,
          "%2d ", dut.ctrl.ctrl_pool.ctrl_buf_feat.col_count,
          "%2d ", dut.ctrl.ctrl_pool.ctrl_buf_feat.str_x_count,
          "%2d ", dut.ctrl.ctrl_pool.ctrl_buf_feat.str_y_count,
          "| ",
          // "%1d ", dut.ctrl.ctrl_core.serial_we$,
          // "%1d ", dut.ctrl.ctrl_core.serial_re$,
          // "%3d ", dut.ctrl.ctrl_core.serial_addr$,
          // "%3d ", dut.ctrl.ctrl_core.serial_cnt$,
          // "%1d ", dut.ctrl.ctrl_core.serial_end$,
          // ": ",
          // "%1d ", dut.ctrl.ctrl_core.in_period$,
          "%1d ", dut.ctrl.ctrl_conv.wait_back$,
          // "| ",
          // "%1d ", dut.serial.serial_we,
          // "%1d ", dut.serial.serial_re,
          // "%4d ", dut.serial.serial_addr,
          // "%4d ", dut.serial.in_data[0],
          // "%4d ", dut.serial.out_data,
          "%1d ", dut.ctrl.ctrl_core.fea_size$,
          "|"
        );
      end
      #(STEP/2+1);
    end // }}}
  end

endmodule
