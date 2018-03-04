--------------------------------------------------------------------------------
-- HEIG-VD
-- Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
-- School of Business and Engineering in Canton de Vaud
--------------------------------------------------------------------------------
-- REDS Institute
-- Reconfigurable Embedded Digital Systems
--------------------------------------------------------------------------------
--
-- File     : alu_tb.vhd
-- Author   : TbGenerator
-- Date     : 01.03.2018
--
-- Context  :
--
--------------------------------------------------------------------------------
-- Description : This module is a simple VHDL testbench.
--               It instanciates the DUV and proposes a TESTCASE generic to
--               select which test to start.
--
--------------------------------------------------------------------------------
-- Dependencies : -
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver   Date        Person     Comments
-- 0.1   01.03.2018  TbGen      Initial version
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_tb is
    generic (
        TESTCASE : integer := 0;
        SIZE     : integer := 8;
        ERRNO    : integer := 0
    );

end alu_tb;

architecture testbench of alu_tb is

    signal a_sti    : std_logic_vector(SIZE-1 downto 0);
    signal b_sti    : std_logic_vector(SIZE-1 downto 0);
    signal s_obs    : std_logic_vector(SIZE-1 downto 0);
    signal c_obs    : std_logic;
    signal mode_sti : std_logic_vector(2 downto 0);

    signal sim_end_s : boolean := false;

    component alu is
    generic (
        SIZE  : integer := 8;
        ERRNO : integer := 20
    );
    port (
        a_i    : in std_logic_vector(SIZE-1 downto 0);
        b_i    : in std_logic_vector(SIZE-1 downto 0);
        s_o    : out std_logic_vector(SIZE-1 downto 0);
        c_o    : out std_logic;
        mode_i : in std_logic_vector(2 downto 0)
    );
    end component;

    type operator_enum is (add, sub, op_or, op_and, get_first_arg, get_second_arg,
      first_bit_test, zero);

begin

    duv : alu
    generic map (
        SIZE  => SIZE,
        ERRNO => ERRNO
    )
    port map (
        a_i    => a_sti,
        b_i    => b_sti,
        s_o    => s_obs,
        c_o    => c_obs,
        mode_i => mode_sti
    );

    stimulus_proc: process is

      impure function get_operator(operator : operator_enum) return std_logic_vector is
      begin
        case operator is
          when add =>
              return "000";
          when sub =>
              return "001";
          when op_or =>
              return "010";
          when op_and =>
              return "011";
          when get_first_arg =>
              return "100";
          when get_second_arg =>
              return "101";
          when first_bit_test =>
              return "110";
          when others =>
              return "111";
        end case;
      end get_operator;

      -- methods
      impure function get_signed_vector(nb : integer; length : integer) return std_logic_vector is
      begin
        return std_logic_vector(to_signed(nb, length));
      end get_signed_vector;

      impure function get_integer_value(val: std_logic_vector) return integer is
      begin
        return to_integer(signed(val));
      end get_integer_value;

      impure function get_correct_result(a : integer; b : integer; operator : operator_enum) return integer is
      begin
        case operator is
          when add =>
              return a+b;
          when sub =>
              return a-b;
          when op_or =>
              return get_integer_value(get_signed_vector(a, a_sti'length) or get_signed_vector(b, b_sti'length));
          when op_and =>
              return get_integer_value(get_signed_vector(a, a_sti'length) and get_signed_vector(b, b_sti'length));
          when get_first_arg =>
              return a;
          when get_second_arg =>
              return b;
          when first_bit_test =>
              if a = b then
                return 1;
              else
                return 0;
              end if;
          when others =>
              return 0;
        end case;
      end get_correct_result;

      procedure generate_input(a : integer; b : integer; mode : in operator_enum) is
      begin
        a_sti <= get_signed_vector(a, a_sti'length);
        b_sti <= get_signed_vector(b, b_sti'length);
        mode_sti <= get_operator(mode);
        wait for 10 ns;
      end generate_input;

    impure function verification_result(alu_value : integer; correct_value: integer; operator : operator_enum) return boolean is
    begin
      case operator is
        when first_bit_test =>
            if get_signed_vector(alu_value, SIZE)(0) = get_signed_vector(correct_value, SIZE)(0) then
              return true;
            else
              return false;
            end if;
        when others =>
            return alu_value=correct_value;
      end case;
    end verification_result;

    procedure test(a : integer; b : integer; mode : operator_enum) is
      variable correct_result : integer;
    begin
      generate_input(a, b, mode);
      correct_result := get_correct_result(a, b, mode);

      if(verification_result(get_integer_value(s_obs), correct_result, mode) = true) then
        report "good "  & integer'image(get_integer_value(s_obs)) & " "
                        & integer'image(correct_result) & " " & to_string(mode) & LF severity note;
      else
        report "bad "  & integer'image(get_integer_value(s_obs)) & " "
                       & integer'image(correct_result) &  " " & to_string(mode) & LF severity error;
      end if;
    end test;

    begin
        -- a_sti    <= default_value;
        -- b_sti    <= default_value;
        -- mode_sti <= default_value;
        -- add, sub, op_or, op_and, get_first_arg, get_second_arg,first_bit_test, zero
        test(1,2,add);
        test(2,2,sub);
        test(3,2,op_or);
        test(3,4,op_and);
        test(4,5,get_first_arg);
        test(4,5,get_second_arg);
        test(5,5,first_bit_test);
        test(5,5,zero);

        -- do something
        case TESTCASE is
            when 0      => -- default testcase
            when others => report "Unsupported testcase : "
                                  & integer'image(TESTCASE)
                                  severity error;
        end case;

        -- end of simulation
        sim_end_s <= true;

        -- stop the process
        wait;

    end process; -- stimulus_proc

end testbench;
