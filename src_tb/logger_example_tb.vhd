--------------------------------------------------------------------------------
-- HEIG-VD
-- Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
-- School of Business and Engineering in Canton de Vaud
--------------------------------------------------------------------------------
-- REDS Institute
-- Reconfigurable Embedded Digital Systems
--------------------------------------------------------------------------------
--
-- File     : logger_example_tb.vhd
-- Author   : Yann Thoma
-- Date     : 14.02.2018
--
-- Context  :
--
--------------------------------------------------------------------------------
-- Description : This module shows an example of a simple logger shared
--               accross three entities.
--
--------------------------------------------------------------------------------
-- Dependencies : -
--shiftregistern     Comments
-- 0.1   14.02.2018  YTA      Initial version
--------------------------------------------------------------------------------

library project_lib;
context project_lib.project_ctx;


entity logger_example_tb is
    generic (
        TESTCASE : integer := 0
    );
end logger_example_tb;

architecture testbench of logger_example_tb is

    component tester1 is
    end component;

    component tester2 is
    end component;

begin

    t1 : entity work.tester1;
    t2 : tester2;


    stimulus_proc: process is
        variable a_v : std_logic_vector(7 downto 0);
        variable b_v : std_logic_vector(7 downto 0);

        variable trans1_v : transaction_t;
        variable trans2_v : transaction_t;
    begin
        -- configure the logger
        logger.enable_write_on_file;
        -- If the set_log_file_name is not called, it will not write on a file
        logger.set_log_file_name("toto.txt");
        logger.set_severity_level(level => error);

        -- test
        logger.log_error;

        wait for 20 us;


        compare(logger, a_v, b_v);

        a_v := "00000000";
        b_v := "11111111";
        compare(logger, a_v, b_v);

        a_v := "11111111";
        b_v := "11111111";
        compare(logger, a_v, b_v);

        trans1_v := transaction_t'(1,2,(others=>'0'));
        trans2_v := transaction_t'(1,2,(others=>'0'));
        work.transaction_comparator_pkg.compare(logger, trans1_v, trans2_v);

        trans1_v := transaction_t'(1,3,(others=>'0'));
        trans2_v := transaction_t'(1,2,(others=>'0'));

        work.transaction_comparator_pkg.compare(logger, trans1_v, trans2_v);
        work.transaction_lazy_comparator_pkg.compare(logger, trans1_v, trans2_v);

        trans1_v := transaction_t'(1,3,(others=>'0'));
        trans2_v := transaction_t'(2,2,(others=>'0'));

        work.transaction_comparator_pkg.compare(logger, trans1_v, trans2_v);
        work.transaction_lazy_comparator_pkg.compare(logger, trans1_v, trans2_v);

        logger.final_report;

        -- stop the process
        wait;

    end process; -- stimulus_proc

end testbench;
