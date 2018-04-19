/******************************************************************************
Project Math_computer

File : math_computer.sv
Description : This module implements a simple mathematic calculation.
              Its interfaces use ready-valid signals to communicate with the
              outside. It has 3 values, a, b ,c as input and result as an
              output.

Author : Y. Thoma
Team   : REDS institute

Date   : 13.04.2017

| Modifications |--------------------------------------------------------------
Ver    Date         Who    Description
1.0    13.04.2017   YTA    First version

******************************************************************************/
`include "math_computer_macros.sv"
`include "math_computer_itf.sv"


module math_computer(
    input logic clk,
    input logic rst,
    math_computer_input_itf.slave input_port,
    math_computer_output_itf.master output_port
);

    // signal interne
    logic[`DATASIZE:0] val;
    enum {s0, s1} state;

    // Processus synchrone
    always_ff @(posedge clk, posedge rst) begin
        if (rst==1) begin
            output_port.result <= 0;
            output_port.valid  <= 0;
            state <= s0;
        end
        else begin
            case (state)
            s0 : begin
                input_port.ready <= 1;
                if (input_port.valid && input_port.ready) begin
                    state <= s1;
                    input_port.ready <= 0;
                    val   <= input_port.a + input_port.b;
                end
            end
            s1 : begin
                output_port.result <= val;
                output_port.valid  <= 1;
                if (output_port.valid && output_port.ready) begin
                    output_port.valid  <= 0;
                    output_port.result <= 0;
                    state <= s0;
                end
            end
            endcase
        end
    end

endmodule
