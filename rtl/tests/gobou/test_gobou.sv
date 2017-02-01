`include "gobou.svh"

int N_IN  = 800;
int N_OUT = 500;
string infile = "test_gobou_input.dat";
string weight = "/home/work/takau/bhewtek/data/mnist/lenet/bwb_3";

module test_gobou;

  reg                     clk;
  reg                     xrst;
  reg                     req;
  reg                     img_we;
  reg [IMGSIZE-1:0]       input_addr;
  reg [IMGSIZE-1:0]       output_addr;
  reg signed [DWIDTH-1:0] write_img;
  reg [CORELOG:0]         net_we;
  reg [NETSIZE-1:0]       net_addr;
  reg signed [DWIDTH-1:0] write_net;
  reg [LWIDTH-1:0]        total_out;
  reg [LWIDTH-1:0]        total_in;
`ifdef DIST
  reg signed [DWIDTH-1:0] read_img;
`endif
  reg                      ack;
`ifdef DIST
  reg                      mem_img_we;
  reg [IMGSIZE-1:0]        mem_img_addr;
  reg signed [DWIDTH-1:0]  write_mem_img;
`else
  reg signed [DWIDTH-1:0]  read_img;
`endif

  reg [DWIDTH-1:0] mem_i [2**IMGSIZE-1:0];
  reg [DWIDTH-1:0] mem_n [CORE-1:0][2**NETSIZE-1:0];

  int req_time = 2**30;
  int now_time = 0;

  gobou dut(.*);

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
    input_addr = 0;
    output_addr = 0;
    write_img = 0;
    net_we = 0;
    net_addr = 0;
    write_net = 0;
    total_out = 0;
    total_in = 0;
    #(STEP);

    total_out = N_OUT;
    total_in = N_IN;
    input_addr = 0;
    output_addr = 1000;
    read_input;
    read_weight;
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
        input_addr = i;
        #(STEP);
        write_img = mem_i[i];
        #(STEP);
      end
      #(STEP);

      img_we = 0;
      input_addr = 0;
      write_img = 0;
    end // }}}
  endtask

  task read_weight;
    begin // {{{
      for (int i = 0; i < N_OUT/CORE; i++)
        for (int j = 0; j < CORE; j++)
          $readmemb(
            $sformatf("%s/data%0d.bin", weight, CORE*i+j),
            mem_n[j],
            (N_IN+1)*(i),
            (N_IN+1)*(i+1)-1
          );

      if (N_OUT % CORE != 0)
        for (int j = 0; j < CORE; j++)
          if ((CORE * (N_OUT/CORE) + j) <  N_OUT)
            $readmemb(
              $sformatf("%s/data%0d.bin", weight, CORE*(N_OUT/CORE)+j),
              mem_n[j],
              (N_IN+1)*(N_OUT/CORE),
              (N_IN+1)*(N_OUT/CORE+1)-1
            );
          else
            $readmemb(
              $sformatf("%s/null_net.bin", weight),
              mem_n[j],
              (N_IN+1)*(N_OUT/CORE),
              (N_IN+1)*(N_OUT/CORE+1)-1
            );

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
      end
    end // }}}
  endtask

  task write_output;
    integer fd;
    integer out_size;
    begin // {{{
      fd = $fopen("test_gobou.dat", "w");
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
