#!/usr/bin/env xsct

set origin_dir .
set proj_name [lindex $argv 0]
set app_name  [lindex $argv 1]

set app_dir $origin_dir/../app
set sdk_ws_dir $origin_dir/$proj_name/$proj_name.sdk

set hdf_filename [lindex [glob -dir $sdk_ws_dir *.hdf] 0]
set hdf_filename_only [lindex [split $hdf_filename /] end]
set top_module_name [lindex [split $hdf_filename_only .] 0]
set hw_project_name ${top_module_name}_hw_platform_0

setws $sdk_ws_dir
if {[file exists $app_dir/$app_name] != 0} {
  exec cp -rf {*}[glob $app_dir/$app_name/*] $sdk_ws_dir/$app_name/src
}
projects -build -type app -name $app_name

connect
targets -set -nocase -filter {name =~ "ARM*#0"}
rst -system

fpga $sdk_ws_dir/$hw_project_name/design_1_wrapper.bit
loadhw $sdk_ws_dir/$hw_project_name/system.hdf
source $sdk_ws_dir/$hw_project_name/ps7_init.tcl
ps7_init
ps7_post_config
dow $sdk_ws_dir/$app_name/Debug/$app_name.elf

con

