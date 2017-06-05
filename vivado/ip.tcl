#!/usr/bin/env vivado -mode batch -source

set origin_dir .
set proj_name [lindex $argv 0]
set ip_name  [lindex $argv 1]

switch $proj_name {
  "zybo" {
    set part_name xc7z010clg400-1
  }
  "zedboard" {
    set part_name xc7z020clg484-1
  }
}

# Create project
create_project ip ./ip -part $part_name -force

# Set project properties
set obj [get_projects ip]
switch $proj_name {
  "zybo" {
    set_property "board_part" "digilentinc.com:zybo:part0:1.0" $obj
    set_property "default_lib" "xil_defaultlib" $obj
    set_property "ip_cache_permissions" "read write" $obj
    set_property "ip_output_repo" "$origin_dir/ip/ip.cache/ip" $obj
    set_property "sim.ip.auto_export_scripts" "1" $obj
    set_property "simulator_language" "Mixed" $obj
    set_property "xsim.array_display_limit" "64" $obj
    set_property "xsim.trace_limit" "65536" $obj
  }
  "zedboard" {
    set_property "board_part" "em.avnet.com:zed:part0:1.3" $obj
    set_property "default_lib" "xil_defaultlib" $obj
    set_property "ip_cache_permissions" "read write" $obj
    set_property "ip_output_repo" "$origin_dir/ip/ip.cache/ip" $obj
    set_property "sim.ip.auto_export_scripts" "1" $obj
    set_property "simulator_language" "Mixed" $obj
    set_property "xsim.array_display_limit" "64" $obj
    set_property "xsim.trace_limit" "65536" $obj
  }
}

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set IP repository paths
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "[file normalize "$origin_dir/../dist"]" $obj

# Rebuild user ip_repo's index before adding any source files
update_ip_catalog -rebuild

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
set files [list \
 "[file normalize "$origin_dir/../dist/mem_sp.sv"]"\
 "[file normalize "$origin_dir/../dist/common.svh"]"\
 "[file normalize "$origin_dir/../dist/renkon.svh"]"\
 "[file normalize "$origin_dir/../dist/renkon_pool_max4.sv"]"\
 "[file normalize "$origin_dir/../dist/renkon_linebuf.sv"]"\
 "[file normalize "$origin_dir/../dist/renkon_conv_wreg.sv"]"\
 "[file normalize "$origin_dir/../dist/renkon_conv_tree25.sv"]"\
 "[file normalize "$origin_dir/../dist/renkon_accum.sv"]"\
 "[file normalize "$origin_dir/../dist/mem_dp.sv"]"\
 "[file normalize "$origin_dir/../dist/renkon_relu.sv"]"\
 "[file normalize "$origin_dir/../dist/renkon_pool.sv"]"\
 "[file normalize "$origin_dir/../dist/renkon_mux_output.sv"]"\
 "[file normalize "$origin_dir/../dist/ctrl_bus.svh"]"\
 "[file normalize "$origin_dir/../dist/renkon_ctrl_relu.sv"]"\
 "[file normalize "$origin_dir/../dist/renkon_ctrl_pool.sv"]"\
 "[file normalize "$origin_dir/../dist/renkon_ctrl_core.sv"]"\
 "[file normalize "$origin_dir/../dist/renkon_ctrl_conv.sv"]"\
 "[file normalize "$origin_dir/../dist/renkon_ctrl_bias.sv"]"\
 "[file normalize "$origin_dir/../dist/renkon_conv.sv"]"\
 "[file normalize "$origin_dir/../dist/renkon_bias.sv"]"\
 "[file normalize "$origin_dir/../dist/gobou.svh"]"\
 "[file normalize "$origin_dir/../dist/gobou_relu.sv"]"\
 "[file normalize "$origin_dir/../dist/gobou_bias.sv"]"\
 "[file normalize "$origin_dir/../dist/gobou_ctrl_relu.sv"]"\
 "[file normalize "$origin_dir/../dist/gobou_ctrl_core.sv"]"\
 "[file normalize "$origin_dir/../dist/gobou_ctrl_mac.sv"]"\
 "[file normalize "$origin_dir/../dist/gobou_ctrl_bias.sv"]"\
 "[file normalize "$origin_dir/../dist/gobou_mac.sv"]"\
 "[file normalize "$origin_dir/../dist/renkon_serial_mat.sv"]"\
 "[file normalize "$origin_dir/../dist/renkon_ctrl.sv"]"\
 "[file normalize "$origin_dir/../dist/renkon_core.sv"]"\
 "[file normalize "$origin_dir/../dist/gobou_core.sv"]"\
 "[file normalize "$origin_dir/../dist/gobou_serial_vec.sv"]"\
 "[file normalize "$origin_dir/../dist/gobou_ctrl.sv"]"\
 "[file normalize "$origin_dir/../dist/renkon_top.sv"]"\
 "[file normalize "$origin_dir/../dist/ninjin.svh"]"\
 "[file normalize "$origin_dir/../dist/ninjin_s_axi_params.sv"]"\
 "[file normalize "$origin_dir/../dist/ninjin_s_axi_image.sv"]"\
 "[file normalize "$origin_dir/../dist/ninjin_s_axi_renkon.sv"]"\
 "[file normalize "$origin_dir/../dist/ninjin_s_axi_gobou.sv"]"\
 "[file normalize "$origin_dir/../dist/gobou_top.sv"]"\
 "[file normalize "$origin_dir/../dist/kinpira_axi.sv"]"\
]
add_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset file properties for remote files
set file "$origin_dir/../dist/mem_sp.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/common.svh"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
# set_property "file_type" "Verilog Header" $file_obj
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/renkon.svh"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
# set_property "file_type" "Verilog Header" $file_obj
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/renkon_pool_max4.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/renkon_linebuf.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/renkon_conv_wreg.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/renkon_conv_tree25.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/renkon_accum.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/mem_dp.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/renkon_relu.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/renkon_pool.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/renkon_mux_output.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/ctrl_bus.svh"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
# set_property "file_type" "Verilog Header" $file_obj
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/renkon_ctrl_relu.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/renkon_ctrl_pool.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/renkon_ctrl_core.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/renkon_ctrl_conv.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/renkon_ctrl_bias.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/renkon_conv.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/renkon_bias.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/gobou.svh"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
# set_property "file_type" "Verilog Header" $file_obj
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/gobou_relu.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/gobou_bias.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/gobou_ctrl_relu.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/gobou_ctrl_core.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/gobou_ctrl_mac.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/gobou_ctrl_bias.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/gobou_mac.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/renkon_serial_mat.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/renkon_ctrl.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/renkon_core.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/gobou_core.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/gobou_serial_vec.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/gobou_ctrl.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/renkon_top.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/ninjin.svh"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
# set_property "file_type" "Verilog Header" $file_obj
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/ninjin_s_axi_params.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/ninjin_s_axi_image.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/ninjin_s_axi_renkon.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/ninjin_s_axi_gobou.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/gobou_top.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/kinpira_axi.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

# set file "$origin_dir/../dist/component.xml"
# set file [file normalize $file]
# set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
# set_property "file_type" "IP-XACT" $file_obj


# Set 'sources_1' fileset file properties for local files
# None

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property "top" ${ip_name} $obj

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Empty (no sources present)

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
set files [list \
 "[file normalize "$origin_dir/../dist/test_gobou_top.sv"]"\
 "[file normalize "$origin_dir/../dist/test_kinpira_axi.sv"]"\
 "[file normalize "$origin_dir/../dist/test_mem_dp.sv"]"\
 "[file normalize "$origin_dir/../dist/test_mem_sp.sv"]"\
 "[file normalize "$origin_dir/../dist/test_renkon_top.sv"]"\
]
add_files -norecurse -fileset $obj $files

# Set 'sim_1' fileset file properties for remote files
set file "$origin_dir/../dist/test_gobou_top.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/test_kinpira_axi.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/test_mem_dp.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/test_mem_sp.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj

set file "$origin_dir/../dist/test_renkon_top.sv"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj


# Set 'sim_1' fileset file properties for local files
# None

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property "top" "test_${ip_name}" $obj
set_property "transport_int_delay" "0" $obj
set_property "transport_path_delay" "0" $obj
set_property "xelab.nosort" "1" $obj
set_property "xelab.unifast" "" $obj

# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
  create_run -name synth_1 \
    -part $part_name \
    -flow {Vivado Synthesis 2016} \
    -strategy "Vivado Synthesis Defaults" \
    -constrset constrs_1
} else {
  set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
  set_property flow "Vivado Synthesis 2016" [get_runs synth_1]
}
set obj [get_runs synth_1]

# set the current synth run
current_run -synthesis [get_runs synth_1]

# Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {
  create_run -name impl_1 \
    -part $part_name \
    -flow {Vivado Implementation 2016} \
    -strategy "Vivado Implementation Defaults" \
    -constrset constrs_1 \
    -parent_run synth_1
} else {
  set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
  set_property flow "Vivado Implementation 2016" [get_runs impl_1]
}
set obj [get_runs impl_1]
set_property "steps.write_bitstream.args.readback_file" "0" $obj
set_property "steps.write_bitstream.args.verbose" "0" $obj

# set the current impl run
current_run -implementation [get_runs impl_1]

puts "INFO: Project created:ip"

ipx::package_project -root_dir $origin_dir/../dist -vendor user.org -library user -taxonomy /UserIP
set_property core_revision 1 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
set_property  ip_repo_paths  $origin_dir/../dist [current_project]
update_ip_catalog

puts "INFO: Project packaged:ip"
