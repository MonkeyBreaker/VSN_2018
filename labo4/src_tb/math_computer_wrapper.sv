`include "math_computer_macros.sv"
`include "math_computer_itf.sv"

module math_computer_wrapper (
    input logic clk,
    input logic rst,
    math_computer_input_itf.slave input_port,
    math_computer_output_itf.master output_port
);

    math_computer dut(.*);

    bind dut math_computer_assertions binded(.*);

endmodule
