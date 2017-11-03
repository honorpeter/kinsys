set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

#clk
create_clock -name C0_SYS_CLK -period 3.33 [get_ports PIXEL_CLK_clk_p]
set_property PACKAGE_PIN AL8 [get_ports {PIXEL_CLK_clk_p}]
set_property IOSTANDARD LVDS [get_ports PIXEL_CLK_clk_*]
#set_property PACKAGE_PIN F12 [get_ports dp_aux_data_in]
#set_property IOSTANDARD LVCMOS33 [get_ports dp_aux_data_in]
#set_property PACKAGE_PIN D10 [get_ports dp_aux_data_out]
#set_property IOSTANDARD LVCMOS33 [get_ports {dp_aux_data_oe[0]}]
#set_property PACKAGE_PIN G11 [get_ports {dp_aux_data_oe[0]}]
#set_property PACKAGE_PIN H11 [get_ports HPD]
#set_property IOSTANDARD LVCMOS33 [get_ports dp_aux_data_out]
#set_property IOSTANDARD LVCMOS33 [get_ports HPD]


#set_property OFFCHIP_TERM NONE [get_ports dp_aux_data_out]

