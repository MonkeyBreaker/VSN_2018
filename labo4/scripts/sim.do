
#!/usr/bin/tclsh

# Main proc at the end #

#------------------------------------------------------------------------------
proc dut_compile { } {
  global Path_DUT
  puts "\nSystemVerilog DUT compilation :"

  vlog $Path_DUT/math_computer.sv
}

#------------------------------------------------------------------------------
proc tb_compile { } {
  global Path_TB
  global Path_DUT
  puts "\nSystemVerilog TB compilation :"

  vlog +incdir+$Path_DUT $Path_TB/math_computer_tb.sv
}

#------------------------------------------------------------------------------
proc sim_start { testcase errno} {

  vsim -t 1ns -novopt -Gtestcase=$testcase -GERRNO=$errno work.math_computer_tb
#  do wave.do
  add wave -r *
  wave refresh
  run -all
}

#------------------------------------------------------------------------------
proc do_all { testcase errno } {
  dut_compile
  tb_compile
  sim_start $testcase $errno
}

## MAIN #######################################################################

# Compile folder ----------------------------------------------------
if {[file exists work] == 0} {
  vlib work
}

puts -nonewline "  Path_VHDL => "
set Path_DUT     "../src_sv"
set Path_TB       "../src_tb"

global Path_DUT
global Path_TB

# start of sequence -------------------------------------------------

if {$argc>1} {
  if {[string compare $1 "all"] == 0} {
    do_all 0 $2
  } elseif {[string compare $1 "comp_vhdl"] == 0} {
    vhdl_compil
  } elseif {[string compare $1 "sim"] == 0} {
    sim_start 0 $2
  }

} else {
  do_all 0 0
}
