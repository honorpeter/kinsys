`include "renkon.svh"

// `define SAIF
`define DIRECT

int N_OUT = 50;
int N_IN  = 20;
int ISIZE = 12;
int OSIZE = (ISIZE - FSIZE + 1) / PSIZE;
int IMG_OFFSET = 0;
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
  reg [LWIDTH-1:0]          fil_size;
  reg [LWIDTH-1:0]          pool_size;
  reg                       ack;
  reg signed [DWIDTH-1:0]   img_rdata;
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

  mem_sp #(DWIDTH, IMGSIZE) mem_img(
    .mem_we     (mem_img_we),
    .mem_addr   (mem_img_addr),
    .mem_wdata  (mem_img_wdata),
    .mem_rdata  (mem_img_rdata),
    .*
  );

  renkon_top dut(
    .img_we     (renkon_img_we),
    .img_addr   (renkon_img_addr),
    .img_wdata  (renkon_img_wdata),
    .img_rdata  (renkon_img_rdata),
    .*
  );

  // This statement is for direct assignment for generated modules
  for (genvar n = 0; n < RENKON_CORE; n++)
    always @*
      for (int i = 0; i < 2**RENKON_NETSIZE; i++)
        dut.pe[n].mem_net.mem[i] = mem_n[n][i];

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

    xrst        = 0;
    #(STEP);

    xrst        = 1;
    req         = 0;
    in_offset   = IMG_OFFSET;
    out_offset  = OUT_OFFSET;
    net_offset  = NET_OFFSET;
    total_out   = N_OUT;
    total_in    = N_IN;
    img_size    = ISIZE;
    fil_size    = FSIZE;
    pool_size   = PSIZE;
    net_sel     = 0;
    net_we      = 0;
    net_addr    = 0;
    net_wdata   = 0;
    img_we    = 0;
    img_addr  = 0;
    img_wdata = 0;

    mem_clear;
    read_input_direct;
    read_params_direct;
    // read_network(wdir);
    // read_image(indir, label, file);

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
            r = $fscanf(fd, "%x", mem_img.mem[idx]);
            idx++;
          end

      $fclose(fd);
      #(STEP);
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
      // reading iterations for normal weight sets
      // for (int n = 0; n < N_OUT/RENKON_CORE; n++)
      //   for (int dn = 0; dn < RENKON_CORE; dn++) begin
      //     for (int m = 0; m < N_IN; m++) begin
      //       for (int i = 0; i < FSIZE; i++)
      //         for (int j = 0; j < FSIZE; j++) begin
      //           r = $fscanf(wd, "%x", dut.pe[dn].mem_net.mem[idx[dn]]);
      //           idx[dn]++;
      //         end
      //     end
      //     r = $fscanf(bd, "%x", dut.pe[dn].mem_net.mem[idx[dn]]);
      //     idx[dn]++;
      //   end
      //
      // // reading iteration for a boundary weight set (if exists)
      // if (N_OUT % RENKON_CORE != 0)
      //   for (int dn = 0; dn < RENKON_CORE; dn++) begin
      //     // put remainder weights to cores
      //     if ((RENKON_CORE * (N_OUT/RENKON_CORE) + dn) < N_OUT) begin
      //       for (int m = 0; m < N_IN; m++) begin
      //         for (int i = 0; i < FSIZE; i++)
      //           for (int j = 0; j < FSIZE; j++) begin
      //             r = $fscanf(wd, "%x", dut.pe[dn].mem_net.mem[idx[dn]]);
      //             idx[dn]++;
      //           end
      //       end
      //       r = $fscanf(bd, "%x", dut.pe[dn].mem_net.mem[idx[dn]]);
      //       idx[dn]++;
      //     end
      //     // put null (zero) values to unused cores
      //     else begin
      //       for (int m = 0; m < N_IN; m++) begin
      //         for (int i = 0; i < FSIZE; i++)
      //           for (int j = 0; j < FSIZE; j++) begin
      //             dut.pe[dn].mem_net.mem[idx[dn]] = 0;
      //             idx[dn]++;
      //           end
      //       end
      //       dut.pe[dn].mem_net.mem[idx[dn]] = 0;
      //       idx[dn]++;
      //     end
      //   end

      $fclose(wd);
      $fclose(bd);
      #(STEP);
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
        assert (mem_img.mem[img_addr] == mem_img_rdata);
        $fdisplay(fd, "%0d", mem_img_rdata);
      end

      img_addr = 0;
      #(STEP);

      $fclose(fd);
    end // }}}
  endtask

  initial begin
    forever begin // {{{
      #(STEP/2-1);
      now_time = $time/STEP;
      if (now_time >= req_time)
        $display(
          "%5d: ", now_time - req_time,
          "%d ", dut.ctrl.ctrl_core.r_state[0],
          "| ",
          "%2d ",  dut.ctrl.ctrl_core.r_count_out,
          "%2d ",  dut.ctrl.ctrl_core.r_count_in,
          "%2d  ", dut.ctrl.ctrl_core.r_input_x,
          "%2d  ", dut.ctrl.ctrl_core.r_input_y,
          "%2d  ", dut.ctrl.ctrl_core.r_weight_x,
          "%2d  ", dut.ctrl.ctrl_core.r_weight_y,
          "| ",
          "%1b",  dut.ctrl.ctrl_conv.in_ctrl.start,
          "%1b",  dut.ctrl.ctrl_conv.in_ctrl.valid,
          "%1b ", dut.ctrl.ctrl_conv.in_ctrl.stop,
          "%1b",  dut.ctrl.ctrl_conv.conv_ctrl.start,
          "%1b",  dut.ctrl.ctrl_conv.conv_ctrl.valid,
          "%1b ", dut.ctrl.ctrl_conv.conv_ctrl.stop,
          "%1b",  dut.ctrl.ctrl_conv.accum_ctrl.start,
          "%1b",  dut.ctrl.ctrl_conv.accum_ctrl.valid,
          "%1b ", dut.ctrl.ctrl_conv.accum_ctrl.stop,
          "%1b",  dut.ctrl.ctrl_conv.out_ctrl.start,
          "%1b",  dut.ctrl.ctrl_conv.out_ctrl.valid,
          "%1b ", dut.ctrl.ctrl_conv.out_ctrl.stop,
          "%1b",  dut.ctrl.ctrl_pool.pool_ctrl.start,
          "%1b",  dut.ctrl.ctrl_pool.pool_ctrl.valid,
          "%1b ", dut.ctrl.ctrl_pool.pool_ctrl.stop,
          "%1b",  dut.ctrl.ctrl_pool.out_ctrl.start,
          "%1b",  dut.ctrl.ctrl_pool.out_ctrl.valid,
          "%1b ", dut.ctrl.ctrl_pool.out_ctrl.stop,
          "| ",
          "%5d ", dut.pe[0].core.conv.pixel_in[0],
          "%5d ", dut.pe[0].core.conv.pixel_in[24],
          "%5d ", dut.pe[0].core.conv.weight[0],
          "%5d ", dut.pe[0].core.conv.weight[24],
          "%5d ", dut.pe[0].core.conv.result,
          "%5d ", dut.pe[0].core.conv.feat_rdata,
          "%5d ", dut.pe[0].core.conv.feat_wdata,
          "%5d ", dut.pe[0].core.conv.pixel_out,
          "| ",
          "%5d@ ", dut.pe[0].core.fmap,
          "%5d@ ", dut.pe[0].core.pmap,
          "|"
        );
      #(STEP/2+1);
    end // }}}
  end

  // initial begin
  //   forever begin // {{{
  //     #(STEP/2-1);
  //     now_time = $time/STEP;
  //     if (now_time >= req_time)
  //       $display(
  //         "%5d: ", now_time - req_time,
  //         "%d ", dut.ctrl.ctrl_core.r_state[0],
  //         "| ",
  //         "%1b",  dut.ctrl.ctrl_conv.in_ctrl.start,
  //         "%1b",  dut.ctrl.ctrl_conv.in_ctrl.valid,
  //         "%1b ", dut.ctrl.ctrl_conv.in_ctrl.stop,
  //         "%1b",  dut.ctrl.ctrl_conv.conv_ctrl.start,
  //         "%1b",  dut.ctrl.ctrl_conv.conv_ctrl.valid,
  //         "%1b ", dut.ctrl.ctrl_conv.conv_ctrl.stop,
  //         "%1b",  dut.ctrl.ctrl_conv.accum_ctrl.start,
  //         "%1b",  dut.ctrl.ctrl_conv.accum_ctrl.valid,
  //         "%1b ", dut.ctrl.ctrl_conv.accum_ctrl.stop,
  //         "%1b",  dut.ctrl.ctrl_conv.out_ctrl.start,
  //         "%1b",  dut.ctrl.ctrl_conv.out_ctrl.valid,
  //         "%1b ", dut.ctrl.ctrl_conv.out_ctrl.stop,
  //         "%1b",  dut.ctrl.ctrl_pool.pool_ctrl.start,
  //         "%1b",  dut.ctrl.ctrl_pool.pool_ctrl.valid,
  //         "%1b ", dut.ctrl.ctrl_pool.pool_ctrl.stop,
  //         "%1b",  dut.ctrl.ctrl_pool.out_ctrl.start,
  //         "%1b",  dut.ctrl.ctrl_pool.out_ctrl.valid,
  //         "%1b ", dut.ctrl.ctrl_pool.out_ctrl.stop,
  //         "| ",
  //         "%5d@ ", dut.pe[0].core.fmap,
  //         "%5d@ ", dut.pe[1].core.fmap,
  //         "%5d@ ", dut.pe[2].core.fmap,
  //         "%5d@ ", dut.pe[3].core.fmap,
  //         "%5d@ ", dut.pe[4].core.fmap,
  //         "%5d@ ", dut.pe[5].core.fmap,
  //         "%5d@ ", dut.pe[6].core.fmap,
  //         "%5d@ ", dut.pe[7].core.fmap,
  //         "| ",
  //         "%5d@ ", dut.pe[0].core.pmap,
  //         "%5d@ ", dut.pe[1].core.pmap,
  //         "%5d@ ", dut.pe[2].core.pmap,
  //         "%5d@ ", dut.pe[3].core.pmap,
  //         "%5d@ ", dut.pe[4].core.pmap,
  //         "%5d@ ", dut.pe[5].core.pmap,
  //         "%5d@ ", dut.pe[6].core.pmap,
  //         "%5d@ ", dut.pe[7].core.pmap,
  //         "|"
  //       );
  //     #(STEP/2+1);
  //   end // }}}
  // end

endmodule
