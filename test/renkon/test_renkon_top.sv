`include "renkon.svh"
`include "ninjin.svh"

// `define SAIF
// `define NINJIN
`define DIRECT

int N_OUT = 32;
int N_IN  = 16;
int ISIZE = 12;
// int N_OUT = 16;
// int N_IN  = 1;
// int ISIZE = 28;
int OSIZE = (ISIZE - FSIZE + 1) / PSIZE;
int IMG_OFFSET = 100;
int OUT_OFFSET = 5000;
int NET_OFFSET = 0;

int label = 2;
int file  = 4;
string indir = "/home/work/takau/1.hw/bhewtek/data/mnist/bpmap1";
string wdir  = "/home/work/takau/1.hw/bhewtek/data/mnist/lenet/bwb_2";

module test_renkon_top;

  reg                       clk;
  reg                       xrst;
  reg                       req;
  reg [RENKON_CORELOG-1:0]  net_sel;
  reg                       net_we;
  reg [RENKON_NETSIZE-1:0]  net_addr;
  reg signed [DWIDTH-1:0]   net_wdata;
  reg [IMGSIZE-1:0]         in_offset;
  reg [IMGSIZE-1:0]         out_offset;
  reg [RENKON_NETSIZE-1:0]  net_offset;
  reg [LWIDTH-1:0]          total_out;
  reg [LWIDTH-1:0]          total_in;
  reg [LWIDTH-1:0]          img_size;
  reg [LWIDTH-1:0]          conv_size;
  reg [LWIDTH-1:0]          pool_size;
  reg                       ack;
  reg signed [DWIDTH-1:0]   mem_i [2**IMGSIZE-1:0];
  reg signed [DWIDTH-1:0]   mem_n [RENKON_CORE-1:0][2**RENKON_NETSIZE-1:0];

  reg                      img_we;
  reg [IMGSIZE-1:0]        img_addr;
  reg signed [DWIDTH-1:0]  img_wdata;

  wire                      mem_img_we;
  wire [IMGSIZE-1:0]        mem_img_addr;
  wire signed [DWIDTH-1:0]  mem_img_wdata;
  wire signed [DWIDTH-1:0]  mem_img_rdata;

  wire                      renkon_img_we;
  wire [IMGSIZE-1:0]        renkon_img_addr;
  wire signed [DWIDTH-1:0]  renkon_img_wdata;
  wire signed [DWIDTH-1:0]  renkon_img_rdata;

  int req_time = 2**30;
  int now_time = 0;

  assign mem_img_we     = ack ? img_we    : renkon_img_we;
  assign mem_img_addr   = ack ? img_addr  : renkon_img_addr;
  assign mem_img_wdata  = ack ? img_wdata : renkon_img_wdata;

  assign renkon_img_rdata = mem_img_rdata;

`ifdef NINJIN
  reg                     pre_req;
  reg [MEMSIZE-1:0]       pre_base;
  reg [LWIDTH-1:0]        read_len;
  reg [LWIDTH-1:0]        write_len;
  reg                     ddr_we;
  reg [MEMSIZE-1:0]       ddr_waddr;
  reg [BWIDTH-1:0]        ddr_wdata;
  reg [MEMSIZE-1:0]       ddr_raddr;
  wire                      pre_ack;
  wire                      ddr_req;
  wire                      ddr_mode;
  wire [MEMSIZE+LSB-1:0]    ddr_base;
  wire [LWIDTH-1:0]         ddr_len;
  wire [BWIDTH-1:0]         ddr_rdata;
  wire [2-1:0]              probe_state;
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
          mem_i[2*(ddr_waddr-(IMG_OFFSET >> RATELOG))+1],
          mem_i[2*(ddr_waddr-(IMG_OFFSET >> RATELOG))]
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
`else
  mem_sp #(DWIDTH, IMGSIZE) mem_img(
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
    for (int i = 0; i < 2**IMGSIZE; i++)
      if (i < IMG_OFFSET)
        mem_img.mem[i] = 0;
      else
        mem_img.mem[i] = mem_i[i-IMG_OFFSET];
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
    in_offset   = IMG_OFFSET;
    out_offset  = OUT_OFFSET;
    net_offset  = NET_OFFSET;
    total_out   = N_OUT;
    total_in    = N_IN;
    img_size    = ISIZE;
    conv_size   = FSIZE;
    pool_size   = PSIZE;

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
    // read_network(wdir);
    // read_image(indir, label, file);

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
    pre_base  = IMG_OFFSET >> RATELOG;
    read_len  = N_IN * ISIZE * ISIZE;
    write_len = RENKON_CORE * ((ISIZE-FSIZE+1)/PSIZE) * ((ISIZE-FSIZE+1)/PSIZE);
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
    #(STEP*10);
    req_time = 2**30;

`ifdef SAIF
    $toggle_stop();
    $toggle_report(
      $sformatf("renkon%d_%d.saif", label, file),
      1.0e-9,
      "test_renkon_top.dut"
    );
`endif

    write_output;
    $finish();
  end

  task mem_clear;
    begin // {{{
      for (int i = 0; i < 2**IMGSIZE; i++)
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
        for (int i = 0; i < ISIZE; i++)
          for (int j = 0; j < ISIZE; j++) begin
            r = $fscanf(fd, "%x", mem_i[idx]);
            idx++;
          end

      $fclose(fd);
      #(STEP);

      for (int i = 0; i < 2**IMGSIZE; i++) begin
        img_we    = 1;
        img_addr  = i + IMG_OFFSET;
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
        for (int i = 0; i < ISIZE; i++)
          for (int j = 0; j < ISIZE; j++) begin
            r = $fscanf(fd, "%x", mem_i[idx]);
            idx++;
          end

      $fclose(fd);
    end // }}}
  endtask

  task read_image;
    input string indir;
    input int label;
    input int file;
    begin // {{{
      for (int i = 0; i < N_IN; i++)
        $readmemb(
          $sformatf("%s/%0d/data%0d_%0d.bin", indir, label, file, i),
          mem_i,
          (ISIZE**2)*(i),
          (ISIZE**2)*(i+1) - 1
        );
      #(STEP);

      img_we = 1;
      for (int i = 0; i < 2**IMGSIZE; i++) begin
        img_addr = i;
        #(STEP);

        img_wdata = mem_i[i];
        #(STEP);
      end

      img_we = 0;
      img_addr = 0;
      img_wdata = 0;
      #(STEP);
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
            for (int i = 0; i < FSIZE; i++)
              for (int j = 0; j < FSIZE; j++) begin
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
              for (int i = 0; i < FSIZE; i++)
                for (int j = 0; j < FSIZE; j++) begin
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
              for (int i = 0; i < FSIZE; i++)
                for (int j = 0; j < FSIZE; j++) begin
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
            for (int i = 0; i < FSIZE; i++)
              for (int j = 0; j < FSIZE; j++) begin
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
              for (int i = 0; i < FSIZE; i++)
                for (int j = 0; j < FSIZE; j++) begin
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
              for (int i = 0; i < FSIZE; i++)
                for (int j = 0; j < FSIZE; j++) begin
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

  task read_network;
    input string wdir;
    begin // {{{
      // reading iterations for normal weight sets
      for (int i = 0; i < N_OUT/RENKON_CORE; i++) begin
        for (int j = 0; j < RENKON_CORE; j++) begin
          for (int k = 0; k < N_IN; k++) begin
            $readmemb(
              $sformatf("%s/data%0d_%0d.bin", wdir, RENKON_CORE*i+j, k),
              mem_n[j],
              (FSIZE**2) * (N_IN*i+k) + (i) + NET_OFFSET,
              (FSIZE**2) * (N_IN*i+k+1) + (i-1) + NET_OFFSET
            );
          end
          $readmemb(
            $sformatf("%s/data%0d.bin", wdir, RENKON_CORE*i+j),
            mem_n[j],
            (FSIZE**2) * (N_IN*(i+1)) + (i) + NET_OFFSET,
            (FSIZE**2) * (N_IN*(i+1)) + (i) + NET_OFFSET
          );
        end
      end

      // reading iteration for a boundary weight set (if exists)
      if (N_OUT % RENKON_CORE != 0) begin
        for (int j = 0; j < RENKON_CORE; j++) begin

          // put remainder weights to cores
          if ((RENKON_CORE * (N_OUT/RENKON_CORE) + j) < N_OUT) begin
            for (int k = 0; k < N_IN; k++) begin
              $readmemb(
                $sformatf("%s/data%0d_%0d.bin", wdir, RENKON_CORE*(N_OUT/RENKON_CORE)+j, k),
                mem_n[j],
                (FSIZE**2) * (N_IN*(N_OUT/RENKON_CORE)+k) + (N_OUT/RENKON_CORE) + NET_OFFSET,
                (FSIZE**2) * (N_IN*(N_OUT/RENKON_CORE)+k+1) + (N_OUT/RENKON_CORE-1) + NET_OFFSET
              );
            end
            $readmemb(
              $sformatf("%s/data%0d.bin", wdir, RENKON_CORE*(N_OUT/RENKON_CORE)+j),
              mem_n[j],
              (FSIZE**2) * (N_IN*(N_OUT/RENKON_CORE+1)) + (N_OUT/RENKON_CORE) + NET_OFFSET,
              (FSIZE**2) * (N_IN*(N_OUT/RENKON_CORE+1)) + (N_OUT/RENKON_CORE) + NET_OFFSET
            );
          end
          // put null (zero) values to unused cores
          else begin
            for (int k = 0; k < N_IN; k++) begin
              $readmemb(
                $sformatf("%s/null_w.bin", wdir),
                mem_n[j],
                (FSIZE**2) * (N_IN*(N_OUT/RENKON_CORE)+k) + (N_OUT/RENKON_CORE) + NET_OFFSET,
                (FSIZE**2) * (N_IN*(N_OUT/RENKON_CORE)+k+1) + (N_OUT/RENKON_CORE-1) + NET_OFFSET
              );
            end
            $readmemb(
              $sformatf("%s/null_b.bin", wdir),
              mem_n[j],
              (FSIZE**2) * (N_IN*(N_OUT/RENKON_CORE+1)) + (N_OUT/RENKON_CORE) + NET_OFFSET,
              (FSIZE**2) * (N_IN*(N_OUT/RENKON_CORE+1)) + (N_OUT/RENKON_CORE) + NET_OFFSET
            );
          end
        end
      end

      for (int n = 0; n < RENKON_CORE; n++) begin
        net_sel = n;
        net_we  = 1;
        #(STEP);

        for (int i = 0; i < 2**RENKON_NETSIZE; i++) begin
          net_addr = i;
          #(STEP);

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

  task write_output;
    int fd;
    int out_size;
    begin // {{{
      fd = $fopen("../../data/renkon/output_renkon_top.dat", "w");
      out_size = N_OUT * OSIZE**2;

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
        $display(
          "%5d: ", now_time - req_time,
          "%d ", req,
          "%d ", ack,
          "*%d ", dut.ctrl.ctrl_core.state$[0],
          "| ",
          "%d ", mem_img_we,
          "%d ", mem_img_addr,
          "%d ", mem_img_wdata,
          "%d ", mem_img_rdata,
          `ifdef NINJIN
          "| ",
          "%x ", ddr_req,
          "%x ", ddr_mode,
          "%x ", ddr_base,
          "%x ", ddr_len,
          ": ",
          "*%x ", mem_img.state$[0],
          "*%x ", mem_img.ddr_which$,
          "%x ", mem_img.count_len$,
          "%x ", mem_img.count_buf$,
          `else
          // "| ",
          // "%x ", 1'b0,
          // "%x ", 1'b0,
          // "%x ", {MEMSIZE+LSB{1'b0}},
          // "%x ", {LWIDTH{1'b0}},
          // ": ",
          // "*%x ", 2'b0,
          // "%4x ", 4'b0,
          // "%4x ", 4'b0,
          "| ",
          "%1d ", dut.ctrl.ctrl_core.out_ctrl.valid,
          "%1d ", dut.ctrl.ctrl_conv.out_ctrl.valid,
          "%1d ", dut.ctrl.ctrl_bias.out_ctrl.valid,
          "%1d ", dut.ctrl.ctrl_relu.out_ctrl.valid,
          "%1d ", dut.ctrl.ctrl_pool.out_ctrl.valid,
          "| ",
          "%2d ",  dut.ctrl.ctrl_core.count_out$,
          "%2d ",  dut.ctrl.ctrl_core.count_in$,
          "%2d  ", dut.ctrl.ctrl_core.input_x$,
          "%2d  ", dut.ctrl.ctrl_core.input_y$,
          "%2d  ", dut.ctrl.ctrl_core.weight_x$,
          "%2d  ", dut.ctrl.ctrl_core.weight_y$,
        `endif
          "|"
        );
      #(STEP/2+1);
    end // }}}
  end

endmodule
