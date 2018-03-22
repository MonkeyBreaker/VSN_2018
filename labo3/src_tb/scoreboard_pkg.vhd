
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library tlmvm;
context tlmvm.tlmvm_context;

use work.input_transaction_fifo_pkg.all;
use work.output_transaction_fifo_pkg.all;
use work.transactions_pkg.all;
use work.spike_detection_pkg.all;

package scoreboard_pkg is

    procedure scoreboard(variable fifo_input  : inout work.input_transaction_fifo_pkg.tlm_fifo_type;
                         variable fifo_output : inout work.output_transaction_fifo_pkg.tlm_fifo_type
    );


end package;


package body scoreboard_pkg is


    procedure scoreboard(variable fifo_input  : inout work.input_transaction_fifo_pkg.tlm_fifo_type;
                         variable fifo_output : inout work.output_transaction_fifo_pkg.tlm_fifo_type
    ) is
        variable trans_input  : input_transaction_t;
        variable trans_output : output_transaction_t;
        variable counter      : integer;
        variable expected     : std_logic_vector(7 downto 0);
    begin

        raise_objection;

        counter := 0;

        for i in 0 to 9 loop
            report "Scoreboard waiting for transaction number " & integer'image(counter) severity note;
            blocking_get(fifo_output, trans_output);
            blocking_get(fifo_input, trans_input);
            report "Scoreboard received transaction number " & integer'image(counter) severity note;
            expected := std_logic_vector(
                unsigned(trans_input.a) +
                unsigned(trans_input.b) +
                unsigned(trans_input.c));
            if (expected /= trans_output.r) then
                report "Scoreboard : Error in transaction number " & integer'image(counter) severity error;
            end if;
            counter := counter + 1;
        end loop;

        drop_objection;

    end scoreboard;

end package body;
