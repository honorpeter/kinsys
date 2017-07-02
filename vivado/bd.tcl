# Define your own block design

create_bd_design "design_1"

if {$proj_name == "zcu102"} {
  create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:2.0 zynq_ultra_ps_e_0
  create_bd_cell -type ip -vlnv user.org:user:${ip_name}:1.0 ${ip_name}_0

  apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells zynq_ultra_ps_e_0]

  switch $ip_name {
    "kinpira_axi_lite" {
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD" Clk "Auto" }  [get_bd_intf_pins ${ip_name}_0/s_axi]
    }
    "kinpira_axi" {
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD" Clk "Auto" }  [get_bd_intf_pins ${ip_name}_0/s_axi_params]
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM1_FPD" Clk "Auto" }  [get_bd_intf_pins ${ip_name}_0/s_axi_gobou]
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM1_FPD" Clk "Auto" }  [get_bd_intf_pins ${ip_name}_0/s_axi_image]
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM1_FPD" Clk "Auto" }  [get_bd_intf_pins ${ip_name}_0/s_axi_renkon]
    }
  }
} else {
  create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
  create_bd_cell -type ip -vlnv user.org:user:${ip_name}:1.0 ${ip_name}_0

  apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" } [get_bd_cells processing_system7_0]

  switch $ip_name {
    "kinpira_axi_lite" {
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" Clk "Auto" }  [get_bd_intf_pins ${ip_name}_0/s_axi]
    }
    "kinpira_axi" {
      set_property -dict [list CONFIG.PCW_USE_M_AXI_GP1 {1}] [get_bd_cells processing_system7_0]

      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" Clk "Auto" }  [get_bd_intf_pins ${ip_name}_0/s_axi_params]
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP1" Clk "Auto" }  [get_bd_intf_pins ${ip_name}_0/s_axi_image]
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP1" Clk "Auto" }  [get_bd_intf_pins ${ip_name}_0/s_axi_renkon]
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP1" Clk "Auto" }  [get_bd_intf_pins ${ip_name}_0/s_axi_gobou]
    }
    "kinpira_ddr" {
      set_property -dict [list CONFIG.PCW_USE_S_AXI_HP0 {1}] [get_bd_cells processing_system7_0]
      set_property -dict [list CONFIG.PCW_USE_M_AXI_GP1 {1}] [get_bd_cells processing_system7_0]

      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" Clk "Auto" }  [get_bd_intf_pins ${ip_name}_0/s_axi_params]
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/kinpira_ddr_0/m_axi_image" Clk "Auto" }  [get_bd_intf_pins processing_system7_0/S_AXI_HP0]
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP1" Clk "Auto" }  [get_bd_intf_pins ${ip_name}_0/s_axi_renkon]
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP1" Clk "Auto" }  [get_bd_intf_pins ${ip_name}_0/s_axi_gobou]
    }
  }
}

set_property HDL_ATTRIBUTE.DEBUG true [get_bd_intf_nets {kinpira_ddr_0_m_axi_image }]

apply_bd_automation -rule xilinx.com:bd_rule:debug \
  -dict [list \
    [get_bd_intf_nets kinpira_ddr_0_m_axi_image] \
    { AXI_R_ADDRESS "Data and Trigger" AXI_R_DATA "Data and Trigger" \
      AXI_W_ADDRESS "Data and Trigger" AXI_W_DATA "Data and Trigger" AXI_W_RESPONSE "Data and Trigger" \
      CLK_SRC "/processing_system7_0/FCLK_CLK0" SYSTEM_ILA "Auto" APC_EN "0" \
    }
  ]

regenerate_bd_layout
save_bd_design

