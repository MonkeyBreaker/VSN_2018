
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
        variable counter_out         : integer;
        variable counter_in          : integer;
        variable counter_fifo_0      : integer;
        variable expected     : std_logic_vector(7 downto 0);
        variable sample_casted             : signed(15 downto 0);
        variable sample_casted_square             : signed(31 downto 0);
        variable mean_ref                  : signed(31 downto 0);
        variable deviation_standard_ref    : signed(63 downto 0);
        variable is_spike_ref              : boolean;
        variable window_size               : integer;
        variable factor_square             : integer;
        variable intermediate_sum_ref              : signed(63 downto 0);
        variable intermediate_sum_reduced_ref      : signed(31 downto 0);
        variable deviation_ref                     : signed(63 downto 0);

    begin

        -- raise_objection;
        --------------------
        -- initialization --
        --------------------
        counter_in := 0;
        counter_out := 0;
        counter_fifo_0 := 0;
        mean_ref := (others => '0');
        deviation_ref := (others => '0');
        deviation_standard_ref := (others => '0');
        factor_square := 15; -- seriously ... already squared !? Arghhhhh, and why do I need to check the DUT for know this value :@
        window_size := 128; -- Not 128, because the first sample is dropped
        is_spike_ref := false;
        intermediate_sum_ref := (others => '0');
        intermediate_sum_reduced_ref := (others => '0');

        ----------------------
        -- Scoreboard Logic --
        ----------------------
        while true loop

            if(fifo_output.is_empty = false) then
              blocking_get(fifo_output, trans_output);
              logger.log_note("[Scoreboard] received monitor 1 " & integer'image(counter_out));

              for i in 0 to (trans_output.data_out_trans'length)-1 loop
                blocking_get(fifo_monitor_0, trans_input);
                logger.log_note("[Scoreboard] monitor 0, value received : " & integer'image(to_integer(signed(trans_input.data_in_trans))));
                logger.log_note("[Scoreboard] monitor 1, value received : " & integer'image(to_integer(signed(trans_output.data_out_trans(i)))));
                counter_fifo_0 := counter_fifo_0-1;
              end loop;

              counter_out := counter_out + 1;
            end if;

            blocking_get(fifo_input, trans_input);
            -- logger.log_note("[Scoreboard] received monitor 0 " & integer'image(counter_in));

            logger.log_note("[Scoreboard] monitor 0, value received : " & integer'image(to_integer(signed(trans_input.data_in_trans))));

            if(counter_fifo_0 < 200) then
              blocking_put(fifo_monitor_0, trans_input);
              counter_fifo_0 := counter_fifo_0+1;
            else
              -- Pseudo Circular buffer
              blocking_put(fifo_monitor_0, trans_input);

              blocking_get(fifo_monitor_0, trans_input_drop);
            end if;

            ---------------------------------
            -- Determine if spike detected --
            ---------------------------------

            sample_casted := signed(trans_input.data_in_trans);
            sample_casted_square := sample_casted*sample_casted;

            if (counter_in >= 1) then -- WHY THE F*CK the first value stored in the FIFO is not read in the DUT !? :@
              if(counter_in >= window_size+1) then
                mean_ref := mean_ref + (sample_casted - mean_ref)/window_size;
                intermediate_sum_reduced_ref := (sample_casted_square + intermediate_sum_reduced_ref) - (intermediate_sum_reduced_ref)/window_size;
              else
                mean_ref := mean_ref + (sample_casted)/window_size;
                intermediate_sum_reduced_ref := sample_casted_square + (intermediate_sum_reduced_ref);
              end if;

              deviation_ref := (sample_casted-mean_ref)*(sample_casted-mean_ref);
              deviation_standard_ref := (intermediate_sum_reduced_ref/window_size) - mean_ref*mean_ref;

              logger.log_note("[Scoreboard] sample_casted                 : " & integer'image(to_integer(sample_casted)));
              logger.log_note("[Scoreboard] sample_casted_square          : " & integer'image(to_integer(sample_casted_square)));
              logger.log_note("[Scoreboard] mean_ref                      : " & integer'image(to_integer(mean_ref)));
              logger.log_note("[Scoreboard] intermediate_sum_ref          : " & integer'image(to_integer(intermediate_sum_ref)));
              logger.log_note("[Scoreboard] intermediate_sum_reduced_ref  : " & integer'image(to_integer(intermediate_sum_reduced_ref)));
              logger.log_note("[Scoreboard] deviation_ref                 : " & integer'image(to_integer(deviation_ref)));
              logger.log_note("[Scoreboard] deviation_standard_ref        : " & integer'image(to_integer(deviation_standard_ref)));
              logger.log_note("[Scoreboard] deviation_standard_ref*factor_square        : " & integer'image(to_integer( deviation_standard_ref*factor_square)));

              if (deviation_ref > (deviation_standard_ref*factor_square)) and (counter_in >= window_size+1) then
                is_spike_ref := true;
                logger.log_note("[Scoreboard] spike detected");
                -- counter_in := 0;
              else
                is_spike_ref := false;
              end if;
            end if;

            if (counter_in < window_size+1) then
              counter_in := counter_in + 1;
            end if;

        end loop;

        -- drop_objection;

    end scoreboard;

end package body;
