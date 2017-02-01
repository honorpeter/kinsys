`include "renkon.svh"

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

  //flow
  initial
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
    img_size    = 12;
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
        mem_i[i] = {DWIDTH{1'b0}};

      for (int n = 0; n < CORE; n++)
        for (int i = 0; i < 2**NETSIZE; i++)
          mem_n[n][i] = {DWIDTH{1'b0}};
    end // }}}
  endtask

  task read_image;
    integer fd;
    begin // {{{
      <%- for i in 0...$n_f1 -%>
      $readmemb(
        "<%=input%>/<%=num%>/data<%=file%>_<%=i%>.bin",
        mem_i,
        <%=($pm1hei**2)*i%>,
        <%=($pm1hei**2)*(i+1)-1%>
      );
      <%- end -%>
      #(STEP);
      img_we = 1;
      fd = $fopen("asdf");
      for (i=0; i<2**IMGSIZE; i=i+1)
      begin
        $fdisplay(fd, "%d", mem_i[i]);
        input_addr = i;
        #(STEP);
        write_img = mem_i[i];
        #(STEP);
      end
      $fclose(fd);
      #(STEP);
      img_we = 0;
      input_addr = 0;
      write_img = 0;
    end // }}}
  endtask

  task read_network;
    begin // {{{
      <%- for i in 0...$n_f2/$core -%>
      <%-   for j in 0...$core -%>
      <%-     for k in 0...$n_f1 -%>
      $readmemb(
        "<%=weight%>/bwb_2/data<%=$core*i+j%>_<%=k%>.bin",
        mem_n<%=j%>,
        <%=($fsize**2)*($n_f1*i+k)+i%> + <%=net_offset%>,
        <%=($fsize**2)*($n_f1*i+k+1)+i-1%> + <%=net_offset%>
      );
      <%-     end -%>
      $readmemb(
        "<%=weight%>/bwb_2/data<%=$core*i+j%>.bin",
        mem_n<%=j%>,
        <%=($fsize**2)*($n_f1*(i+1))+i%> + <%=net_offset%>,
        <%=($fsize**2)*($n_f1*(i+1))+i%> + <%=net_offset%>
      );
      <%-   end -%>
      <%- end -%>
      <%- if $n_f2 % $core != 0 -%>
      <%-   for j in 0...$core -%>
      <%-     if $core*($n_f2/$core) + j < $n_f2 -%>
      <%-       for k in 0...$n_f1 -%>
      $readmemb(
        "<%=weight%>/bwb_2/data<%=$core*($n_f2/$core)+j%>_<%=k%>.bin",
        mem_n<%=j%>,
        <%=($fsize**2)*($n_f1*($n_f2/$core)+k)+($n_f2/$core)%> + <%=net_offset%>,
        <%=($fsize**2)*($n_f1*($n_f2/$core)+k+1)+($n_f2/$core)-1%> + <%=net_offset%>
      );
      <%-       end -%>
      $readmemb(
        "<%=weight%>/bwb_2/data<%=$core*($n_f2/$core)+j%>.bin",
        mem_n<%=j%>,
        <%=($fsize**2)*($n_f1*(($n_f2/$core)+1))+($n_f2/$core)%> + <%=net_offset%>,
        <%=($fsize**2)*($n_f1*(($n_f2/$core)+1))+($n_f2/$core)%> + <%=net_offset%>
      );
      <%-     else -%>
      <%-       for k in 0...$n_f1 -%>
      $readmemb(
        "<%=weight%>/bwb_2/null_w.bin",
        mem_n<%=j%>,
        <%=($fsize**2)*($n_f1*($n_f2/$core)+k)+($n_f2/$core)%> + <%=net_offset%>,
        <%=($fsize**2)*($n_f1*($n_f2/$core)+k+1)+($n_f2/$core)-1%> + <%=net_offset%>
      );
      <%-       end -%>
      $readmemb(
        "<%=weight%>/bwb_2/null_b.bin",
        mem_n<%=j%>,
        <%=($fsize**2)*($n_f1*(($n_f2/$core)+1))+($n_f2/$core)%> + <%=net_offset%>,
        <%=($fsize**2)*($n_f1*(($n_f2/$core)+1))+($n_f2/$core)%> + <%=net_offset%>
      );
      <%-     end -%>
      <%-   end -%>
      <%- end -%>

      <%- for n in 0...$core -%>
      net_we = <%=$core_log+1%>'d<%=n+1%>;
      #(STEP);
      for (i=0; i<2**NETSIZE; i=i+1)
      begin
        net_addr = i;
        #(STEP);
        write_net = mem_n<%=n%>[i];
        #(STEP);
      end
      net_we = <%=$core_log+1%>'d0;
      net_addr = 0;
      write_net = 0;
      <%- end -%>
    end // }}}
  endtask

  task write_output;
    integer fd;
    integer i;
    integer out_size;
    begin // {{{
      fd = $fopen("test_renkon.dat", "w");
      out_size = 800;
      for (i=0; i<out_size; i=i+1)
      begin
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
