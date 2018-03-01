`include "renkon.svh"

int N_IN  = 20;
int N_OUT = 50;
int IMAGE = 12;
int FILTER = 5;
int RESULT = IMAGE - FILTER + 1;

module test_renkon_ctrl_conv;

  localparam S_CORE_WAIT    = 'd0;
  localparam S_CORE_NETWORK = 'd1;
  localparam S_CORE_INPUT   = 'd2;
  localparam S_CORE_OUTPUT  = 'd3;

  reg               clk;
  reg               xrst;
  ctrl_bus          in_ctrl();
  reg [2-1:0]       core_state;
  reg [LWIDTH-1:0]  w_img_size;
  reg [LWIDTH-1:0]  w_fil_size;
  reg               first_input;
  reg               last_input;
  ctrl_bus          out_ctrl();
  reg               mem_feat_we;
  reg               mem_feat_rst;
  reg [FEASIZE-1:0] mem_feat_addr;
  reg [FEASIZE-1:0] mem_feat_addr_d1;
  reg               conv_oe;
  reg [LWIDTH-1:0]  w_fea_size;

  reg [2-1:0]       core_state$   [D_PIXELBUF-1:0];
  reg               first_input$  [D_PIXELBUF-1:0];
  reg               last_input$   [D_PIXELBUF-1:0];
  ctrl_reg          in_ctrl$      [D_PIXELBUF-1:0];
  ctrl_reg          out_ctrl$;

  assign in_ctrl.start = in_ctrl$[D_PIXELBUF-1].start;
  assign in_ctrl.valid = in_ctrl$[D_PIXELBUF-1].valid;
  assign in_ctrl.stop  = in_ctrl$[D_PIXELBUF-1].stop;

  always @(posedge clk)
    if (!xrst) begin
      core_state  <= 0;
      first_input <= 0;
      last_input  <= 0;
      out_ctrl$  <= '{0, 0, 0};
    end
    else begin
      core_state       <= core_state$[D_PIXELBUF-1];
      first_input      <= first_input$[D_PIXELBUF-1];
      last_input       <= last_input$[D_PIXELBUF-1];
      out_ctrl$.start <= out_ctrl.start;
      out_ctrl$.valid <= out_ctrl.valid;
      out_ctrl$.stop  <= out_ctrl.stop;
    end

  for (genvar i = 1; i < D_PIXELBUF; i++)
    always @(posedge clk)
      if (!xrst) begin
        core_state$[i]  <= 0;
        first_input$[i] <= 0;
        last_input$[i]  <= 0;
        in_ctrl$[i]     <= '{0, 0, 0};
      end
      else begin
        core_state$[i]    <= core_state$[i-1];
        first_input$[i]   <= first_input$[i-1];
        last_input$[i]    <= last_input$[i-1];
        in_ctrl$[i].start <= in_ctrl$[i-1].start;
        in_ctrl$[i].valid <= in_ctrl$[i-1].valid;
        in_ctrl$[i].stop  <= in_ctrl$[i-1].stop;
      end

  renkon_ctrl_conv dut(.*);

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
    in_ctrl$[0] = '{0, 0, 0};
    core_state$[0] = 0;
    w_img_size = 0;
    w_fil_size = 0;
    first_input$[0] = 0;
    last_input$[0] = 0;
    #(STEP);

    w_img_size = IMAGE;
    w_fil_size = FILTER;
    input_send;
    while (!out_ctrl$.stop) #(STEP);

    #(STEP*5);
    $finish();
  end

  task input_send;
    begin
      for (int i = 0; i < (N_OUT/RENKON_CORE)+1; i++) begin
        // weight
        in_ctrl$[0].start = 1;
        core_state$[0] = S_CORE_NETWORK;
        #(STEP);
        in_ctrl$[0].start = 0;
        in_ctrl$[0].valid = 1;
        for (int j = 0; j < FILTER; j++)
          for (int k = 0; k < FILTER; k++)
            #(STEP);
        #(STEP);

        // input
        core_state$[0] = S_CORE_INPUT;
        #(STEP);
        for (int j = 0; j < N_IN; j++) begin
          if (j == 0)       first_input$[0] = 1;
          if (j == N_IN-1)  last_input$[0] = 1;

          for (int k = 0; k < IMAGE; k++)
            for (int l = 0; l < IMAGE; l++)
              #(STEP);

          if (j == 0)       first_input$[0] = 0;
          if (j == N_IN-1)  last_input$[0] = 0;
        end
        in_ctrl$[0].stop = 1;
        #(STEP);
        in_ctrl$[0].valid = 0;
        in_ctrl$[0].stop = 0;

        // output
        core_state$[0] = S_CORE_OUTPUT;
        #(STEP);
        for (int j = 0; j < RESULT; j++)
          for (int k = 0; k < RESULT; k++)
            #(STEP);
      end
      core_state$[0] = S_CORE_WAIT;
    end
  endtask

  //display
  initial begin
    $display("clk: |");
    forever begin
      #(STEP/2-1);
      $display(
        "%d: ", $time/STEP,
        "|i: ",
        "%d ", xrst,
        "%d", in_ctrl$[D_PIXELBUF-1].start,
        "%d", in_ctrl$[D_PIXELBUF-1].valid,
        "%d ", in_ctrl$[D_PIXELBUF-1].stop,
        "%d ", core_state,
        "%d ", w_img_size,
        "%d ", w_fil_size,
        "%d ", first_input,
        "%d ", last_input,
        "|o: ",
        "%d", out_ctrl$.start,
        "%d", out_ctrl$.valid,
        "%d ", out_ctrl$.stop,
        "%d ", mem_feat_we,
        "%d ", mem_feat_rst,
        "%d ", mem_feat_addr,
        "%d ", mem_feat_addr_d1,
        "%d ", conv_oe,
        "%d ", w_fea_size,
        "|r: ",
        "%d ", dut.conv_x$,
        "%d ", dut.conv_y$,
        "|"
      );
      #(STEP/2+1);
    end
  end

endmodule
