#!/usr/bin/env vivado -mode batch -source

set origin_dir .
set proj_name [lindex $argv 0]
set ip_name  [lindex $argv 1]

switch $proj_name {
  "zybo" {
    set part_name   xc7z010clg400-1
    set board_name  digilentinc.com:zybo:part0:1.0
  }
  "zedboard" {
    set part_name   xc7z020clg484-1
    set board_name  em.avnet.com:zed:part0:1.3
  }
  "zcu102" {
    set part_name   xczu9eg-ffvb1156-2-i-es2
    set board_name  xilinx.com:zcu102:part0:2.2
  }
}

# Create project
create_project $proj_name ./$proj_name -part $part_name -force

# Set project properties
set obj [get_projects $proj_name]
set_property "board_part" $board_name $obj
set_property "default_lib" "xil_defaultlib" $obj
set_property "ip_cache_permissions" "read write" $obj
set_property "ip_output_repo" "$origin_dir/$proj_name/$proj_name.cache/ip" $obj
set_property "sim.ip.auto_export_scripts" "1" $obj
set_property "simulator_language" "Mixed" $obj
set_property "xsim.array_display_limit" "64" $obj
set_property "xsim.trace_limit" "65536" $obj

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set IP repository paths
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "[file normalize "$origin_dir/../dist"]" $obj

# Rebuild user ip_repo's index before adding any source files
update_ip_catalog -rebuild

source bd.tcl

make_wrapper -files [get_files $origin_dir/$proj_name/$proj_name.srcs/sources_1/bd/design_1/design_1.bd] -top

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
set files [list \
 "[file normalize "$origin_dir/../dist/ctrl_bus.svh"]"\
 "[file normalize "$origin_dir/../dist/common.svh"]"\
 "[file normalize "$origin_dir/../dist/ninjin.svh"]"\
 "[file normalize "$origin_dir/../dist/renkon.svh"]"\
 "[file normalize "$origin_dir/../dist/gobou.svh"]"\
 "[file normalize "$origin_dir/$proj_name/$proj_name.srcs/sources_1/bd/design_1/hdl/design_1_wrapper.v"]"\
]
add_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset file properties for remote files
set file "$origin_dir/../dist/ctrl_bus.svh"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj
# set_property "is_global_include" "1" $file_obj

set file "$origin_dir/../dist/common.svh"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj
# set_property "is_global_include" "1" $file_obj

set file "$origin_dir/../dist/ninjin.svh"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj
# set_property "is_global_include" "1" $file_obj

set file "$origin_dir/../dist/renkon.svh"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj
# set_property "is_global_include" "1" $file_obj

set file "$origin_dir/../dist/gobou.svh"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "SystemVerilog" $file_obj
# set_property "is_global_include" "1" $file_obj

set file "$origin_dir/$proj_name/$proj_name.srcs/sources_1/bd/design_1/design_1.bd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
if { ![get_property "is_locked" $file_obj] } {
  set_property "generate_synth_checkpoint" "0" $file_obj
}


# Set 'sources_1' fileset file properties for local files
# None

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property "top" "design_1_wrapper" $obj

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
# Empty (no sources present)

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property "top" "design_1_wrapper" $obj
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

puts "INFO: Project created:$proj_name"
