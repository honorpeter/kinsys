`include "renkon.svh"

// `define SAIF

int N_IN  = 20;
int N_OUT = 50;
int ISIZE = 12;
int OSIZE = (ISIZE - FSIZE + 1) / PSIZE;
int IMG_OFFSET = 0;
int OUT_OFFSET = 3000;
int NET_OFFSET = 0;

int label = 2;
int file  = 4;
string indir = "/home/work/takau/1.hw/bhewtek/data/mnist/bpmap1";
string wdir  = "/home/work/takau/1.hw/bhewtek/data/mnist/lenet/bwb_2";

module test_renkon;

  reg                      clk;
  reg                      xrst;
  reg                      req;
  reg                      img_we;
  reg        [IMGSIZE-1:0] input_addr;
  reg        [IMGSIZE-1:0] output_addr;
  reg signed [DWIDTH-1:0]  write_img;
  reg        [CORELOG:0]   net_we;
  reg        [NETSIZE-1:0] net_addr;
  reg signed [DWIDTH-1:0]  write_net;
  reg        [LWIDTH-1:0]  total_out;
  reg        [LWIDTH-1:0]  total_in;
  reg        [LWIDTH-1:0]  img_size;
  reg        [LWIDTH-1:0]  fil_size;
  reg        [LWIDTH-1:0]  pool_size;
  reg                      ack;
  reg signed [DWIDTH-1:0]  read_img;
  reg        [DWIDTH-1:0] mem_i [2**IMGSIZE-1:0];
  reg        [DWIDTH-1:0] mem_n [CORE-1:0][2**NETSIZE-1:0];

  int req_time = 2**30;
  int now_time = 0;

  renkon dut(.*);

  // clock
  initial begin
    clk = 0;
    forever
      #(STEP/2) clk = ~clk;
  end

  // flow
  initial begin
`ifdef SAIF
    $set_toggle_region(test_renkon.dut);
`endif

    xrst        = 0;
    #(STEP);

    xrst        = 1;
    req         = 0;
    total_out   = N_OUT;
    total_in    = N_IN;
    img_size    = ISIZE;
    fil_size    = FSIZE;
    pool_size   = PSIZE;
    input_addr  = IMG_OFFSET;
    output_addr = OUT_OFFSET;
    net_addr    = NET_OFFSET;

    mem_clear;
    read_network(wdir);

    read_image(indir, label, file);

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
      "test_renkon.dut"
    );
`endif

    write_output;
    $finish();
  end

  task mem_clear;
    begin // {{{
      for (int i = 0; i < 2**IMGSIZE; i++)
        mem_i[i] = 0;

      for (int n = 0; n < CORE; n++)
        for (int i = 0; i < 2**NETSIZE; i++)
          mem_n[n][i] = 0;
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
        input_addr = i;
        #(STEP);

        write_img = mem_i[i];
        #(STEP);
      end

      img_we = 0;
      input_addr = 0;
      write_img = 0;
      #(STEP);
    end // }}}
  endtask

  task read_network;
    input string wdir;
    begin // {{{
      // reading iterates for normal weight sets
      for (int i = 0; i < N_OUT/CORE; i++) begin
        for (int j = 0; j < CORE; j++) begin
          for (int k = 0; k < N_IN; k++) begin
            $readmemb(
              $sformatf("%s/data%0d_%0d.bin", wdir, CORE*i+j, k),
              mem_n[j],
              (FSIZE**2) * (N_IN*i+k) + (i) + NET_OFFSET,
              (FSIZE**2) * (N_IN*i+k+1) + (i-1) + NET_OFFSET
            );
          end
          $readmemb(
            $sformatf("%s/data%0d.bin", wdir, CORE*i+j),
            mem_n[j],
            (FSIZE**2) * (N_IN*(i+1)) + (i) + NET_OFFSET,
            (FSIZE**2) * (N_IN*(i+1)) + (i) + NET_OFFSET
          );
        end
      end

      // reading iterate for a boundary weight set (if exists)
      if (N_OUT % CORE != 0) begin
        for (int j = 0; j < CORE; j++) begin

          // put remainder weights to cores
          if ((CORE * (N_OUT/CORE) + j) < N_OUT) begin
            for (int k = 0; k < N_IN; k++) begin
              $readmemb(
                $sformatf("%s/data%0d_%0d.bin", wdir, CORE*(N_OUT/CORE)+j, k),
                mem_n[j],
                (FSIZE**2) * (N_IN*(N_OUT/CORE)+k) + (N_OUT/CORE) + NET_OFFSET,
                (FSIZE**2) * (N_IN*(N_OUT/CORE)+k+1) + (N_OUT/CORE-1) + NET_OFFSET
              );
            end
            $readmemb(
              $sformatf("%s/data%0d.bin", wdir, CORE*(N_OUT/CORE)+j),
              mem_n[j],
              (FSIZE**2) * (N_IN*(N_OUT/CORE+1)) + (N_OUT/CORE) + NET_OFFSET,
              (FSIZE**2) * (N_IN*(N_OUT/CORE+1)) + (N_OUT/CORE) + NET_OFFSET
            );
          end
          // put null (zero) values to unused cores
          else begin
            for (int k = 0; k < N_IN; k++) begin
              $readmemb(
                $sformatf("%s/null_w.bin", wdir),
                mem_n[j],
                (FSIZE**2) * (N_IN*(N_OUT/CORE)+k) + (N_OUT/CORE) + NET_OFFSET,
                (FSIZE**2) * (N_IN*(N_OUT/CORE)+k+1) + (N_OUT/CORE-1) + NET_OFFSET
              );
            end
            $readmemb(
              $sformatf("%s/null_b.bin", wdir),
              mem_n[j],
              (FSIZE**2) * (N_IN*(N_OUT/CORE+1)) + (N_OUT/CORE) + NET_OFFSET,
              (FSIZE**2) * (N_IN*(N_OUT/CORE+1)) + (N_OUT/CORE) + NET_OFFSET
            );
          end
        end
      end

      for (int n = 0; n < CORE; n++) begin
        net_we = n + 1;
        #(STEP);

        for (int i = 0; i < 2**NETSIZE; i++) begin
          net_addr = i;
          #(STEP);

          write_net = mem_n[n][i];
          #(STEP);
        end

        net_we    = 0;
        net_addr  = 0;
        write_net = 0;
        #(STEP);
      end

    end // }}}
  endtask

  task write_output;
    int fd;
    int out_size;
    begin // {{{
      fd = $fopen("../../data/renkon/output_renkon.dat", "w");
      out_size = N_OUT * OSIZE**2;

      for (int i = 0; i < out_size; i++) begin
        input_addr = i + OUT_OFFSET;
        #(STEP*2);

        $fdisplay(fd, "%0d", read_img);
      end

      input_addr = 0;
      #(STEP);

      $fclose(fd);
    end // }}}
  endtask

  initial begin
    forever begin
      #(STEP/2-1);
      now_time = $time/STEP;
      if (now_time >= req_time)
        $display(
          "%5d: ", now_time - req_time,
          "%d ", dut.ctrl.ctrl_core.r_state[0],
          "| ",
          "%d ", dut.mem_img_we,
          "%d ", dut.mem_img_addr,
          "%4d ", dut.read_img,
          "%4d ", dut.write_mem_img,
          "| ",
          "%1d ", dut.mem_net_we,
          "%d ", dut.mem_net_addr,
          "%4d ", dut.read_net[0],
          "%4d ", dut.write_net,
          "| ",
          "%2d ", dut.ctrl.ctrl_core.r_count_out,
          "%2d ", dut.ctrl.ctrl_core.r_count_in,
          "%2d ", dut.ctrl.ctrl_core.r_input_x,
          "%2d ", dut.ctrl.ctrl_core.r_input_y,
          "%2d ", dut.ctrl.ctrl_core.r_weight_x,
          "%2d ", dut.ctrl.ctrl_core.r_weight_y,
          "| ",
          "%3d ", dut.pe[0].core.pixel[0],
          "%3d ", dut.pe[0].core.fmap,
          "%3d ", dut.pe[0].core.bmap,
          "%3d ", dut.pe[0].core.amap,
          "%3d ", dut.pe[0].core.pmap,
          "| ",
          "%1d ", dut.pe[0].core.conv.mem_feat_rst,
          "%5d ", dut.pe[0].core.conv.result,
          "| ",
          "@%1d ", dut.pe[0].core.conv.mem_feat_we,
          "%3d ", dut.pe[0].core.conv.mem_feat_addr,
          "%3d ", dut.pe[0].core.conv.mem_feat_addr_d1,
          "%4d ", dut.pe[0].core.conv.read_feat,
          "%5d ", dut.pe[0].core.conv.write_feat,
          "| ",
          "%3d ", dut.pe[0].core.pool.pixel_in,
          "%1d ", dut.pe[0].core.pool.buf_feat_en,
          "%3d ", dut.pe[0].core.pool.pixel_feat[0],
          "%3d ", dut.pe[0].core.pool.pixel_feat[1],
          "%3d ", dut.pe[0].core.pool.pixel_feat[2],
          "%3d ", dut.pe[0].core.pool.pixel_feat[3],
          "|"
        );
      #(STEP/2+1);
    end
  end

endmodule
