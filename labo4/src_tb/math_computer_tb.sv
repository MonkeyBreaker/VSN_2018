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

    task generate_random_stimuli(int enable_a,
                                 int enable_b,
                                 int enable_c);
      // Assign a random value to a and b
      if(ENABLE == enable_a)
        assert(randomize(cb.a));
      if(ENABLE == enable_b)
        assert(randomize(cb.b));
      if(ENABLE == enable_c)
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
        automatic int result = 0;
        automatic int iters = nb_iter;
        $display("Let's start second test case");
        cb.a <= 0;
        cb.b <= 0;
        cb.c <= 0;
        cb.input_valid  <= 0;
        cb.output_ready <= 1;

        reset_DUT();

        while(0 != iters) begin
          wait_input_ready();
          generate_random_stimuli(ENABLE,ENABLE,DISABLE);
          result = (cb.a+cb.b);

          $display("%d + %d = %d", cb.a, cb.b, result);

          $display("Result before = %d",cb.result);
          wait_end_computation();
          $display("Result after = %d",cb.result);

          if (cb.result == result)
            $display("The result is correct");
          else
            $display("The result is incorrect");

          iters--;
        end

    endtask



    // Programme lancé au démarrage de la simulation
    program TestSuite;
        initial begin
            if (testcase == 0) begin
                test_case0();
                test_case1(10);
            end
            else
                $display("Ach, test case not yet implemented");
            $display("done!");
            $stop;
        end
    endprogram

endmodule
