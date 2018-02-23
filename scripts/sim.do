
# Main proc at the end #

#------------------------------------------------------------------------------
proc compile_duv { } {
  global Path_DUV
  puts "\nVHDL DUV compilation :"

}

#------------------------------------------------------------------------------
proc compile_tb { } {
  global Path_TB
  global Path_DUV
  puts "\nVHDL TB compilation :"

  vcom -work common_lib  -2008 $Path_TB/common_lib/logger_pkg.vhd
  vcom -work common_lib  -2008 $Path_TB/common_lib/comparator_pkg.vhd
  vcom -work common_lib  -2008 $Path_TB/common_lib/complex_comparator_pkg.vhd
  vcom -work common_lib  -2008 $Path_TB/common_lib/common_ctx.vhd

  vcom -work project_lib -2008 $Path_TB/vector_comparator_pkg.vhd
  vcom -work project_lib -2008 $Path_TB/transactions_pkg.vhd
  vcom -work project_lib -2008 $Path_TB/transaction_comparator_pkg.vhd
  vcom -work project_lib -2008 $Path_TB/transaction_lazy_comparator_pkg.vhd
  vcom -work project_lib -2008 $Path_TB/project_logger_pkg.vhd
  vcom -work project_lib -2008 $Path_TB/project_ctx.vhd

  vcom -work project_lib -2008 $Path_TB/tester1.vhd
  vcom -work project_lib -2008 $Path_TB/tester2.vhd
  vcom -work project_lib -2008 $Path_TB/logger_example_tb.vhd
}

#------------------------------------------------------------------------------
proc sim_start {TESTCASE} {

  vsim -t 1ns -novopt -GTESTCASE=$TESTCASE project_lib.logger_example_tb
  run -all
}

#------------------------------------------------------------------------------
proc do_all {TESTCASE} {
  compile_duv
  compile_tb
  sim_start $TESTCASE
}

## MAIN #######################################################################

# Compile folder ----------------------------------------------------
if {[file exists work] == 0} {
  vlib work
}

puts -nonewline "  Path_VHDL => "
set Path_DUV    "../src"
set Path_TB     "../src_tb"

global Path_DUV
global Path_TB

# start of sequence -------------------------------------------------

if {$argc>1} {
  if {[string compare $1 "all"] == 0} {
    do_all 0
  } elseif {[string compare $1 "comp_duv"] == 0} {
    compile_duv
  } elseif {[string compare $1 "comp_tb"] == 0} {
    compile_tb
  } elseif {[string compare $1 "sim"] == 0} {
    sim_start 0
  }

} else {
  do_all 0
}
