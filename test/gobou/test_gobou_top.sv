`include "gobou.svh"

int N_IN  = 800;
int N_OUT = 500;

string infile = "../../data/gobou/input_gobou_top.dat";
string weight = "/home/work/takau/1.hw/bhewtek/data/mnist/lenet/bwb_3";

module test_gobou_top;

  reg                     clk;
  reg                     xrst;
  reg                     req;
  reg                     img_we;
  reg [GOBOU_CORELOG-1:0] net_sel;
  reg                     net_we;
  reg [GOBOU_NETSIZE-1:0] net_addr;
  reg signed [DWIDTH-1:0] net_wdata;
  reg [IMGSIZE-1:0]       in_offset;
  reg [IMGSIZE-1:0]       out_offset;
  reg [GOBOU_NETSIZE-1:0] net_offset;
  reg [LWIDTH-1:0]        total_out;
  reg [LWIDTH-1:0]        total_in;
  reg signed [DWIDTH-1:0] img_wdata;
`ifdef DIST
  reg signed [DWIDTH-1:0] img_rdata;
`endif
  reg                      ack;
`ifdef DIST
  reg                      mem_img_we;
  reg [IMGSIZE-1:0]        mem_img_addr;
  reg signed [DWIDTH-1:0]  mem_img_wdata;
`else
  reg signed [DWIDTH-1:0]  img_rdata;
`endif

  reg [DWIDTH-1:0] mem_i [2**IMGSIZE-1:0];
  reg [DWIDTH-1:0] mem_n [GOBOU_CORE-1:0][2**GOBOU_NETSIZE-1:0];

  int req_time = 2**30;
  int now_time = 0;

  gobou_top dut(.*);

  // clock
  initial begin
    clk = 0;
    forever
      #(STEP/2) clk = ~clk;
  end

  //flow
  initial
  begin
    xrst = 0;
    #(STEP);

    xrst = 1;
    req = 0;
    img_we = 0;
    in_offset = 0;
    out_offset = 0;
    img_wdata = 0;
    net_we = 0;
    net_addr = 0;
    net_wdata = 0;
    total_out = 0;
    total_in = 0;
    #(STEP);

    total_out = N_OUT;
    total_in = N_IN;
    in_offset = 0;
    out_offset = 1000;
    read_input;
    // read_weight;
    read_params;
    #(STEP);

    req = 1;
    req_time = $time/STEP;
    #(STEP);
    req = 0;

    while(!ack) #(STEP);
    #(STEP*10);
    write_output;
    $finish();
  end

  task read_input;
    begin // {{{
      $readmemh(
        infile,
        mem_i,
        0,
        N_IN-1
      );

      img_we = 1;
      #(STEP);

      for (int i = 0; i < 2**IMGSIZE; i++) begin
        in_offset = i;
        #(STEP);
        img_wdata = mem_i[i];
        #(STEP);
      end
      #(STEP);

      img_we = 0;
      in_offset = 0;
      img_wdata = 0;
    end // }}}
  endtask

  task read_params;
    int idx[GOBOU_CORE-1:0];
    int wd, bd;
    int r;
    begin // {{{
      for (int dn = 0; dn < GOBOU_CORE; dn++)
        idx[dn] = 0;
      wd = $fopen("../../data/renkon/weight_renkon_top.dat", "r");
      bd = $fopen("../../data/renkon/bias_renkon_top.dat", "r");

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
    integer fd;
    integer out_size;
    begin // {{{
      fd = $fopen("../../data/gobou/output_gobou_top.dat", "w");
      out_size = N_OUT;
      for (int i = 1000; i < 1000+out_size; i++)
        $fdisplay(fd, "%0d", dut.mem_img.mem[i]);
      $fclose(fd);
    end // }}}
  endtask

  // display
  always
  begin
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
      );
    #(STEP/2+1);
  end

endmodule
