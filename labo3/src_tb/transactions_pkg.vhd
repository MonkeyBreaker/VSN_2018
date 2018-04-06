
library ieee;
use ieee.std_logic_1164.all;

package transactions_pkg is

    type input_transaction_t is record
        data_in_trans : std_logic_vector(15 downto 0);
        -- Possibility to add more signal, e.g. the delta time between each sample
    end record;

    type data_t is array (0 to 149) of std_logic_vector(15 downto 0);
    
    type output_transaction_t is record
        -- maybe possible only array
        data_out_trans : data_t;
    end record;

end package;
