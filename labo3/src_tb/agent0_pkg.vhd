
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library tlmvm;
context tlmvm.tlmvm_context;

library project_lib;
context project_lib.project_ctx;

library osvvm;
use osvvm.all;
use osvvm.RandomPkg.all;

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

  shared variable stop_monitor_0 : boolean := false;

end package;


package body agent0_pkg is

  constant SIZE_FRAME : integer := 1000;
  constant MAX_POSITIVE_VALUE : integer :=  3000;
  constant MAX_NEGATIVE_VALUE : integer := -3000;
  constant BUFFERIZE          : integer := 128;
  constant WINDOW_SIZE        : integer := 150;

  impure function get_signed_vector(nb : integer; length : integer) return std_logic_vector is
  begin
    return std_logic_vector(to_signed(nb, length));
  end get_signed_vector;

  impure function get_integer_signed_value(val : std_logic_vector) return integer is
  begin
    return to_integer(signed(val));
  end get_integer_signed_value;

  procedure generate_data(fifo : inout work.input_transaction_fifo1_pkg.tlm_fifo_type;
                          nb_samples : integer; nb_spikes : integer; factor : integer; random_seed : integer) is
    variable var_rand : RandomPType;
    variable transaction : input_transaction_t;
    variable data : integer;
    variable mean : integer;
    variable deviantion : integer;
    variable is_spike : boolean;
    variable last_spike : integer;
    variable spike_random : integer;
    variable nb_spike : integer;
  begin

    --------------------------
    -- Initialize variables --
    --------------------------
    last_spike := 0;
    nb_spike := 0;

    --------------------------------------------------
    -- Check if it's possible to cast enough spikes --
    --------------------------------------------------

    if((nb_samples/150) < nb_spikes) then
      logger.log_error("[Sequencer] Not enough space to place the spikes in the frame");
    end if;

    ---------------
    -- Init seed --
    ---------------
    var_rand.InitSeed(random_seed);

    -----------------------
    -- Generate the data --
    -----------------------
    for i in 0 to nb_samples loop
      data := var_rand.Uniform(MAX_NEGATIVE_VALUE, MAX_POSITIVE_VALUE);

      ----------------------------
      -- Compute necessary data --
      ----------------------------

      --------------------
      -- Generate spike --
      --------------------
      spike_random := var_rand.Uniform(-10, 10);
      -- Only generate a spike ~10% of the time
      if (i > last_spike+WINDOW_SIZE) and (spike_random < 1 and spike_random > -1) and nb_spikes >= nb_spike then
        data := deviantion*(factor+1);
        last_spike := i;
        nb_spike := nb_spike + 1;
        logger.log_error("[Sequencer] : Generate spike");
      elsif is_spike = true then     -- Do not generate a spike by chance
        data := data/10;
      end if;

      if (i < BUFFERIZE) then
        mean := mean + data/BUFFERIZE;
        deviantion := data**2 + deviantion;
      else
        mean := mean + (data-mean)/BUFFERIZE;
        deviantion := data**2 + deviantion - deviantion/WINDOW_SIZE;
      end if;

      is_spike := ((data-mean)**2) > deviantion*factor and i > BUFFERIZE;

      transaction.data_in_trans :=  get_signed_vector(data, transaction.data_in_trans'length);
      blocking_put(fifo, transaction);

    end loop;

  end generate_data;

  procedure sequencer(variable fifo     : inout work.input_transaction_fifo1_pkg.tlm_fifo_type;
                      constant testcase : in    integer) is
    variable transaction : input_transaction_t;
    variable counter     : integer;
  begin
    raise_objection;
    counter := 0;

    case testcase is
      when 1 => -- random
        generate_data(fifo, 1500, 4, 15, 1);

      when 0 => -- 2 spikes
        for i in 0 to SIZE_FRAME loop
          -- TODO : Prepare a transaction
          if (i = SIZE_FRAME/4) or (i = (SIZE_FRAME/4) + 120) or (i = (SIZE_FRAME/4) + 155) or (i = SIZE_FRAME-101) then -- (i = 3*SIZE_FRAME/4) or
            transaction.data_in_trans := get_signed_vector(10000, transaction.data_in_trans'length);
          else
            transaction.data_in_trans := get_signed_vector(0, transaction.data_in_trans'length);
          end if;

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
    variable timeout_ok     : boolean;
    constant time_before_timeout : time := 5 ns;
  begin

    -- raise_objection;

    counter := 0;

    while true loop

      logger.log_note("[Driver] waiting for transaction number " & integer'image(counter));
      blocking_timeout_get(fifo, transaction, time_before_timeout, timeout_ok);

      if (timeout_ok = true) then
        logger.log_note("[Driver] received transaction number " & integer'image(counter)
        & " Value received " & integer'image(get_integer_signed_value(transaction.data_in_trans)));
      else
        stop_monitor_0 := true;
        logger.log_note("[Driver] Timeout ");
      end if;

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

    -- wait;

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

    while stop_monitor_0 = false loop

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

    logger.log_note("[Monitor 0] Stopped ");

    -- wait;

  end monitor;

end package body;
