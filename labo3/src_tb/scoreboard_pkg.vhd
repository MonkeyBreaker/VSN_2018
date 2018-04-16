library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library tlmvm;
context tlmvm.tlmvm_context;

library project_lib;
context project_lib.project_ctx;

use project_lib.input_transaction_fifo_pkg.all;
use project_lib.output_transaction_fifo_pkg.all;
use project_lib.transactions_pkg.all;
use project_lib.spike_detection_pkg.all;

package scoreboard_pkg is

    procedure scoreboard(variable fifo_input  : inout work.input_transaction_fifo_pkg.tlm_fifo_type;
                         variable fifo_output : inout work.output_transaction_fifo_pkg.tlm_fifo_type
    );


end package;


package body scoreboard_pkg is


    procedure scoreboard(variable fifo_input  : inout work.input_transaction_fifo_pkg.tlm_fifo_type;
                         variable fifo_output : inout work.output_transaction_fifo_pkg.tlm_fifo_type
    ) is
        -- maybe possible only array
        variable fifo_monitor_0 : work.input_transaction_fifo_pkg.tlm_fifo_type;
        variable trans_input  : input_transaction_t;
        variable trans_input_drop  : input_transaction_t;
        variable trans_output : output_transaction_t;

        variable spike_detected_ref              : boolean;
        variable data_match                      : boolean;
        variable timeout_ok                         : boolean;

        variable counter_out         : integer;
        variable counter_in          : integer;
        variable counter_samples_received_bounded          : integer;
        variable counter_fifo_0      : integer;
        variable counter_timeout     : integer;
        variable window_size               : integer;
        variable factor_square             : integer;
        variable waiting_to_receive_spike          : integer;

        variable expected     : std_logic_vector(7 downto 0);
        variable sample_casted             : signed(15 downto 0);
        variable sample_casted_square             : signed(36 downto 0);
        variable mean_ref                  : signed(31 downto 0);
        variable deviation_standard_ref    : signed(63 downto 0);
        variable intermediate_sum_ref              : signed(47 downto 0);
        variable intermediate_sum_reduced_ref      : signed(47 downto 0);
        variable deviation_ref                     : signed(63 downto 0);

        -- When the ref detect a spike, the DUT will send us the data after 151 samples : 50 because of the implementation of the DUT, 100 of the samples after the spike, 1 for data aligned
        constant nb_samples_to_wait_after_spike_detection : integer := 152;
        constant time_before_timeout : time := 20 ns;

    begin

        raise_objection;
        --------------------
        -- initialization --
        --------------------
        counter_samples_received_bounded := 0;
        counter_in := 0;
        counter_out := 0;
        counter_fifo_0 := 0;
        counter_timeout := 0;
        mean_ref := (others => '0');
        deviation_ref := (others => '0');
        deviation_standard_ref := (others => '0');
        factor_square := 15; -- seriously ... already squared !? Arghhhhh, and why do I need to check the DUT for know this value :@
        window_size := 128; -- Not 128, because the first sample is dropped
        spike_detected_ref := false;
       timeout_ok := false;
        intermediate_sum_ref := (others => '0');
        intermediate_sum_reduced_ref := (others => '0');
        waiting_to_receive_spike := nb_samples_to_wait_after_spike_detection;

        ----------------------
        -- Scoreboard Logic --
        ----------------------
        while true loop

            if(fifo_output.is_empty = false) and (waiting_to_receive_spike = 0 or timeout_ok = false) then
              blocking_get(fifo_output, trans_output);
              logger.log_note("[Scoreboard] received monitor 1 " & integer'image(counter_out));

              data_match := true;

              if(timeout_ok= false) then
                blocking_get(fifo_monitor_0, trans_input_drop);
                blocking_get(fifo_monitor_0, trans_input_drop);
              end if;

              -- Check that the values sent from the DUT are the same that we determined
              for i in 0 to (trans_output.data_out_trans'length)-1 loop
                blocking_get(fifo_monitor_0, trans_input);
                logger.log_note("[Scoreboard] monitor 0, value received : " & integer'image(to_integer(signed(trans_input.data_in_trans))));
                logger.log_note("[Scoreboard] monitor 1, value received : " & integer'image(to_integer(signed(trans_output.data_out_trans(i)))));

                if(trans_input.data_in_trans /= trans_output.data_out_trans(i)) then
                  data_match := false;
                end if;

                counter_fifo_0 := counter_fifo_0-1;

                -- End the simulation
                if(timeout_ok= false) then
                  drop_objection;
                end if;

              end loop;

              if (data_match = true) then
                logger.log_note("[Scoreboard] The data received from the DUT match the data determined by the REF");
              else
                logger.log_error("[Scoreboard] The Data received doesn't match ");
              end if;

              -- Data received from monitor 1
              counter_out := counter_out + 1;

            else
              if(waiting_to_receive_spike = 0) then
                logger.log_error("[Scoreboard] Spike was not found by the DUT");
              elsif (fifo_output.is_empty = false) then
                logger.log_error("[Scoreboard] Received a spike from DUT, the REF didn't find any");

                -- Data received from monitor 1
                counter_out := counter_out + 1;

                -- Clear FIFO
                blocking_get(fifo_output, trans_output);

                -- Check that the values sent from the DUT are the same that we determined
                for i in 0 to (trans_output.data_out_trans'length)-1 loop
                  blocking_get(fifo_monitor_0, trans_input);
                  logger.log_note("[Scoreboard] monitor 0, value received : " & integer'image(to_integer(signed(trans_input.data_in_trans))));
                  logger.log_note("[Scoreboard] monitor 1, value received : " & integer'image(to_integer(signed(trans_output.data_out_trans(i)))));

                  counter_fifo_0 := counter_fifo_0-1;
                end loop;
              end if;
            end if;

            blocking_timeout_get(fifo_input, trans_input, time_before_timeout,timeout_ok);

            ---------------------
            -- Circular Buffer --
            ---------------------
            if(counter_fifo_0 < 200) then
              blocking_put(fifo_monitor_0, trans_input);
              counter_fifo_0 := counter_fifo_0+1;
            else
              -- Pseudo Circular buffer
              blocking_put(fifo_monitor_0, trans_input);

              blocking_get(fifo_monitor_0, trans_input_drop);
            end if;

            ---------------------
            -- Circular Buffer --
            ---------------------

            if(timeout_ok= true) then
              counter_timeout := 0;
              logger.log_note("[Scoreboard] monitor 0 : transaction " & integer'image(counter_in));
              counter_in := counter_in +1;
              logger.log_note("[Scoreboard] monitor 0, value received : " & integer'image(to_integer(signed(trans_input.data_in_trans))));

              ----------------------------
              -- When spike is detected --
              ----------------------------
              -- when a spike is detected, start decreasing
              if(waiting_to_receive_spike /= nb_samples_to_wait_after_spike_detection) then
                if (waiting_to_receive_spike = 0) then
                  waiting_to_receive_spike := nb_samples_to_wait_after_spike_detection;
                else
                  waiting_to_receive_spike := waiting_to_receive_spike - 1;
                end if;
              end if;

              ---------------------------------
              -- Determine if spike detected --
              ---------------------------------

              sample_casted := signed(trans_input.data_in_trans);
              sample_casted_square := resize(sample_casted*sample_casted, sample_casted_square'length);

              if (counter_samples_received_bounded >= 1) then -- WHY THE F*CK the first value stored in the FIFO is not read in the DUT !? :@

                --------------------------------------------------------------------------------------
                -- Until we have received enough data to fill the FIFO (128), we don't remove X/128 --
                --------------------------------------------------------------------------------------
                if(counter_samples_received_bounded >= window_size+1) then
                  mean_ref := mean_ref + (sample_casted - mean_ref)/window_size;
                  intermediate_sum_reduced_ref := (resize(sample_casted_square, intermediate_sum_reduced_ref'length) + intermediate_sum_reduced_ref) - (intermediate_sum_reduced_ref)/window_size;
                else
                  mean_ref := mean_ref + (sample_casted)/window_size;
                  intermediate_sum_reduced_ref := resize(sample_casted_square, intermediate_sum_reduced_ref'length) + (intermediate_sum_reduced_ref);
                end if;

                deviation_ref := (sample_casted-mean_ref)*(sample_casted-mean_ref);
                deviation_standard_ref := resize((intermediate_sum_reduced_ref/window_size),deviation_standard_ref'length) - mean_ref*mean_ref;

                -- logger.log_note("[Scoreboard] sample_casted                 : " & integer'image(to_integer(sample_casted)));
                -- logger.log_note("[Scoreboard] sample_casted_square          : " & integer'image(to_integer(sample_casted_square)));
                -- logger.log_note("[Scoreboard] mean_ref                      : " & integer'image(to_integer(mean_ref)));
                -- logger.log_note("[Scoreboard] intermediate_sum_ref          : " & integer'image(to_integer(intermediate_sum_ref)));
                -- logger.log_note("[Scoreboard] intermediate_sum_reduced_ref  : " & integer'image(to_integer(intermediate_sum_reduced_ref)));
                -- logger.log_note("[Scoreboard] deviation_ref                 : " & integer'image(to_integer(deviation_ref)));
                -- logger.log_note("[Scoreboard] deviation_standard_ref        : " & integer'image(to_integer(deviation_standard_ref)));
                -- logger.log_note("[Scoreboard] deviation_standard_ref*factor_square        : " & integer'image(to_integer( deviation_standard_ref*factor_square)));

                -- The last condition is to prevent generating a spike detection in the window of 150 samples
                if (deviation_ref > (deviation_standard_ref*factor_square)) and (counter_samples_received_bounded >= window_size+1)  and waiting_to_receive_spike = nb_samples_to_wait_after_spike_detection then
                  spike_detected_ref := true;
                  logger.log_note("[Scoreboard] spike detected");

                  waiting_to_receive_spike := waiting_to_receive_spike - 1;
                else
                  spike_detected_ref := false;
                end if;
              end if;

              if (counter_samples_received_bounded < window_size+1) then
                counter_samples_received_bounded := counter_samples_received_bounded + 1;
              end if;

            else
              counter_timeout := counter_timeout + 1;
              logger.log_note("[Scoreboard] Timeout " & integer'image(counter_timeout));
            end if;

            -- 51 clock cycles = 51 half cycles * 2
            if(counter_timeout > (51 * 2)) then
              drop_objection;
            end if;

            beat;

        end loop;

        drop_objection;

    end scoreboard;

end package body;
