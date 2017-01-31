set design gobou
set resultDir results
set reportDir reports
file mkdir $resultDir
file mkdir $reportDir
set_host_options -max_cores 4

sh date
source ./synopsys_dc.setup
set search_path [concat $search_path  ../rtl/common]
read_file -format sverilog [glob ../rtl/$design/*.sv]
# read_file -format sverilog ../rtl/$design.sv

source -echo -verbose const.tcl
current_design $design

link
#set dont_touch_network true
set_wire_load_mode enclosed

set_max_area 0
compile_ultra -gate_clock
#compile_ultra
#set_fix_multiple_port_nets -all -buffer_constants
# compile -power_effort high
ungroup -flatten -all
define_name_rules verilog -allowed "a-zA-Z0-9_" -remove_port_bus
change_names -rules verilog -hierarchy
check_design

write_file -format ddc -output $resultDir/$design.ddc
write_file -format svsim   -hierarchy -output $resultDir/$design.mapped.sv
write_file -format verilog -hierarchy -output $resultDir/$design.v
write_file -format vhdl    -hierarchy -output $resultDir/$design.vhd
write_sdf $resultDir/$design.sdf
write_sdc -nosplit -version 1.9 $resultDir/$design.sdc

report_qor > $reportDir/$design.mapped.qor.rpt
report_area -nosplit > $reportDir/$design.mapped.area.rpt
report_timing -transition_time -nets -attributes -nosplit -group clk \
   > $reportDir/$design.mapped.timing.rpt
report_power -verbose -analysis_effort high -hierarchy -levels 2 \
  > $reportDir/$design.mapped.power.rpt

quit
