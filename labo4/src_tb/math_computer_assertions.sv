
`include "math_computer_macros.sv"
`include "math_computer_itf.sv"

module math_computer_assertions (
    input logic clk,
    input logic rst,
    math_computer_input_itf.master input_port,
    math_computer_output_itf.slave output_port
);


    assert_outvalid : assert property ( @(posedge clk) disable iff (rst==1)
        input_port.valid |=> output_port.valid);

    `define ASSERT_PROP(p) assert property ( @ ( posedge clk ) disable iff ( rst == 1) p );

    assert_outvalid1 : `ASSERT_PROP( (input_port.valid |=> output_port.valid) )

endmodule
