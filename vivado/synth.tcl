source lib.tcl

set result_dir results
set report_dir reports
file mkdir $result_dir
file mkdir $report_dir

set top_dir [exec git rev-parse --show-toplevel]
set board   zedboard
set design  gobou
set xpr     $top_dir/$board/$design.xpr

open_project $xpr
update_compile_order -fileset sources_1
set_property top $design [current_fileset]

reset_run   synth_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1

open_run synth_1 -name netlist_1
source const.tcl

# Generate a timing and power reports and write to disk
report_timing_summary -delay_type max -report_unconstrained \
  -check_timing_verbose -max_paths 10 -input_pins \
  -file $report_dir/syn_timing.rpt
report_power -file $report_dir/syn_power.rpt
report_utilization -file $report_dir/syn_util.rpt
#write_hwdef -file $design.hwdef
reportCriticalPaths $report_dir/post_synth_critpath_report.csv
write_verilog -force $result_dir/${design}_synth_netlist.v
