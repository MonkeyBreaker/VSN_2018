`ifndef MATH_COMPUTER_ITF_SV
`define MATH_COMPUTER_ITF_SV

`include "math_computer_macros.sv"

interface math_computer_input_itf;
    logic[`DATASIZE-1:0] a;
    logic[`DATASIZE-1:0] b;
    logic[`DATASIZE-1:0] c;
    logic valid;
    logic ready;

    modport master (
        output a, b, c, valid,
        input  ready
    );

    modport slave (
        input  a, b, c, valid,
        output ready
    );

endinterface

interface math_computer_output_itf;
    logic[`DATASIZE-1:0] result;
    logic valid;
    logic ready;

    modport master (
        output result, valid,
        input  ready
    );

    modport slave (
        input  result, valid,
        output ready
    );

endinterface

`endif // MATH_COMPUTER_ITF_SV
