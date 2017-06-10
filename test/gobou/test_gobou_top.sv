`include "gobou.svh"

int N_IN  = 800;
int N_OUT = 500;
int IMG_OFFSET = 0;
int OUT_OFFSET = 1000;
int NET_OFFSET = 0;

string weight = "/home/work/takau/1.hw/bhewtek/data/mnist/lenet/bwb_3";

module test_gobou_top;

  reg                     clk;
  reg                     xrst;
  reg                     req;
  reg [GOBOU_CORELOG-1:0] net_sel;
  reg                     net_we;
  reg [GOBOU_NETSIZE-1:0] net_addr;
  reg signed [DWIDTH-1:0] net_wdata;
  reg [IMGSIZE-1:0]       in_offset;
  reg [IMGSIZE-1:0]       out_offset;
  reg [GOBOU_NETSIZE-1:0] net_offset;
  reg [LWIDTH-1:0]        total_out;
  reg [LWIDTH-1:0]        total_in;
  reg                      ack;
  reg [DWIDTH-1:0] mem_i [2**IMGSIZE-1:0];
  reg [DWIDTH-1:0] mem_n [GOBOU_CORE-1:0][2**GOBOU_NETSIZE-1:0];

  reg                      img_we;
  reg [IMGSIZE-1:0]        img_addr;
  reg signed [DWIDTH-1:0]  img_wdata;

  wire                      mem_img_we;
  wire [IMGSIZE-1:0]        mem_img_addr;
  wire signed [DWIDTH-1:0]  mem_img_wdata;
  wire signed [DWIDTH-1:0]  mem_img_rdata;

  wire                      gobou_img_we;
  wire [IMGSIZE-1:0]        gobou_img_addr;
  wire signed [DWIDTH-1:0]  gobou_img_wdata;
  wire signed [DWIDTH-1:0]  gobou_img_rdata;

  int req_time = 2**30;
  int now_time = 0;

  assign mem_img_we     = ack ? img_we    : gobou_img_we;
  assign mem_img_addr   = ack ? img_addr  : gobou_img_addr;
  assign mem_img_wdata  = ack ? img_wdata : gobou_img_wdata;

  assign gobou_img_rdata = mem_img_rdata;

  mem_sp #(DWIDTH, IMGSIZE) mem_img(
    .mem_we     (mem_img_we),
    .mem_addr   (mem_img_addr),
    .mem_wdata  (mem_img_wdata),
    .mem_rdata  (mem_img_rdata),
    .*
  );

  gobou_top dut(
    .img_we     (gobou_img_we),
    .img_addr   (gobou_img_addr),
    .img_wdata  (gobou_img_wdata),
    .img_rdata  (gobou_img_rdata),
    .*
  );

  // clock
  initial begin
    clk = 0;
    forever
      #(STEP/2) clk = ~clk;
  end

  //flow
  initial begin
`ifdef SAIF
    $set_toggle_region(test_renkon_top.dut);
`endif

    xrst = 0;
    #(STEP);

    xrst = 1;
    req = 0;
    img_we = 0;
    in_offset = 0;
    out_offset = 0;
    net_offset = 0;
    img_wdata = 0;
    net_sel = 0;
    net_we = 0;
    net_addr = 0;
    net_wdata = 0;
    total_out = 0;
    total_in = 0;
    #(STEP);

    total_out = N_OUT;
    total_in  = N_IN;
    in_offset = IMG_OFFSET;
    out_offset = OUT_OFFSET;
    net_offset = NET_OFFSET;

    mem_clear;
    read_input;
    // read_weight;
    read_params;

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
      $sformatf("gobou%d_%d.saif", label, file),
      1.0e-9,
      "test_gobou_top.dut"
    );
`endif

    write_output;
    $finish();
  end

  task mem_clear;
    begin // {{{
      for (int i = 0; i < 2**IMGSIZE; i++)
        mem_i[i] = 0;

      for (int n = 0; n < GOBOU_CORE; n++)
        for (int i = 0; i < 2**GOBOU_NETSIZE; i++)
          mem_n[n][i] = 0;
    end // }}}
  endtask

  task read_input;
    int idx;
    int fd;
    int r;
    begin // {{{
      idx = 0;
      fd = $fopen("../../data/gobou/input_gobou_top.dat", "r");

      for (int m = 0; m < N_IN; m++) begin
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

  task read_params;
    int idx[GOBOU_CORE-1:0];
    int wd, bd;
    int r;
    begin // {{{
      for (int dn = 0; dn < GOBOU_CORE; dn++)
        idx[dn] = 0;
      wd = $fopen("../../data/gobou/weight_gobou_top.dat", "r");
      bd = $fopen("../../data/gobou/bias_gobou_top.dat", "r");

      // reading iterations for normal weight sets
      for (int n = 0; n < N_OUT/GOBOU_CORE; n++)
        for (int dn = 0; dn < GOBOU_CORE; dn++) begin
          for (int m = 0; m < N_IN; m++) begin
            r = $fscanf(wd, "%x", mem_n[dn][idx[dn]]);
            idx[dn]++;
          end
          r = $fscanf(bd, "%x", mem_n[dn][idx[dn]]);
          idx[dn]++;
        end

      // reading iteration for a boundary weight set (if exists)
      if (N_OUT % GOBOU_CORE != 0)
        for (int dn = 0; dn < GOBOU_CORE; dn++) begin
          // put remainder weights to cores
          if ((GOBOU_CORE * (N_OUT/GOBOU_CORE) + dn) < N_OUT) begin
            for (int m = 0; m < N_IN; m++) begin
              r = $fscanf(wd, "%x", mem_n[dn][idx[dn]]);
              idx[dn]++;
            end
            r = $fscanf(bd, "%x", mem_n[dn][idx[dn]]);
            idx[dn]++;
          end
          // put null (zero) values to unused cores
          else begin
            for (int m = 0; m < N_IN; m++) begin
              mem_n[dn][idx[dn]] = 0;
              idx[dn]++;
            end
            mem_n[dn][idx[dn]] = 0;
            idx[dn]++;
          end
        end

      $fclose(wd);
      $fclose(bd);

      for (int n = 0; n < GOBOU_CORE; n++) begin
        net_sel = n;
        net_we = 1;
        #(STEP);

        for (int i = 0; i < 2**GOBOU_NETSIZE; i++) begin
          net_addr = i;
          #(STEP);

          net_wdata = mem_n[n][i];
          #(STEP);
        end

        net_sel   = 0;
        net_we    = 0;
        net_addr  = 0;
        net_wdata = 0;
      end
    end // }}}
  endtask

  task read_weight;
    begin // {{{
      for (int i = 0; i < N_OUT/GOBOU_CORE; i++)
        for (int j = 0; j < GOBOU_CORE; j++)
          $readmemb(
            $sformatf("%s/data%0d.bin", weight, GOBOU_CORE*i+j),
            mem_n[j],
            (N_IN+1)*(i),
            (N_IN+1)*(i+1)-1
          );

      if (N_OUT % GOBOU_CORE != 0)
        for (int j = 0; j < GOBOU_CORE; j++)
          if ((GOBOU_CORE * (N_OUT/GOBOU_CORE) + j) < N_OUT)
            $readmemb(
              $sformatf("%s/data%0d.bin", weight, GOBOU_CORE*(N_OUT/GOBOU_CORE)+j),
              mem_n[j],
              (N_IN+1)*(N_OUT/GOBOU_CORE),
              (N_IN+1)*(N_OUT/GOBOU_CORE+1)-1
            );
          else
            $readmemb(
              $sformatf("%s/null_net.bin", weight),
              mem_n[j],
              (N_IN+1)*(N_OUT/GOBOU_CORE),
              (N_IN+1)*(N_OUT/GOBOU_CORE+1)-1
            );

      for (int n = 0; n < GOBOU_CORE; n++) begin
        net_sel = n;
        net_we = 1;
        #(STEP);

        for (int i = 0; i < 2**GOBOU_NETSIZE; i++) begin
          net_addr = i;
          #(STEP);
          net_wdata = mem_n[n][i];
          #(STEP);
        end

        net_sel   = 0;
        net_we    = 0;
        net_addr  = 0;
        net_wdata = 0;
      end
    end // }}}
  endtask

  task write_output;
    int fd;
    int out_size;
    begin // {{{
      fd = $fopen("../../data/gobou/output_gobou_top.dat", "w");
      out_size = N_OUT;

      for (int i = 0; i < out_size; i++) begin
        img_addr = i + OUT_OFFSET;
        #(STEP*2);
        assert (mem_img.mem[img_addr] == mem_img_rdata);
        $fdisplay(fd, "%0d", mem_img_rdata);
      end

      img_addr = 0;
      #(STEP);

      $fclose(fd);
      //
      // fd = $fopen("../../data/gobou/output_gobou_top.dat", "w");
      // out_size = N_OUT;
      // for (int i = 1000; i < 1000+out_size; i++)
      //   $fdisplay(fd, "%0d", mem_img.mem[i]);
      // $fclose(fd);
    end // }}}
  endtask

  // display
  initial begin
    forever begin
      #(STEP/2-1);
      now_time = $time/STEP;
      if (now_time >= req_time)
        $display(
          "%5d: ", now_time - req_time,
          "%d ", xrst,
          "%d ", req,
          "%d ", ack,
          "%d ", dut.ctrl.ctrl_core.r_state,
          "| ",
          "%d ", dut.ctrl.ctrl_core.out_ctrl.valid,
          "%d ", dut.ctrl.ctrl_mac.out_ctrl.valid,
          "%d ", dut.ctrl.ctrl_bias.out_ctrl.valid,
          "%d ", dut.ctrl.ctrl_relu.out_ctrl.valid,
          "| ",
          "%5d ", dut.pe[0].core.pixel,
          "%5d ", dut.pe[0].core.weight,
          "%5d ", dut.pe[0].core.mac.r_x,
          "%5d ", dut.pe[0].core.mac.r_w,
          "%5d ", dut.pe[0].core.mac.r_accum,
          "%5d ", dut.pe[0].core.mac.r_y,
          "%5d ", dut.pe[0].core.bias.r_bias,
          "| ",
          "%5d ", dut.pe[0].core.fvec,
          "%5d ", dut.pe[0].core.bvec,
          "%5d ", dut.pe[0].core.avec,
          "| ",
          "%5d@ ", dut.pe[0].core.fvec,
          "%5d@ ", dut.pe[1].core.fvec,
          "%5d@ ", dut.pe[2].core.fvec,
          "%5d@ ", dut.pe[3].core.fvec,
          "| ",
          "%5d@ ", dut.pe[0].core.avec,
          "%5d@ ", dut.pe[1].core.avec,
          "%5d@ ", dut.pe[2].core.avec,
          "%5d@ ", dut.pe[3].core.avec,
          "|"
        );
      #(STEP/2+1);
    end
  end

endmodule
