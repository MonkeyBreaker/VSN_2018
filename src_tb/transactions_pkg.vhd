
library ieee;
use ieee.std_logic_1164.all;

package transactions_pkg is

    type transaction_t is record
        a : integer;
        b : integer;
        c : std_logic_vector(31 downto 0);
    end record;

    function transaction_to_string(val : transaction_t) return string;

    function lazy_compare(val1 : transaction_t; val2: transaction_t) return boolean;

end transactions_pkg;

package body transactions_pkg is

    function transaction_to_string(val : transaction_t) return string is
    begin
        return "a : " & to_string(val.a) & LF &
               "b : " & to_string(val.b) & LF &
               "c : " & to_string(val.c);
    end transaction_to_string;


    function lazy_compare(val1 : transaction_t; val2: transaction_t) return boolean is
    begin
        return val1.a = val2.a;
    end lazy_compare;

end transactions_pkg;
