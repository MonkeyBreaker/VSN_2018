


proc check_sva { } {
  vlog  +incdir+../src_sv ../src_sv/math_computer.sv  ../src_tb/math_computer_assertions.sv ../src_tb/math_computer_wrapper.sv

  formal compile -d math_computer_wrapper -work work

  formal verify
}


check_sva
