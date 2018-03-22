--------------------------------------------------------------------------------
-- HEIG-VD
-- Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
-- School of Business and Engineering in Canton de Vaud
--------------------------------------------------------------------------------
-- REDS Institute
-- Reconfigurable Embedded Digital Systems
--------------------------------------------------------------------------------
--
-- File     : my_design_tb.vhd
-- Author   : TbGenerator
-- Date     : 16.03.2018
--
-- Context  :
--
--------------------------------------------------------------------------------
-- Description : This module is a simple VHDL testbench.
--               It instanciates the DUV and proposes a TESTCASE generic to
--               select which test to start.
--
--------------------------------------------------------------------------------
-- Dependencies : -
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver   Date        Person     Comments
-- 0.1   16.03.2018  TbGen      Initial version
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library tlmvm;
context tlmvm.tlmvm_context;

use work.spike_detection_pkg.all;

use work.input_transaction_fifo_pkg.all;
use work.input_transaction_fifo1_pkg.all;
use work.output_transaction_fifo_pkg.all;
use work.agent0_pkg.all;
use work.scoreboard_pkg.all;

entity spike_detection_tb is
    generic (
        TESTCASE : integer := 0
    );

end spike_detection_tb;

architecture testbench of spike_detection_tb is

    constant CLK_PERIOD : time := 10 ns;

    signal clk_sti          : std_logic;
    signal rst_sti          : std_logic;
    signal port0_input_sti  : port0_input_t;
    signal port0_output_obs : port0_output_t;
    signal port1_output_obs : port1_output_t;

    component spike_detection is
        port (
            -- standard inputs
            clk_i                  : in  std_logic;
            rst_i                  : in  std_logic;
            -- Samples
            sample_i               : in  std_logic_vector(15 downto 0);
            sample_valid_i         : in  std_logic;
            ready_o                : out std_logic;
            -- Ouputs
            samples_spikes_o       : out std_logic_vector(15 downto 0);
            samples_spikes_valid_o : out std_logic;
            spike_detected_o       : out std_logic
            );
    end component;

    shared variable fifo_seq0_to_driver0 : work.input_transaction_fifo1_pkg.tlm_fifo_type;
    shared variable fifo_mon0_to_score : work.input_transaction_fifo_pkg.tlm_fifo_type;

    shared variable fifo_mon1_to_score : work.output_transaction_fifo_pkg.tlm_fifo_type;


  	procedure rep(finish_status: finish_status_t) is
  	begin
  		report "I finished, yippee";
  	end rep;

begin


	monitor: simulation_monitor
	generic map (drain_time => 50 ns,
                 beat_time => 400 ns,
                 final_reporting => rep);


	clk_proc : clock_generator(clk_sti, CLK_PERIOD);

	rst_proc : simple_startup_reset(rst_sti, 2*CLK_PERIOD);

    agent0_sequencer : work.agent0_pkg.sequencer(fifo_seq0_to_driver0, TESTCASE);

    agent0_driver : work.agent0_pkg.driver(fifo_seq0_to_driver0,
                                           clk_sti,
                                           rst_sti,
                                           port0_input_sti,
                                           port0_output_obs );

    agent0_monitor : work.agent0_pkg.monitor(fifo_mon0_to_score,
                                             clk_sti,
                                             rst_sti,
                                             port0_input_sti,
                                             port0_output_obs );


    agent1_monitor : work.agent1_pkg.monitor(fifo_mon1_to_score,
                                             clk_sti,
                                             rst_sti,
                                             port1_output_obs );

    scoreboard : work.scoreboard_pkg.scoreboard(fifo_mon0_to_score,
                                                fifo_mon1_to_score);

    duv : spike_detection
        port map (
            clk_i                  => clk_sti,
            rst_i                  => rst_sti,

            sample_i               => port0_input_sti.sample,
            sample_valid_i         => port0_input_sti.sample_valid,
            ready_o                => port0_output_obs.ready,

            samples_spikes_o       => port1_output_obs.samples_spikes,
            samples_spikes_valid_o => port1_output_obs.samples_spikes_valid,
            spike_detected_o       => port1_output_obs.spike_detected
        );
end testbench;
