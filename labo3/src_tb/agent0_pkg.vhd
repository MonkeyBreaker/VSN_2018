
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library tlmvm;
context tlmvm.tlmvm_context;

library project_lib;
context project_lib.project_ctx;

use project_lib.input_transaction_fifo_pkg.all;
use project_lib.input_transaction_fifo1_pkg.all;
use project_lib.output_transaction_fifo_pkg.all;
use project_lib.transactions_pkg.all;
use project_lib.spike_detection_pkg.all;

package agent0_pkg is

  procedure sequencer(variable fifo     : inout work.input_transaction_fifo1_pkg.tlm_fifo_type;
                      constant testcase : in    integer);

  procedure driver(variable fifo      : inout work.input_transaction_fifo1_pkg.tlm_fifo_type;
                   signal clk         : in    std_logic;
                   signal rst         : in    std_logic;
                   signal port_input  : out   port0_input_t;
                   signal port_output : in    port0_output_t
                   );


  procedure monitor(variable fifo      : inout work.input_transaction_fifo_pkg.tlm_fifo_type;
                    signal clk         : in    std_logic;
                    signal rst         : in    std_logic;
                    signal port_input  : in    port0_input_t;
                    signal port_output : in    port0_output_t
                    );

end package;


package body agent0_pkg is

  constant SIZE_FRAME : integer := 1000;

  impure function get_signed_vector(nb : integer; length : integer) return std_logic_vector is
  begin
    return std_logic_vector(to_signed(nb, length));
  end get_signed_vector;

  impure function get_integer_signed_value(val : std_logic_vector) return integer is
  begin
    return to_integer(signed(val));
  end get_integer_signed_value;

  procedure sequencer(variable fifo     : inout work.input_transaction_fifo1_pkg.tlm_fifo_type;
                      constant testcase : in    integer) is
    variable transaction : input_transaction_t;
    variable counter     : integer;
  begin
    raise_objection;
    counter := 0;

    case testcase is
      when 0 => -- 1 spike
        counter := -(SIZE_FRAME/2);
        for i in 0 to SIZE_FRAME loop
          transaction.data_in_trans := get_signed_vector(counter, transaction.data_in_trans'length);
          blocking_put(fifo, transaction);
          logger.log_note("[Sequencer] : Sent transaction number " & integer'image(counter));
          counter := counter + 1;
        end loop;

      when 1 => -- 2 spikes
        for i in 0 to SIZE_FRAME loop
          -- TODO : Prepare a transaction

          blocking_put(fifo, transaction);
          logger.log_note("[Sequencer] : Sent transaction number " & integer'image(counter));
          counter := counter + 1;
        end loop;

      when others =>
        logger.log_error("[Sequencer] : Unsupported testcase");

    end case;

    drop_objection;
    logger.log_note("[Sequencer] finished his job");
    wait;
  end sequencer;



  procedure driver(variable fifo      : inout work.input_transaction_fifo1_pkg.tlm_fifo_type;
                   signal clk         : in    std_logic;
                   signal rst         : in    std_logic;
                   signal port_input  : out   port0_input_t;
                   signal port_output : in    port0_output_t
                   ) is
    variable transaction : input_transaction_t;
    variable counter     : integer;
  begin

    -- raise_objection;

    counter := 0;

    while true loop

      logger.log_note("[Driver] waiting for transaction number " & integer'image(counter));
      blocking_get(fifo, transaction);
      logger.log_note("[Driver] received transaction number " & integer'image(counter)
      & " Value received " & integer'image(get_integer_signed_value(transaction.data_in_trans)));

      logger.log_note("[Driver] port_output.ready " & to_string(port_output.ready));

      wait until falling_edge(clk) and port_output.ready = '1';

      logger.log_note("[Driver] Load Data  & enable data");
      port_input.sample <= transaction.data_in_trans;
      port_input.sample_valid <= '1';

      wait until falling_edge(clk);

      logger.log_note("[Driver] Disable Data");
      port_input.sample_valid <= '0';

      counter := counter + 1;
    end loop;

    -- drop_objection;

    wait;

  end driver;


  procedure monitor(variable fifo      : inout work.input_transaction_fifo_pkg.tlm_fifo_type;
                    signal clk         : in    std_logic;
                    signal rst         : in    std_logic;
                    signal port_input  : in    port0_input_t;
                    signal port_output : in    port0_output_t
                    ) is
    variable transaction : input_transaction_t;
    variable counter     : integer;
    variable ok          : boolean;
  begin

    counter := 0;

    while true loop

      logger.log_note("[Monitor 0] waiting for transaction number " & integer'image(counter));
      ok := false;
      while (not ok) loop
        wait until rising_edge(clk);

        transaction.data_in_trans := port_input.sample;

        if (port_input.sample_valid = '1' and port_output.ready = '1') then
          blocking_put(fifo, transaction);
          logger.log_note("[Monitor 0] received transaction number " & integer'image(counter));
          counter := counter + 1;
          ok      := true;
        end if;
      end loop;
    end loop;

    wait;

  end monitor;

end package body;
