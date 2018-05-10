
/* Génération de signaux de type bus avalon
*/

module avalon_assertions#(
        int AVALONMODE  = 0,
        int TESTCASE    = 0,
        int NBDATABYTES = 2,
        int NBADDRBITS  = 8,
        int WRITEDELAY  = 2,  // Delay for fixed delay write operation
        int READDELAY   = 1,   // Delay for fixed delay read operation
        int FIXEDDELAY  = 2)  // Delay for pipeline operation
(
    input logic clk,
    input logic rst,

    input logic[NBADDRBITS-1:0] address,
    input logic[NBDATABYTES:0] byteenable,
    input logic[2^NBDATABYTES-1:0] readdata,
    input logic[2^NBDATABYTES-1:0] writedata,
    input logic read,
    input logic write,
    input logic waitrequest,
    input logic readdatavalid,
    input logic[7:0] burstcount,
    input logic beginbursttransfer
);


    // clocking block
    default clocking cb @(posedge clk);
    endclocking

    generate
       // simple wait request
        if (AVALONMODE == 0) begin : assert_waitrequest

            // When wait request = 1, control signals must be equal to old control signals
            assert_waitreq1: assert property (!(read & write));
            assert_waitreq2: assert property    ((waitrequest and $stable(waitrequest)) |->
                                                ($stable(read)  and
                                                 $stable(write) and
                                                 $stable(readdatavalid) and
                                                 $stable(byteenable) and
                                                 $stable(address))
                                                 );
            assert_waitreq3: assert property     ($fell(waitrequest) and read |-> readdatavalid);
        end

        // Fixed wait
        if (AVALONMODE == 1) begin : assert_fixed

            assert1: assert property (!(read & write));

        end

        if (AVALONMODE == 2) begin : assert_pipeline_variable

            assert1: assert property (!(read & write));

        end

        if (AVALONMODE == 3) begin : assert_pipeline_fixed

            assert1: assert property (!(read & write));

        end

        if (AVALONMODE == 4) begin : assert_burst
            int total_burst = 0;
            int total_readdata = 0;

            assert1: assert property (!(read & write));
            assert2: assert property ($rise(beginbursttransfer) |-> $rise(waitrequest));
            assert3: assert property ($rise(beginbursttransfer) |-> $rise(waitrequest));

        end

    endgenerate
endmodule
