
library ieee;
use ieee.std_logic_1164.all;

package transactions_pkg is

    type input_transaction_t is record
        a : std_logic_vector(7 downto 0);
        b : std_logic_vector(7 downto 0);
        c : std_logic_vector(7 downto 0);
    end record;


    type output_transaction_t is record
        r : std_logic_vector(7 downto 0);
    end record;

end package;
