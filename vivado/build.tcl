# The following Tcl commands creates a new project named bft_test,
# adds files to the project, sets the fileset property,
# exports a tcl script named "bft.tcl" in the current
# working directory, creates a new project in "./my_bft" directory,
# prints the list of files in the new project (test_1.v and test_2.v),
# prints the "verilog_define" property
# value and then closes the newly created project:-

set design        gobou
set top_dir       [exec git rev-parse --show-toplevel]
set board         zedboard
set board_part    em.avnet.com:zed:part0:1.3
set device_parts  xc7z020clg484-1

create_project -force $design $top_dir/$board

set_property board_part         $board_part     [current_project]
set_property part               $device_parts   [current_project]
set_property default_lib        xil_defaultlib  [current_project]
set_property simulator_language Verilog         [current_project]
set_property target_language    Verilog         [current_project]

# Create fileset "sources_1"
if {[string equal [get_filesets -quiet sources_1] ""]} {
    create_fileset -srcset sources_1
}
# Create fileset "constrs_1"
if {[string equal [get_filesets -quiet constrs_1] ""]} {
    create_fileset -constrset constrs_1
}
# Create fileset "sim_1"
if {[string equal [get_filesets -quiet sim_1] ""]} {
    create_fileset -simset sim_1
}

add_files -norecurse -fileset sources_1 $top_dir/rtl/common
add_files -norecurse -fileset sources_1 $top_dir/rtl/$design

# Create run "synth_1" and set property
set synth_1_flow     "Vivado Synthesis 2016"
set synth_1_strategy "Vivado Synthesis Defaults"
if {[string equal [get_runs -quiet synth_1] ""]} {
    create_run -name synth_1 \
      -flow $synth_1_flow -strategy $synth_1_strategy \
      -constrset constrs_1
} else {
    set_property flow     $synth_1_flow     [get_runs synth_1]
    set_property strategy $synth_1_strategy [get_runs synth_1]
}
current_run -synthesis [get_runs synth_1]

# Create run "impl_1" and set property
set impl_1_flow      "Vivado Implementation 2016"
set impl_1_strategy  "Vivado Implementation Defaults"
if {[string equal [get_runs -quiet impl_1] ""]} {
    create_run -name impl_1 \
      -flow $impl_1_flow -strategy $impl_1_strategy \
      -constrset constrs_1 -parent_run synth_1
} else {
    set_property flow     $impl_1_flow      [get_runs impl_1]
    set_property strategy $impl_1_strategy  [get_runs impl_1]
}
current_run -implementation [get_runs impl_1]
