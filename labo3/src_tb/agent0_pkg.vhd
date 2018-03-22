
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library tlmvm;
context tlmvm.tlmvm_context;

use work.input_transaction_fifo_pkg.all;
use work.input_transaction_fifo1_pkg.all;
use work.output_transaction_fifo_pkg.all;
use work.transactions_pkg.all;
use work.spike_detection_pkg.all;

package agent0_pkg is

    procedure sequencer(variable fifo : inout work.input_transaction_fifo1_pkg.tlm_fifo_type;
                        constant testcase : in integer);

    procedure driver(variable fifo : inout work.input_transaction_fifo1_pkg.tlm_fifo_type;
        signal clk : in std_logic;
        signal rst : in std_logic;
        signal port_input  : out port0_input_t;
        signal port_output : in port0_output_t
    );


    procedure monitor(variable fifo : inout work.input_transaction_fifo_pkg.tlm_fifo_type;
        signal clk : in std_logic;
        signal rst : in std_logic;
        signal port_input  : in port0_input_t;
        signal port_output : in port0_output_t
    );

end package;


package body agent0_pkg is

    procedure sequencer(variable fifo : inout work.input_transaction_fifo1_pkg.tlm_fifo_type;
                        constant testcase : in integer) is
        variable transaction : input_transaction_t;
        variable counter     : integer;
    begin
        raise_objection;
        counter := 0;

        case testcase is
            when 0 =>
            for i in 0 to 9 loop
                -- TODO : Prepare a transaction

                blocking_put(fifo, transaction);
                report "Sequencer : Sent transaction number " & integer'image(counter) severity note;
                counter := counter + 1;
            end loop;

            when 1 =>
            for i in 0 to 9 loop
                -- TODO : Prepare a transaction

                blocking_put(fifo, transaction);
                report "Sequencer : Sent transaction number " & integer'image(counter) severity note;
                counter := counter + 1;
            end loop;

            when others =>
                report "Sequencer : Unsupported testcase" severity error;

        end case;

        drop_objection;
        report "Sequencer finished his job" severity note;
        wait;
    end sequencer;



    procedure driver(variable fifo : inout work.input_transaction_fifo1_pkg.tlm_fifo_type;
        signal clk : in std_logic;
        signal rst : in std_logic;
        signal port_input  : out port0_input_t;
        signal port_output : in port0_output_t
    ) is
        variable transaction : input_transaction_t;
        variable counter : integer;
    begin

        raise_objection;

        counter := 0;

        for i in 0 to 9 loop
            report "Driver waiting for transaction number " & integer'image(counter) severity note;
            blocking_get(fifo, transaction);
            report "Driver received transaction number " & integer'image(counter) severity note;
            wait until falling_edge(clk);
            -- TODO : Act on the DUV

            wait until falling_edge(clk);

            counter := counter + 1;
        end loop;

        drop_objection;

        wait;

    end driver;


    procedure monitor(variable fifo : inout work.input_transaction_fifo_pkg.tlm_fifo_type;
        signal clk : in std_logic;
        signal rst : in std_logic;
        signal port_input  : in port0_input_t;
        signal port_output : in port0_output_t
    ) is
        variable transaction : input_transaction_t;
        variable counter : integer;
        variable ok : boolean;
    begin

        counter := 0;
        for i in 0 to 9 loop
            report "Monitor waiting for transaction number " & integer'image(counter) severity note;
            ok := false;
            while (not ok) loop
                wait until rising_edge(clk);
                -- TODO : Retrieve data and create a transaction
                if (port_input.valid = '1') then
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
