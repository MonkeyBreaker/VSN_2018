/******************************************************************************
Project Math_computer

File : math_computer_tb.sv
Description : This module implements a test bench for a simple
              mathematic calculator.
              Currently it is far from being efficient nor useful.

Author : Y. Thoma
Team   : REDS institute

Date   : 13.04.2017

| Modifications |--------------------------------------------------------------
Ver    Date         Who    Description
1.0    13.04.2017   YTA    First version

******************************************************************************/

`include "math_computer_macros.sv"
`include "math_computer_itf.sv"

module math_computer_tb#(integer testcase = 0,
                         integer errno = 0);

    // enum for functionalities
    enum integer {DISABLE = 0, ENABLE = 1} functionalitie_status;

    // Déclaration et instanciation des deux interfaces
    math_computer_input_itf input_itf();
    math_computer_output_itf output_itf();

    // Seulement deux signaux
    logic      clk = 0;
    logic      rst;

    // instanciation du compteur
    math_computer dut(clk, rst, input_itf, output_itf);

    // génération de l'horloge
    always #5 clk = ~clk;

    // clocking block
    default clocking cb @(posedge clk);
        output #3ns rst,
               a            = input_itf.a,
               b            = input_itf.b,
               c            = input_itf.c,
               input_valid  = input_itf.valid,
               output_ready = output_itf.ready;
        input  input_ready  = input_itf.ready,
               result       = output_itf.result,
               output_valid = output_itf.valid;
    endclocking

    class dut_inputs;
      rand logic[`DATASIZE-1:0] di_a;
      rand logic[`DATASIZE-1:0] di_b;
      rand logic[`DATASIZE-1:0] di_c;
    endclass

    class dut_inputs_cons extends dut_inputs;
      constraint a_cons {
        di_a dist {
          [0:10] := 1,
          [11:2**(`DATASIZE)-1]  := 1
        };
      }

      constraint c_cons {
        (di_a > di_b) -> di_c inside {[0:1000]};
      }

      constraint b_cons {
        (((di_a%2) == 0) && ((di_b%2) == 0)) -> di_b inside {di_b+1};
      }

    endclass : dut_inputs_cons

    covergroup cov_group_in @(posedge clk);
      cov_input_ready : coverpoint cb.input_ready;
      cov_result      : coverpoint cb.result;
      cov_output_valid: coverpoint cb.output_valid;
    endgroup

    covergroup cov_group_out @(posedge clk);
      cov_a           : coverpoint cb.a {bins little = {[0:100]}; bins mid = {[1000:2000]}; bins big = {[10000:30000]}; bins max = {2**(`DATASIZE)-1};}
      cov_b           : coverpoint cb.b {bins little = {[0:100]}; bins mid = {[1000:2000]}; bins big = {[10000:30000]}; bins max = {2**(`DATASIZE)-1};}
      cov_c           : coverpoint cb.c {bins little = {[0:100]}; bins mid = {[1000:2000]}; bins big = {[10000:30000]}; bins max = {2**(`DATASIZE)-1};}
      cov_input_valid : coverpoint cb.input_valid;
      cov_output_ready: coverpoint cb.output_ready;
      cov_cross: cross cov_a,cov_b;
    endgroup

    task generate_random_stimuli(int enable_a,
                                 int enable_b,
                                 int enable_c);
      // Assign a random value to a and b
      if(DISABLE != enable_a)
        assert(randomize(cb.a));
      if(DISABLE != enable_b)
        assert(randomize(cb.b));
      if(DISABLE != enable_c)
        assert(randomize(cb.c));

      // Enable the data inputs
      cb.input_valid <= 1;
      ##1;
      // Disable the data inputs
      cb.input_valid <= 0;
      ##1;
    endtask

    task wait_input_ready();
      while(cb.input_ready == 0) ##1;
    endtask

    task wait_end_computation();
      while(cb.output_valid == 0) ##1;
    endtask

    task reset_DUT();
      ##1;
      // Le reset est appliqué 5 fois d'affilée
      // But why :'( :'( :'('
      repeat (5) begin
          cb.rst <= 1;
          ##1 cb.rst <= 0;
          ##10;
      end
    endtask

    task test_case0();
        $display("Let's start first test case");
        cb.a <= 0;
        cb.b <= 0;
        cb.c <= 0;
        cb.input_valid  <= 0;
        cb.output_ready <= 0;

        reset_DUT();

        repeat (10) begin
            cb.input_valid <= 1;
            cb.a <= 1;
            ##1;
            ##($urandom_range(100));
            cb.output_ready <= 1;
        end
    endtask

    task test_case1(int nb_iter);
        automatic logic[`DATASIZE-1:0] result = 0;
        automatic int iters = nb_iter;
        automatic dut_inputs_cons duti = new;

        // instanciation du groupe de couverture
        automatic cov_group_in  cg_in = new;
        automatic cov_group_out cg_out = new;

        $display("Let's start second test case");
        cb.a <= 0;
        cb.b <= 0;
        cb.c <= 0;
        cb.input_valid  <= 0;
        cb.output_ready <= 1;

        reset_DUT();

        while(1) begin
          wait_input_ready();
          // When using generate_random_stimuli, the input_valid is done inside the function !
          // generate_random_stimuli(ENABLE,ENABLE,DISABLE);
          if (!duti.randomize()) $stop;
          cb.a <= duti.di_a;
          cb.b <= duti.di_b;

          // Enable the data inputs
          cb.input_valid <= 1;
          ##1;
          // Disable the data inputs
          cb.input_valid <= 0;
          ##1;

          result = (cb.a+cb.b);

          $display("%d + %d = %d", cb.a, cb.b, result);
          $display("di_c %d", duti.di_c);

          $display("Result before = %d",cb.result);
          wait_end_computation();
          $display("Result after = %d",cb.result);

          if (cb.result == result)
            $display("The result is correct");
          else
            $display("The result is incorrect");

          $display("Current global coverage : %d", $get_coverage());
          $display("Current input coverage  : %d", cg_in.get_inst_coverage());
          $display("Current output coverage : %d", cg_out.get_inst_coverage());

          iters--;
        end
    endtask

    task wait_for_coverage();
      do
        @(posedge clk);
      while (cov_group_in::get_coverage() < 100);
    endtask


    // Programme lancé au démarrage de la simulation
    program TestSuite;
        initial begin


            case(testcase)
              0       : test_case0();
              1       :   begin
                          fork
                            test_case1(10);
                            wait_for_coverage();
                          join_any
                          disable fork;
                          $display("Durée de la simulation: %0d ns", $time());
                        end
              default :
                $display("Ach, test case not yet implemented");
            endcase;
            $display("done!");
            $stop;
        end
    endprogram

endmodule
