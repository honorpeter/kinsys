sh date
set_host_options -max_cores 8

######################################################################
# Read Designs
######################################################################
set design gobou
set resultDir results
set reportDir reports
file mkdir $resultDir
file mkdir $reportDir

source setup.tcl
append search_path ../rtl/common
read_file -format sverilog [glob ../rtl/$design/*.sv]

### use for templated memory
### (or "// synopsys template" directive in template design sources)
# analyze -format sverilog [glob ../rtl/$design/*.sv]
# elaborate $design

list_designs
uniquify -force
current_design $design
link
check_design

######################################################################
# Compile
######################################################################
source -echo -verbose const.tcl
#set dont_touch_network true
set_wire_load_mode enclosed

set_max_area 0
# set_fix_multiple_port_nets -all -buffer_constants
ungroup -flatten -all
# compile_ultra -gate_clock
compile_ultra
# compile
define_name_rules verilog -allowed "a-zA-Z0-9_" -remove_port_bus
change_names -rules verilog -hierarchy

######################################################################
# Write Results
######################################################################
write_file -format ddc     -output $resultDir/$design.ddc
write_file -format verilog -hierarchy -output $resultDir/$design.v
write_sdf $resultDir/$design.sdf
write_sdc -nosplit -version 1.9 $resultDir/$design.sdc

######################################################################
# Report
######################################################################
report_qor > $reportDir/$design.mapped.qor.rpt
report_area -nosplit > $reportDir/$design.mapped.area.rpt
report_timing -transition_time -nets -attributes -nosplit -group clk \
   > $reportDir/$design.mapped.timing.rpt
report_power -verbose -analysis_effort high -hierarchy -levels 2 \
  > $reportDir/$design.mapped.power.rpt

quit
