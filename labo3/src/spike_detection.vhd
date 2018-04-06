-------------------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- File         : spike_detection.vhd
-- Description  : This architecture is used to detect and extract a window that
--                contain a neural spike. NOTE : due to some generics this
--                version is probably unsynthetizable but will be used in a
--                verification course so it is not a problem
--
-- Author       : Mike Meury
-- Date         : 20.03.2018
-- Version      : 1.0
--
-- Dependencies :
--
--| Modifications |------------------------------------------------------------
-- Version   Author Date               Description
-- 1.0       MIM    20.03.18           Creation
-- 1.1       MIM    03.04.18           Correction 
-------------------------------------------------------------------------------

------------------------
-- Standard libraries --
------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------
-- Specifics libraries --
-------------------------

------------
-- Entity --
------------
entity spike_detection is
    generic (
        ERRNO : integer range 0 to 15 := 0
        );
    port (
        -- standard inputs
        clk_i                  : in  std_logic;
        rst_i                  : in  std_logic;
        -- Samples
        sample_i               : in  std_logic_vector(15 downto 0);
        sample_valid_i         : in  std_logic;
        ready_o                : out std_logic;
        -- Ouputs
        samples_spikes_o       : out std_logic_vector(15 downto 0);
        samples_spikes_valid_o : out std_logic;
        spike_detected_o       : out std_logic
        );
end entity;

------------------
-- Architecture --
------------------
architecture behave of spike_detection is

    ---------------
    -- Constants --
    ---------------
    constant WINDOW_SIZE      : integer             := 128;
    constant LOG2_WINDOW_SIZE : integer             := 7;
    constant FACTOR_DETECTION : signed(15 downto 0) := to_signed(15, 16);
    constant NB_ECH_WINDOW    : integer             := 150;
    constant POSITION         : integer             := 50;

    ----------------------
    -- Types definition --
    ----------------------
    type state_t is (
        IDLE,
        SAVING_DATA,
        END_DETECTION
        );

    -----------------------
    -- Internals signals --
    -----------------------
    -- fifo control
    signal read_fifo_s                    : std_logic;
    signal fifo_count_s                   : std_logic_vector(7 downto 0);
    -- spike detection
    signal sample_s                       : signed(sample_i'length-1 downto 0);
    signal moving_average_s               : signed(sample_i'length-1 downto 0);
    signal counter_sample_s               : unsigned(7 downto 0);  -- 0 to 255
    signal det_ready_s                    : std_logic;
    signal sum_squared_s                  : signed(sample_i'length*2+LOG2_WINDOW_SIZE-1 downto 0);
    signal sample_squared_s               : signed(sample_i'length*2-1 downto 0);
    signal sum_squared_div_s              : signed(sample_i'length*2-1 downto 0);
    signal spike_s                        : std_logic;
    signal moving_average_squared_s       : signed(sample_i'length*2-1 downto 0);
    signal standard_deviation_squared_s   : signed(sample_i'length*2-1 downto 0);
    signal product_std_dev_factor_squared : signed(standard_deviation_squared_s'length + FACTOR_DETECTION'length - 1 downto 0);
    signal deviation_s                    : signed(sample_i'length downto 0);  -- one extra bit
    signal dev_squared_s                  : signed(deviation_s'length*2-1 downto 0);
    -- FSM
    signal current_state_s                : state_t;
    signal next_state_s                   : state_t;
    -- counter for stored samples
    signal counter_stored_samples_s       : unsigned(7 downto 0);
    signal rst_counter_sample_s           : std_logic;
    signal write_sample_s                 : std_logic;
    -- data for outputs
    signal data_out_s                     : std_logic_vector(sample_i'length-1 downto 0);
    -- dummy counter
    signal counter_errno_s                : unsigned(sample_i'length-1 downto 0);
    signal spike_detected_s               : std_logic;

begin  -- behave

    -----------------------
    -- Inputs conversion --
    -----------------------
    sample_s <= signed(sample_i);

    ----------
    -- FIFO --
    ----------
    fifo0 : entity work.fifo
        generic map (
            FIFO_DEPTH_G => 128,
            DATASIZE_G   => 16
            )
        port map (
            -- Standard Signals
            clk_i   => clk_i,
            rst_i   => rst_i,
            -- FIFO Port Signals
            -- Write side
            data_i  => sample_i,
            wr_en_i => sample_valid_i,
            full_o  => open,            -- not used
            -- Read side
            data_o  => data_out_s,
            rd_en_i => read_fifo_s,
            empty_o => open,            -- not used
            count_o => fifo_count_s
            );

    triangle_gen : if ERRNO = 7 generate
        process(clk_i, rst_i)
        begin
            if rst_i = '1' then
                counter_errno_s <= (others => '0');
            elsif rising_edge(clk_i) then
                if write_sample_s = '1' then
                    counter_errno_s <= counter_errno_s + 400;
                elsif spike_s = '1' then
                    counter_errno_s <= (others => '0');
                end if;
            end if;
        end process;
        samples_spikes_o <= std_logic_vector(counter_errno_s);
    end generate;
    norm_gen : if ERRNO /= 7 generate
        samples_spikes_o <= data_out_s when ERRNO /= 10 else
                            sample_i;
        counter_errno_s <= (others => '0');  -- avoid metavalues
    end generate;

    ---------------------
    -- Moving average  --
    ---------------------
    process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            moving_average_s <= (others => '0');
        elsif rising_edge(clk_i) then
            if sample_valid_i = '1' then
                -- mux to start moving average
                if det_ready_s = '0' then
                    moving_average_s <= moving_average_s + sample_s(15 downto 7);
                else
                    moving_average_s <= moving_average_s + (sample_s(15 downto 7) - moving_average_s(15 downto 7));
                end if;
            end if;
        end if;
    end process;

    ------------------------
    -- Standard deviation --
    ------------------------
    process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            sum_squared_s <= (others => '0');
        elsif rising_edge(clk_i) then
            if sample_valid_i = '1' then
                if det_ready_s = '1' then
                    sum_squared_s <= sample_squared_s - sum_squared_div_s + sum_squared_s;
                else
                    sum_squared_s <= sample_squared_s + sum_squared_s;
                end if;
            end if;
        end if;
    end process;

    --------------------
    -- Computing part --
    --------------------
    moving_average_squared_s     <= moving_average_s * moving_average_s;
    sample_squared_s             <= sample_s * sample_s;
    sum_squared_div_s            <= sum_squared_s(sum_squared_s'high downto LOG2_WINDOW_SIZE);
    standard_deviation_squared_s <= sum_squared_div_s - moving_average_squared_s when ERRNO /= 5 else
                                    sum_squared_div_s + moving_average_squared_s;
    product_std_dev_factor_squared <= (standard_deviation_squared_s * FACTOR_DETECTION);
    deviation_s                    <= resize(moving_average_s, deviation_s'length) - resize(sample_s, deviation_s'length);
    dev_squared_s                  <= deviation_s * deviation_s;
    spike_s                        <= '1' when (dev_squared_s > product_std_dev_factor_squared) and sample_valid_i = '1' and det_ready_s = '1' else
               '0';

    --------------------------------
    -- Counter for detector ready --
    --------------------------------
    process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            counter_sample_s <= (others => '0');
        elsif rising_edge(clk_i) then
            if det_ready_s = '1' then
                counter_sample_s <= counter_sample_s;
            else
                if sample_valid_i = '1' then
                    counter_sample_s <= counter_sample_s + 1;
                end if;
            end if;
        end if;
    end process;
    --------------------
    -- Detector ready --
    --------------------
    det_ready_s <= '1' when (((counter_sample_s = WINDOW_SIZE) and (ERRNO /= 12)) or ERRNO = 9) else
                   '0';

    ------------------
    -- Fifo manager --
    ------------------
    -- minus 2 because we want the spike to be the 50th sample. we must store
    -- 49 sample so 49-1 = 50-2
    read_fifo_s <= '1' when (unsigned(fifo_count_s) >= POSITION-2) or (ERRNO = 14) else
                   '0';

    -----------------------
    -- FSM to store data --
    -----------------------
    -- decoder
    process (current_state_s, spike_s, counter_stored_samples_s, write_sample_s)
    begin

        -- default value
        next_state_s         <= IDLE;
        spike_detected_s     <= '0';
        rst_counter_sample_s <= '0';

        case current_state_s is
            when IDLE =>
                if spike_s = '1' then
                    next_state_s <= SAVING_DATA;
                else
                    next_state_s <= IDLE;
                end if;
            when SAVING_DATA =>
                -- minus 2 because first is in IDLE state and last is in END_detection
                if counter_stored_samples_s >= (NB_ECH_WINDOW-2) and ERRNO /= 6 then
                    next_state_s <= END_DETECTION;
                else
                    next_state_s <= SAVING_DATA;
                end if;
            when END_DETECTION =>
                -- last sample
                if write_sample_s = '1' then
                    if ERRNO /= 13 then
                        spike_detected_s <= '1';
                    end if;
                    rst_counter_sample_s <= '1';
                    next_state_s         <= IDLE;
                else
                    next_state_s <= END_DETECTION;
                end if;
            when others =>
                next_state_s <= IDLE;
        end case;
    end process;
    -- register
    process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            current_state_s <= IDLE;
        elsif rising_edge(clk_i) then
            if ERRNO = 11 then
                current_state_s <= IDLE;
            else
                current_state_s <= next_state_s;
            end if;
        end if;
    end process;

    -------------------------------
    -- Counter for saved samples --
    -------------------------------
    process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            counter_stored_samples_s <= (others => '0');
        elsif rising_edge(clk_i) then
            if rst_counter_sample_s = '1' then
                counter_stored_samples_s <= (others => '0');
            elsif write_sample_s = '1' then
                if ERRNO = 7 then
                    counter_stored_samples_s <= counter_stored_samples_s + 3;
                else
                    counter_stored_samples_s <= counter_stored_samples_s + 1;
                end if;
            end if;
        end if;
    end process;

    ----------------------------
    -- Logic for output valid --
    ----------------------------
    -- decoder
    write_sample_s <= read_fifo_s when spike_s = '1' else
                      read_fifo_s when current_state_s = SAVING_DATA else
                      read_fifo_s when current_state_s = END_DETECTION else
                      '0';
    -- output
    process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            samples_spikes_valid_o <= '0';
        elsif rising_edge(clk_i) then
            if ERRNO /= 15 then
                samples_spikes_valid_o <= write_sample_s;
            else
                samples_spikes_valid_o <= '0';
            end if;
        end if;
    end process;

    -----------------------------
    -- Spike detected register --
    -----------------------------
    process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            spike_detected_o <= '0';
        elsif rising_edge(clk_i) then
            spike_detected_o <= spike_detected_s;
        end if;
    end process;

    ----------------------
    -- Ready generation --
    ----------------------
    ready_o <= '1' when ERRNO /= 8 else
               '0';

end architecture;  -- behave
