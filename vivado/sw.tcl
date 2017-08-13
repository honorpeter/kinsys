#!/usr/bin/env xsct

# ref: http://www.fpgadeveloper.com/2016/11/tcl-automation-tips-for-vivado-xilinx-sdk.html

set origin_dir .
set proj_name [lindex $argv 0]
set app_name  [lindex $argv 1]

set sdk_ws_dir $origin_dir/$proj_name/$proj_name.sdk
if {[file exists $sdk_ws_dir] == 0} {
  file mkdir $sdk_ws_dir
}
setws $sdk_ws_dir

set hdf_filename [lindex [glob -dir $sdk_ws_dir *.hdf] 0]
set hdf_filename_only [lindex [split $hdf_filename /] end]
set top_module_name [lindex [split $hdf_filename_only .] 0]
set hw_project_name ${top_module_name}_hw_platform_0
if {[file exists $sdk_ws_dir/$hw_project_name] == 0} {
  createhw -name $hw_project_name -hwspec $hdf_filename
}

proc get_processor_name {hw_project_name} {
  set periphs [getperipherals $hw_project_name]
  # For each line of the peripherals table
  foreach line [split $periphs "\n"] {
    set values [regexp -all -inline {\S+} $line]
    # If the last column is "PROCESSOR", then get the "IP INSTANCE" name (1st col)
    if {[lindex $values end] == "PROCESSOR"} {
      return [lindex $values 0]
    }
  }
  return ""
}

set app_dir $origin_dir/../app
if {[file exists $sdk_ws_dir/$app_name] == 0} {
  if {[file exists $app_dir/$app_name] != 0} {
    createapp -name $app_name \
      -app {Empty Application} \
      -proc [get_processor_name $hw_project_name] \
      -hwproject ${hw_project_name} \
      -os standalone
    importsources -name $app_name -path $app_dir/$app_name/src
  } else {
    createapp -name $app_name \
      -app {Hello World} \
      -proc [get_processor_name $hw_project_name] \
      -hwproject ${hw_project_name} \
      -os standalone
  }
}

configapp -app $app_name define-compiler-symbols $proj_name
projects -build

