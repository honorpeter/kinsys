`include "renkon.svh"

module test_renkon_ctrl_core;

  reg                      clk;
  reg                      xrst;
  ctrl_bus                 in_ctrl();
  ctrl_reg                 in_ctrl$;
  reg                      req;
  reg                      img_we;
  reg [IMGSIZE-1:0]        in_offset;
  reg [IMGSIZE-1:0]        out_offset;
  reg [RENKON_NETSIZE-1:0] net_offset;
  reg signed [DWIDTH-1:0]  img_wdata;
  reg signed [DWIDTH-1:0]  out_wdata;
  reg [RENKON_CORELOG-1:0] net_sel;
  reg                      net_we;
  reg [RENKON_NETSIZE-1:0] net_addr;
  reg [LWIDTH-1:0]         total_out;
  reg [LWIDTH-1:0]         total_in;
  reg [LWIDTH-1:0]         img_size;
  reg [LWIDTH-1:0]         fil_size;
  ctrl_bus                 out_ctrl();
  ctrl_reg                 out_ctrl$;
  reg                      ack;
  reg [2-1:0]              core_state;
  reg                      mem_img_we;
  reg [IMGSIZE-1:0]        mem_img_addr;
  reg signed [DWIDTH-1:0]  mem_img_wdata;
  reg [RENKON_CORE-1:0]    mem_net_we;
  reg [RENKON_NETSIZE-1:0] mem_net_addr;
  reg                      buf_pix_en;
  reg                      first_input;
  reg                      last_input;
  reg                      wreg_we;
  reg                      breg_we;
  reg                      serial_we;
  reg [RENKON_CORELOG:0]   serial_re;
  reg [OUTSIZE-1:0]        serial_addr;
  reg [LWIDTH-1:0]         w_img_size;
  reg [LWIDTH-1:0]         w_fil_size;

  assign in_ctrl.start = in_ctrl$.start;
  assign in_ctrl.valid = in_ctrl$.valid;
  assign in_ctrl.stop  = in_ctrl$.stop;

  always @(posedge clk)
    if (!xrst)
      out_ctrl$  <= '{0, 0, 0};
    else begin
      out_ctrl$.start <= out_ctrl.start;
      out_ctrl$.valid <= out_ctrl.valid;
      out_ctrl$.stop  <= out_ctrl.stop;
    end

  renkon_ctrl_core dut(.*);

  // clock
  initial begin
    clk = 0;
    forever
      #(STEP/2) clk = ~clk;
  end

  //flow
  initial begin
    xrst = 0;
    #(STEP);

    xrst = 1;
    req = 0;
    in_ctrl$ = '{0, 0, 0};
    img_we = 0;
    in_offset = 0;
    out_offset = 0;
    img_wdata = 0;
    out_wdata = 0;
    net_we = 0;
    net_addr = 0;
    total_out = 0;
    total_in = 0;
    img_size = 0;
    fil_size = 0;
    #(STEP);

    req = 1;
    total_out = 50;
    total_in = 20;
    img_size = 12;
    fil_size = 5;
    in_offset = 0;
    out_offset = 3000;
    #(STEP);

    req = 0;

    repeat (7) begin
      #(STEP*4000);
      in_ctrl$.start = 1;
      #(STEP);

      in_ctrl$.start = 0;
      in_ctrl$.valid = 1;
      #(STEP*15);

      in_ctrl$.stop = 1;
      #(STEP);

      in_ctrl$.valid = 0;
      in_ctrl$.stop = 0;
    end

    while (!ack) #(STEP);
    #(STEP*5);

    $finish();
  end

  //display
  initial begin
    $display("clk: |");
    forever begin
      #(STEP/2-1);
      $display(
        "%5d: ", $time/STEP,
        "|i: ",
        "%d ", xrst,
        "%d",  in_ctrl$.start,
        "%d",  in_ctrl$.valid,
        "%d ", in_ctrl$.stop,
        "%d ", req,
        "%d ", img_we,
        "%d ", in_offset,
        "%d ", out_offset,
        "%d ", img_wdata,
        "%d ", out_wdata,
        "%d ", net_we,
        "%d ", net_addr,
        "%2d ", total_out,
        "%2d ", total_in,
        "%2d ", img_size,
        "%2d ", fil_size,
        "|o: ",
        "%d",  out_ctrl$.start,
        "%d",  out_ctrl$.valid,
        "%d ", out_ctrl$.stop,
        "%d ", ack,
        "%d ", core_state,
        "%d ", mem_img_we,
        "%d ", mem_img_addr,
        "%d ", mem_img_wdata,
        "%d ", mem_net_we,
        "%d ", mem_net_addr,
        "%d ", buf_pix_en,
        "%d ", first_input,
        "%d ", last_input,
        "%d ", wreg_we,
        "%d ", breg_we,
        "%d ", serial_we,
        "%d ", serial_re,
        "%d ", serial_addr,
        "%2d ", w_img_size,
        "%2d ", w_fil_size,
        "|r: ",
        "|"
      );
      #(STEP/2+1);
    end
  end

endmodule
