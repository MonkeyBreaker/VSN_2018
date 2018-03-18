
# !/usr/bin/tclsh

# Main proc at the end #

#------------------------------------------------------------------------------
proc compile_duv { } {
  global Path_DUV
  puts "\nVHDL DUV compilation :"

  vcom -work project_lib $Path_DUV/alu.vhd
}

#------------------------------------------------------------------------------
proc compile_tb { } {
  global Path_TB
  global Path_DUV
  puts "\nVHDL TB compilation :"

  vcom -work common_lib  -2008 ../../labo1/src_tb/common_lib/logger_pkg.vhd
  vcom -work common_lib  -2008 ../../labo1/src_tb/common_lib/comparator_pkg.vhd
  vcom -work common_lib  -2008 ../../labo1/src_tb/common_lib/complex_comparator_pkg.vhd
  vcom -work common_lib  -2008 ../../labo1/src_tb/common_lib/common_ctx.vhd

  vcom -work project_lib -2008 ../../labo1/src_tb/project_logger_pkg.vhd
  vcom -work project_lib -2008 $Path_TB/project_ctx.vhd
  vcom -work project_lib -2008 $Path_TB/alu_tb.vhd
}

#------------------------------------------------------------------------------
proc sim_start {TESTCASE SIZE ERRNO LOG_FILE} {

  vsim -t 1ns -novopt -GLOG_FILE=$LOG_FILE -GSIZE=$SIZE -GERRNO=$ERRNO -GTESTCASE=$TESTCASE project_lib.alu_tb
#  do wave.do
  #add wave -r *_sti *_obs *_s
  add wave -noupdate -expand -group Stimuli *_sti
  add wave -noupdate -expand -group Observed *_obs
  add wave -noupdate -expand -group References *_ref
  add wave -noupdate -expand -group Simulation *_s
  wave refresh
  run -all
}


#------------------------------------------------------------------------------
proc compile_all {} {
  compile_duv
  compile_tb
}

## MAIN #######################################################################

# Compile folder ----------------------------------------------------
if {[file exists work] == 0} {
  vlib work
}

puts -nonewline "  Path_VHDL => "
set Path_DUV     "../src"
set Path_TB       "../src_tb"

global Path_DUV
global Path_TB

# start of sequence -------------------------------------------------

if {$argc>0} {
  if {[string compare $1 "all"] == 0} {
    do_all 0 $2 $3
  } elseif {[string compare $1 "comp_duv"] == 0} {
    compile_duv
  } elseif {[string compare $1 "comp_tb"] == 0} {
    compile_tb
  } elseif {[string compare $1 "sim"] == 0} {
    sim_start 0 $2
  }

} else {
  compile_all
  sim_start 0 8 0 "testcase1.txt"
  sim_start 1 8 0 "testcase2.txt"
  sim_start 2 8 0 "testcase3.txt"
  sim_start 2 8 21 "testcase4.txt"
}
