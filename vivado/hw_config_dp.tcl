
startgroup
set_property -dict [list CONFIG.PSU__USE__VIDEO {1}] [get_bd_cells zynq_ultra_ps_e_0]
endgroup

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 util_ds_buf_0
endgroup

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 util_ds_buf_1
endgroup

set_property -dict [list CONFIG.C_BUF_TYPE {BUFG}] [get_bd_cells util_ds_buf_1]
connect_bd_net [get_bd_pins util_ds_buf_0/IBUF_OUT] [get_bd_pins util_ds_buf_1/BUFG_I]
connect_bd_net [get_bd_pins util_ds_buf_1/BUFG_O] [get_bd_pins zynq_ultra_ps_e_0/dp_video_in_clk]

startgroup
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 CLK_IN_D
connect_bd_intf_net [get_bd_intf_pins util_ds_buf_0/CLK_IN_D] [get_bd_intf_ports CLK_IN_D]
endgroup

set_property name PIXEL_CLK [get_bd_intf_ports CLK_IN_D]