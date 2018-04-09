
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library tlmvm;
context tlmvm.tlmvm_context;

library project_lib;
context project_lib.project_ctx;
use project_lib.output_transaction_fifo_pkg.all;
use project_lib.transactions_pkg.all;
use project_lib.spike_detection_pkg.all;

package agent1_pkg is


    procedure monitor(variable fifo : inout work.output_transaction_fifo_pkg.tlm_fifo_type;
        signal clk : in std_logic;
        signal rst : in std_logic;
        signal port_output : in port1_output_t
    );

end package;


package body agent1_pkg is


    procedure monitor(variable fifo : inout work.output_transaction_fifo_pkg.tlm_fifo_type;
        signal clk : in std_logic;
        signal rst : in std_logic;
        signal port_output : in port1_output_t
    ) is
        variable transaction : output_transaction_t;
        variable counter : integer;
        variable ok : boolean;
    begin

        counter := 0;
        while true loop
            logger.log_note("[Monitor 1] waiting for transaction number " & integer'image(counter));
            ok := false;
            while ok = false loop
                wait until rising_edge(clk);
                if (port_output.samples_spikes_valid = '1') then

                    transaction.data_out_trans(counter) := port_output.samples_spikes;
                    counter := counter + 1;

                    if (port_output.spike_detected = '1' or counter = 150) then -- last sample received
                      logger.log_note("[Monitor 1] Sending to scoreboard " & integer'image(counter));
                      blocking_put(fifo, transaction);
                      counter := 0;
                    end if;

                    logger.log_note("[Monitor 1] received transaction number " & integer'image(counter));
                    ok := true;
                end if;
            end loop;
        end loop;

        wait;

    end monitor;

end package body;
