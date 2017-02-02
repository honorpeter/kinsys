`include "renkon.svh"

int N_IN  = 16;
int N_OUT = 32;
int INSIZE  = 12;
int OUTSIZE = INSIZE - FSIZE + 1;
int IMG_OFFSET = 5000;
int NET_OFFSET = 0;

// string infile = "test_renkon_input.dat";
int num = 2;
int file = 4;
string indir  = "/home/work/takau/bhewtek/data/mnist/bpmap1";
string weight = "/home/work/takau/bhewtek/data/mnist/lenet/bwb_2";

module test_renkon;

  reg clk;
  reg [DWIDTH-1:0] mem_i [2**IMGSIZE-1:0];
  reg [DWIDTH-1:0] mem_n [2**NETSIZE-1:0][CORE-1:0];

  renkon dut(.*);

  // clock
  initial begin
    clk = 0;
    forever
      #(STEP/2) clk = ~clk;
  end

  //flow initial
  begin
    // $set_toggle_region(test_renkon.dut0);

    xrst = 0;
    clk = 0;
    xrst = 0;
    req = 0;
    img_we = 0;
    input_addr = 0;
    output_addr = 0;
    write_img = 0;
    net_we = 0;
    net_addr = 0;
    write_net = 0;
    total_out = 0;
    total_in = 0;
    img_size = 0;
    fil_size = 0;
    pool_size = 0;
    mem_clear;
    #(STEP);

    xrst        = 1;
    req         = 0;
    total_out   = N_OUT;
    total_in    = N_IN;
    img_size    = INSIZE;
    fil_size    = FSIZE;
    pool_size   = PSIZE;
    input_addr  = 0;
    output_addr = 5000;
    net_addr    = NET_OFFSET;

    read_image;

    read_network;

    // $toggle_start();
    #(STEP);

    req = 1;
    #(STEP);
    req = 0;

    while(!ack) #(STEP);
    #(STEP*10);
    // $toggle_stop();
    // $toggle_report(
    //   "renkon<%=num%>_<%=file%>.saif",
    //   1.0e-9,
    //   "test_renkon.dut0"
    // );

    // valid_memin;
    // valid_memw;
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
    begin // {{{
      for (int i = 0; i < N_IN; i++)
        $readmemb(
          $sformatf("%s/%d/data%d_%d.bin", indir, num, file, i),
          mem_i,
          (INSIZE**2)*(i),
          (INSIZE**2)*(i+1) - 1
        );
      #(STEP);

      img_we = 1;
      for (i=0; i<2**IMGSIZE; i=i+1) begin
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
    begin // {{{
      for (int i = 0; i < N_OUT/CORE; i++) begin
        for (int j = 0; j < CORE; j++) begin
          for (int k = 0; k < N_IN; k++) begin
            $readmemb(
              $sformatf("%s/data%d_%d.bin", weight, CORE*i+j, k),
              mem_n[j],
              (FSIZE**2) * (N_IN*i+k) + (i) + NET_OFFSET,
              (FSIZE**2) * (N_IN*i+k+1) + (i-1) + NET_OFFSET
            );
          end
          $readmemb(
            $sformatf("%s/data%d.bin", weight, CORE*i+j),
            mem_n[j],
            (FSIZE**2) * (N_IN*(i+1)) + (i) + NET_OFFSET,
            (FSIZE**2) * (N_IN*(i+1)) + (i) + NET_OFFSET
          );
        end
      end

      if (N_OUT % CORE != 0)
        for (int j = 0; j < CORE; j++)
          if ((CORE * (N_OUT/CORE) + j) < N_OUT) begin
            for (int k = 0; k < N_IN; k++) begin
              $readmemb(
                $sformatf("%s/data%d_%d.bin", weight, CORE*(N_OUT/CORE)+j, k),
                mem_n[j],
                (FSIZE**2) * (N_IN*(N_OUT/CORE)+k) + (N_OUT/CORE) + NET_OFFSET,
                (FSIZE**2) * (N_IN*(N_OUT/CORE)+k+1) + (N_OUT/CORE-1) + NET_OFFSET,
              );
            end
            $readmemb(
              $sformatf("%s/data%d_%d.bin", weight, CORE*(N_OUT/CORE)+j, k),
              mem_n[j],
              (FSIZE**2) * (N_IN*(N_OUT/CORE+1)) + (N_OUT/CORE) + NET_OFFSET,
              (FSIZE**2) * (N_IN*(N_OUT/CORE+1)) + (N_OUT/CORE) + NET_OFFSET,
            );
          else
            for (int k = 0; k < N_IN; k++) begin
              $readmemb(
                $sformatf("%s/null_w.bin", weight),
                mem_n[j],
                (FSIZE**2) * (N_IN*(N_OUT/CORE)+k) + (N_OUT/CORE) + NET_OFFSET,
                (FSIZE**2) * (N_IN*(N_OUT/CORE)+k+1) + (N_OUT/CORE-1) + NET_OFFSET,
              );
            end
            $readmemb(
              $sformatf("%s/null_b.bin", weight),
              mem_n[j],
              (FSIZE**2) * (N_IN*(N_OUT/CORE+1)) + (N_OUT/CORE) + NET_OFFSET,
              (FSIZE**2) * (N_IN*(N_OUT/CORE+1)) + (N_OUT/CORE) + NET_OFFSET,
            );
          end
        end
      end

      for (int n = 0; n < CORE; n++) begin
        net_we = n+1;
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
      fd = $fopen("test_renkon.dat", "w");
      out_size = N_OUT * OUTSIZE**2;

      for (int i = 0; i < out_size; i++) begin
        input_addr = i + 5000;
        #(STEP*2);

        $fdisplay(fd, "%0d", read_img);
      end

      input_addr = 0;
      #(STEP);

      $fclose(fd);
    end // }}}
  endtask

  always
  begin
    #(STEP/2-1);
    $display(
      "%5d: ", $time/STEP, // {{{
      "%d ", dut0.ctrl.ctrl_core.r_state,
      "%d ", dut0.ctrl.ctrl_core.r_state_weight,
      "%d ", dut0.ctrl.ctrl_core.r_count_out,
      "%d ", dut0.ctrl.ctrl_core.r_count_in,
      "|o: ",
      "%d ", ack,
      "%4d ", read_img,
      "|r: ",
      "%d ", dut0.mem_img_we,
      "%d ", dut0.mem_img_addr,
      "%4d ", dut0.read_img,
      "; ",
      "%d ", dut0.mem_net_we,
      "%d ", dut0.mem_net_addr,
      "%4d ", dut0.read_net0,
      "; ",
      "%4d ", dut0.pmap0,
      "; ",
      <%- 16.times do |i| -%>
      "%0d ", dut0.serial.mem_serial0.mem[<%=i%>],
      <%- end -%>
      "; ",
      <%- 16.times do |i| -%>
      "%0d ", dut0.serial.mem_serial7.mem[<%=i%>],
      <%- end -%>
      "|" // }}}
    );
    #(STEP/2+1);
  end

endmodule
