
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
        variable trans_output : output_transaction_t;
        variable counter_out         : integer;
        variable counter_in          : integer;
        variable counter_fifo_0      : integer;
        variable expected     : std_logic_vector(7 downto 0);
    begin

        -- raise_objection;

        counter_in := 0;
        counter_out := 0;
        counter_fifo_0 := 0;

        while true loop

            if(fifo_output.is_empty = false) then
              blocking_get(fifo_output, trans_output);
              logger.log_note("[Scoreboard] received monitor 1 " & integer'image(counter_out));

              -- while(counter_fifo_0 > 150) loop
              --  blocking_get(fifo_monitor_0, trans_input);
              --   counter_fifo_0 := counter_fifo_0-1;
              -- end loop;

              for i in 0 to (trans_output.data_out_trans'length)-1 loop
                blocking_get(fifo_monitor_0, trans_input);
                logger.log_note("[Scoreboard] monitor 0, value received : " & integer'image(to_integer(signed(trans_input.data_in_trans))));
                logger.log_note("[Scoreboard] monitor 1, value received : " & integer'image(to_integer(signed(trans_output.data_out_trans(i)))));
                counter_fifo_0 := counter_fifo_0-1;
              end loop;

              counter_out := counter_out + 1;
            end if;

            blocking_get(fifo_input, trans_input);
            logger.log_note("[Scoreboard] received monitor 0 " & integer'image(counter_in));
            counter_in := counter_in + 1;

            logger.log_note("[Scoreboard] monitor 0, value received : " & integer'image(to_integer(signed(trans_input.data_in_trans))));

            if(counter_fifo_0 < 200) then
              blocking_put(fifo_monitor_0, trans_input);
              counter_fifo_0 := counter_fifo_0+1;
            else
              -- Pseudo Circular buffer
              blocking_put(fifo_monitor_0, trans_input);

              blocking_get(fifo_monitor_0, trans_input);
            end if;

        end loop;

        -- drop_objection;

    end scoreboard;

end package body;
