# Define your own block design
set debug 0
set display 1

create_bd_design "design_1"

if {$proj_name == "zcu102"} {
  create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.0 zynq_ultra_ps_e_0
  create_bd_cell -type ip -vlnv user.org:user:${ip_name}:1.0 ${ip_name}_0

  apply_bd_automation \
    -rule xilinx.com:bd_rule:zynq_ultra_ps_e \
    -config {apply_board_preset "1" } \
    [get_bd_cells zynq_ultra_ps_e_0]

  switch $ip_name {
    "kinpira_axi_lite" {
      apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
        -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD" Clk "Auto" } \
        [get_bd_intf_pins ${ip_name}_0/s_axi]
    }
    "kinpira_axi" {
      apply_bd_automation \
        -rule xilinx.com:bd_rule:axi4 \
        -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD" Clk "Auto" } \
        [get_bd_intf_pins ${ip_name}_0/s_axi_params]
      apply_bd_automation \
        -rule xilinx.com:bd_rule:axi4 \
        -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM1_FPD" Clk "Auto" } \
        [get_bd_intf_pins ${ip_name}_0/s_axi_gobou]
      apply_bd_automation \
        -rule xilinx.com:bd_rule:axi4 \
        -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM1_FPD" Clk "Auto" } \
        [get_bd_intf_pins ${ip_name}_0/s_axi_image]
      apply_bd_automation \
        -rule xilinx.com:bd_rule:axi4 \
        -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM1_FPD" Clk "Auto" } \
        [get_bd_intf_pins ${ip_name}_0/s_axi_renkon]
    }
    "kinpira_ddr" {
      set_property -dict [list CONFIG.PSU__USE__S_AXI_GP0 {1}] [get_bd_cells zynq_ultra_ps_e_0]
      set_property -dict [list CONFIG.PSU__USE__M_AXI_GP1 {0}] [get_bd_cells zynq_ultra_ps_e_0]

      apply_bd_automation \
        -rule xilinx.com:bd_rule:axi4 \
        -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD" Clk "Auto" } \
        [get_bd_intf_pins ${ip_name}_0/s_axi_params]
      apply_bd_automation \
        -rule xilinx.com:bd_rule:axi4 \
        -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD" Clk "Auto" } \
        [get_bd_intf_pins ${ip_name}_0/s_axi_renkon]
      apply_bd_automation \
        -rule xilinx.com:bd_rule:axi4 \
        -config {Master "/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD" Clk "Auto" } \
        [get_bd_intf_pins ${ip_name}_0/s_axi_gobou]
      apply_bd_automation \
        -rule xilinx.com:bd_rule:axi4 \
        -config {Master "/kinpira_ddr_0/m_axi_image" Clk "Auto" }  \
        [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HPC0_FPD]
    }
  }
} else {
  create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
  create_bd_cell -type ip -vlnv user.org:user:${ip_name}:1.0 ${ip_name}_0

  apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" } [get_bd_cells processing_system7_0]

  switch $ip_name {
    "kinpira_axi_lite" {
      apply_bd_automation \
        -rule xilinx.com:bd_rule:axi4 \
        -config {Master "/processing_system7_0/M_AXI_GP0" Clk "Auto" } \
        [get_bd_intf_pins ${ip_name}_0/s_axi]
    }
    "kinpira_axi" {
      set_property -dict [list CONFIG.PCW_USE_M_AXI_GP1 {1}] [get_bd_cells processing_system7_0]

      apply_bd_automation \
        -rule xilinx.com:bd_rule:axi4 \
        -config {Master "/processing_system7_0/M_AXI_GP0" Clk "Auto" } \
        [get_bd_intf_pins ${ip_name}_0/s_axi_params]
      apply_bd_automation \
        -rule xilinx.com:bd_rule:axi4 \
        -config {Master "/processing_system7_0/M_AXI_GP1" Clk "Auto" } \
        [get_bd_intf_pins ${ip_name}_0/s_axi_image]
      apply_bd_automation \
        -rule xilinx.com:bd_rule:axi4 \
        -config {Master "/processing_system7_0/M_AXI_GP1" Clk "Auto" } \
        [get_bd_intf_pins ${ip_name}_0/s_axi_renkon]
      apply_bd_automation \
        -rule xilinx.com:bd_rule:axi4 \
        -config {Master "/processing_system7_0/M_AXI_GP1" Clk "Auto" } \
        [get_bd_intf_pins ${ip_name}_0/s_axi_gobou]
    }
    "kinpira_ddr" {
      set_property -dict [list CONFIG.PCW_USE_S_AXI_HP0 {1}] [get_bd_cells processing_system7_0]

      apply_bd_automation \
        -rule xilinx.com:bd_rule:axi4 \
        -config {Master "/processing_system7_0/M_AXI_GP0" Clk "Auto" } \
        [get_bd_intf_pins ${ip_name}_0/s_axi_params]
      apply_bd_automation \
        -rule xilinx.com:bd_rule:axi4 \
        -config {Master "/processing_system7_0/M_AXI_GP0" Clk "Auto" } \
        [get_bd_intf_pins ${ip_name}_0/s_axi_renkon]
      apply_bd_automation \
        -rule xilinx.com:bd_rule:axi4 \
        -config {Master "/processing_system7_0/M_AXI_GP0" Clk "Auto" } \
        [get_bd_intf_pins ${ip_name}_0/s_axi_gobou]
      apply_bd_automation \
        -rule xilinx.com:bd_rule:axi4 \
        -config {Master "/kinpira_ddr_0/m_axi_image" Clk "Auto" }  \
        [get_bd_intf_pins processing_system7_0/S_AXI_HP0]
    }
  }
}

regenerate_bd_layout
save_bd_design

