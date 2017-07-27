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

if {$proj_name == "zcu102"} {

  connect

  targets -set -nocase -filter {name =~"PSU"}
  rst -system
  targets -set -nocase -filter {name =~"Cortex-A53*0"}
  rst -processor

  targets -set -nocase -filter {name =~"Cortex-A53*0"}
  loadhw $sdk_ws_dir/$hw_project_name/system.hdf
  targets -set -nocase -filter {name =~ "PS TAP"}
  fpga $sdk_ws_dir/$hw_project_name/design_1_wrapper.bit

  targets -set -nocase -filter {name =~"PSU"}
  source $sdk_ws_dir/$hw_project_name/psu_init.tcl
  psu_init
  psu_ps_pl_isolation_removal
  psu_ps_pl_reset_config
  psu_post_config
  catch {psu_protection}

  targets -set -nocase -filter {name =~"Cortex-A53*0"}
  dow $sdk_ws_dir/$app_name/Debug/$app_name.elf
  con

} else {

  connect

  targets -set -nocase -filter {name =~ "ARM*#0"}
  rst -system

  targets -set -nocase -filter {name =~ "ARM*#0"}
  loadhw $sdk_ws_dir/$hw_project_name/system.hdf
  targets -set -nocase -filter {name =~ "xc7z020"}
  fpga $sdk_ws_dir/$hw_project_name/design_1_wrapper.bit

  targets -set -nocase -filter {name =~ "ARM*#0"}
  source $sdk_ws_dir/$hw_project_name/ps7_init.tcl
  ps7_init
  ps7_post_config

  targets -set -nocase -filter {name =~ "ARM*#0"}
  dow $sdk_ws_dir/$app_name/Debug/$app_name.elf
  con

}
