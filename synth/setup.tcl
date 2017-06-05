append search_path {
  /home/default/techlib/sotb65/150701_REL/LIB/LE8U_V02.00.01/liberty/LP
}

set target_library {
  LE8UM_LP_Ptt_V0p55_T25.db
}

set link_library {
  LE8UM_LP_Ptt_V0p55_T25.db
}

set synthetic_library {
  dw_foundation.sldb
}
append link_library $synthetic_library

# set hdlin_check_no_latch true
# set compile_fix_multiple_port_nets true
# set hdlin_translate_off_skip_text true
# set verilogout_write_components true
# set verilogout_architecture_name "structural"
# set verilogout_no_tri true
# set hdlin_translate_off_skip_text true
# set bus_naming_style {%s[%d]}
