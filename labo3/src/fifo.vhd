-------------------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- File         : fifo.vhd
-- Description  : 
--
-- Author       : Mike Meury
-- Date         : 19.03.2018
-- Version      : 0.0
--
-- Dependencies :
--
--| Modifications |------------------------------------------------------------
-- Version   Author Date               Description
-- 0.0       MIM    19.03.2018
-------------------------------------------------------------------------------

---------------
-- Libraries --
---------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

------------------
-- Dependencies --
------------------
use work.log_pkg.all;

------------
-- Entity --
------------
entity fifo is
    generic (
        FIFO_DEPTH_G : integer := 256;
        DATASIZE_G   : integer := 8
        );
    port (
        -- Standard Signals
        clk_i   : in  std_logic;
        rst_i   : in  std_logic;
        -- FIFO Port Signals
        -- Write side
        data_i  : in  std_logic_vector(DATASIZE_G-1 downto 0);
        wr_en_i : in  std_logic;
        full_o  : out std_logic;
        -- Read side
        data_o  : out std_logic_vector(DATASIZE_G-1 downto 0);
        rd_en_i : in  std_logic;
        empty_o : out std_logic;
        count_o : out std_logic_vector(ilogup(FIFO_DEPTH_G+1)-1 downto 0)
        );
end entity fifo;

------------------
-- Architecture --
------------------
architecture Behavioral of fifo is

    -----------
    -- types --
    -----------
    type fifo_type is                  
        array (0 to FIFO_DEPTH_G-1) of std_logic_vector(DATASIZE_G-1 downto 0);

    ----------------------
    -- Internal Signals --
    ----------------------
    signal counter_s  : unsigned(ilogup(FIFO_DEPTH_G+1)-1 downto 0);
    signal fifo_mem_s : fifo_type := (others => (others => '0'));
    signal head_s     : unsigned(ilogup(FIFO_DEPTH_G)-1 downto 0);
    signal tail_s     : unsigned(ilogup(FIFO_DEPTH_G)-1 downto 0);
    -- enable read write BRAM
    signal wr_s       : std_logic;
    signal rd_s       : std_logic;

begin

    ----------------------
    -- Process counters --
    ----------------------
    counters_process : process (clk_i, rst_i) is
    begin  -- process
        if rising_edge(clk_i) then      -- rising clock edge
            -- synchronus reset (active high)
            if rst_i = '1' then         -- synchronous reset (active high)
                head_s    <= (others => '0');
                tail_s    <= (others => '0');
                counter_s <= (others => '0');
            else
                -- Counters management
                -- Write
                if wr_en_i = '1' and counter_s /= FIFO_DEPTH_G then
                    -- Increments counter
                    -- counter must be incremented only if we are not
                    -- writing/reading the same channel and if there is at
                    -- least one element in the fifo otherwise we do not
                    -- update the value of the counter because we add an
                    -- element and delete another at the same time
                    if (not(rd_en_i = '1' and counter_s > 0)) then
                        counter_s <= counter_s + 1;
                    end if;

                    -- head managment
                    if head_s = FIFO_DEPTH_G - 1 then
                        head_s <= to_unsigned(0, head_s'length);
                    else
                        head_s <= head_s + 1;
                    end if;
                -- Read
                elsif rd_en_i = '1' and counter_s /= 0 then
                    -- counter decrement
                    -- counter must be decremented only if we are not
                    -- writing and reading the same channel AND if the fifo
                    -- is not full because the system will not write an
                    -- element if the fifo is full, so we have to decrement
                    -- even if we are writing/reading the same channel
                    if (not(wr_en_i = '1' and counter_s /= FIFO_DEPTH_G)) then
                        counter_s <= counter_s - 1;
                    end if;

                    -- tail management
                    if tail_s = FIFO_DEPTH_G - 1 then
                        tail_s <= to_unsigned(0, tail_s'length);
                    else
                        tail_s <= tail_s + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    ------------------
    -- Process BRAM --
    ------------------
    BRAM_Process : process(clk_i)
    begin
        if rising_edge(clk_i) then      -- The following code generate BRAM
            -- read
            if rd_s = '1' then
                -- read data from fifo
                data_o <= fifo_mem_s(to_integer(tail_s));
            end if;
            -- write
            if wr_s = '1' then
                -- write data in fifo
                fifo_mem_s(to_integer(head_s)) <= data_i;
            end if;
        end if;
    end process;

    ------------------------
    -- combinatorial part --
    ------------------------
    -- Counters 
    count_o <= std_logic_vector(counter_s);

    -- Flags
    full_o  <= '1' when (counter_s = FIFO_DEPTH_G) else '0';
    empty_o <= '1' when (counter_s = 0)            else '0';

    -- Read/write command
    rd_s <= '1' when (rd_en_i = '1' and counter_s /= 0)            else '0';
    wr_s <= '1' when (wr_en_i = '1' and counter_s /= FIFO_DEPTH_G) else '0';

end architecture Behavioral;
