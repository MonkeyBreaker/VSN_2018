
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library tlmvm;
context tlmvm.tlmvm_context;

use work.output_transaction_fifo_pkg.all;
use work.transactions_pkg.all;
use work.spike_detection_pkg.all;

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
        for i in 0 to 9 loop
            report "Monitor waiting for transaction number " & integer'image(counter) severity note;
            ok := false;
            while (not ok) loop
                wait until rising_edge(clk);
                if (port_output.samples_spikes_valid = '1') then
                    -- TODO : Get information and build the transaction

                    blocking_put(fifo, transaction);
                    report "Monitor received transaction number " & integer'image(counter) severity note;
                    counter := counter + 1;
                    ok := true;
                end if;
            end loop;
        end loop;

        wait;

    end monitor;

end package body;
