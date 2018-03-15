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

library project_lib;
context project_lib.project_ctx;
library osvvm;
use osvvm.all;
use osvvm.RandomPkg.all;

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
        ERRNO : integer := 0
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

      -- Inputs to the FIFO.
    type t_result is record
      result    : integer;
      carry     : std_logic;
    end record t_result;

    constant MAX_POSITIVE_VALUE : integer := ((2**SIZE)/2)-1;
    constant MAX_NEGATIVE_VALUE : integer := -((2**SIZE)/2);

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

    -- methods
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

    impure function get_signed_vector(nb : integer; length : integer) return std_logic_vector is
    begin
      return std_logic_vector(to_signed(nb, length));
    end get_signed_vector;

    impure function get_integer_signed_value(val: std_logic_vector) return integer is
    begin
      return to_integer(signed(val));
    end get_integer_signed_value;

    -- This function returns the values expected by the ALU, it's implemented from the specification
    impure function get_correct_result(a : integer; b : integer; operator : operator_enum) return t_result is
      variable record_results : t_result;
      variable a_signed_vector : std_logic_vector(SIZE downto 0) := '0' & get_signed_vector(a, SIZE);
      variable b_signed_vector : std_logic_vector(SIZE downto 0) := '0' & get_signed_vector(b, SIZE);
      variable carry           : std_logic_vector(SIZE   downto 0);
    begin
      record_results.carry := '0';

      case operator is
        when add =>
            carry := std_logic_vector(unsigned(a_signed_vector) +  unsigned(b_signed_vector));
            record_results.carry := carry(SIZE);
            record_results.result := get_integer_signed_value(carry(SIZE-1 downto 0));
        when sub =>
            carry := std_logic_vector(unsigned(a_signed_vector) -  unsigned(b_signed_vector));
            record_results.carry := carry(SIZE);
            record_results.result := get_integer_signed_value(carry(SIZE-1 downto 0));
        when op_or =>
            record_results.result := get_integer_signed_value(get_signed_vector(a, a_sti'length) or get_signed_vector(b, b_sti'length));
        when op_and =>
            record_results.result := get_integer_signed_value(get_signed_vector(a, a_sti'length) and get_signed_vector(b, b_sti'length));
        when get_first_arg =>
            record_results.result := a;
        when get_second_arg =>
            record_results.result := b;
        when first_bit_test =>
            if a = b then
              record_results.result := 1;
            else
              record_results.result := 0;
            end if;
        when others =>
            record_results.result := 0;
      end case;

      return record_results;
    end get_correct_result;

    -- Generate stimulus for the
    procedure generate_input(a : integer; b : integer; mode : in operator_enum) is
    begin
      a_sti <= get_signed_vector(a, a_sti'length);
      b_sti <= get_signed_vector(b, b_sti'length);
      mode_sti <= get_operator(mode);
      wait for 10 ns;
    end generate_input;

    impure function verification_result(alu_value : t_result; correct_value: t_result; operator : operator_enum) return boolean is
    begin
      case operator is
        when add =>
            if (correct_value.result = alu_value.result) and (correct_value.carry=alu_value.carry) then
              return true;
            else
              return false;
            end if;
        when sub =>
            if (correct_value.result = alu_value.result) and (correct_value.carry=alu_value.carry) then
              return true;
            else
              return false;
            end if;
        when first_bit_test =>
            if get_signed_vector(alu_value.result, SIZE)(0) = get_signed_vector(correct_value.result, SIZE)(0) then
              return true;
            else
              return false;
            end if;
        when others =>
            return alu_value.result=correct_value.result;
      end case;
    end verification_result;

    procedure test(a : integer; b : integer; mode : operator_enum) is
      variable alu_result : t_result;
      variable correct_result : t_result;
    begin

      -- Check if the value is in range
      if(a <= MAX_POSITIVE_VALUE) and (b <= MAX_POSITIVE_VALUE) and (a >= MAX_NEGATIVE_VALUE) and (b >= MAX_NEGATIVE_VALUE) then
        -- Generate a stimulus on the ALU
        generate_input(a, b, mode);

        -- get the correct values that correspond the specification of the ALU
        correct_result := get_correct_result(a, b, mode);

        -- Assign returned values from the ALU to a record
        alu_result.result := get_integer_signed_value(s_obs);
        alu_result.carry :=c_obs;

        if(verification_result(alu_result, correct_result, mode) = true) then
          logger.log_note("Good : " & integer'image(a) & " " & to_string(mode) & " " & integer'image(b)
                          & " [ALU|TB] : ["  & integer'image(get_integer_signed_value(s_obs)) & "|"
                          & integer'image(correct_result.result) & "] carry ["
                          & to_string(c_obs) & "|"
                          & to_string(correct_result.carry) & "] "
                          & to_string(mode));
        else
          logger.log_error("Wrong : " & integer'image(a) & " " & to_string(mode) & " " & integer'image(b)
                          & " [ALU TB] : ["  & integer'image(get_integer_signed_value(s_obs)) & "|"
                          & integer'image(correct_result.result) & "] carry ["
                          & to_string(c_obs) & "|"
                          & to_string(correct_result.carry) & "] "
                          & to_string(mode));
        end if;
      else
          logger.log_error("Input(s) parameter out of bounds, range : [" & integer'image(MAX_NEGATIVE_VALUE)
                          & ";" & integer'image(MAX_POSITIVE_VALUE) & "]");
      end if;
    end test;

    procedure print_supported_values is
    begin
      logger.log_note("Input range values : [" & integer'image(MAX_NEGATIVE_VALUE)
                      & ";" & integer'image(MAX_POSITIVE_VALUE) & "]" & LF);
    end print_supported_values;

    procedure testcase1 is
    begin
      test(0,MAX_NEGATIVE_VALUE,add);
      test(0,MAX_POSITIVE_VALUE,add);
      test(MAX_NEGATIVE_VALUE,0,add);
      test(MAX_POSITIVE_VALUE,0,add);
      test(MAX_NEGATIVE_VALUE,MAX_NEGATIVE_VALUE,add);
      test(MAX_POSITIVE_VALUE,MAX_POSITIVE_VALUE,add);
      test(MAX_NEGATIVE_VALUE,1,sub);
      test(MAX_POSITIVE_VALUE,1,sub);
      test(MAX_NEGATIVE_VALUE,MAX_NEGATIVE_VALUE,sub);
      test(MAX_NEGATIVE_VALUE,MAX_POSITIVE_VALUE,sub);
      test(MAX_POSITIVE_VALUE,MAX_POSITIVE_VALUE,sub);
      test(MAX_POSITIVE_VALUE,MAX_NEGATIVE_VALUE,sub);
    end testcase1;

    -- test 1000 random values
    procedure testcase2 is
      variable var_rand_a : RandomPType;
    begin
      var_rand_a.InitSeed(var_rand_a'instance_name);
      for i in 0 to 999 loop
        test(var_rand_a.Uniform(MAX_NEGATIVE_VALUE,MAX_POSITIVE_VALUE), -- Random value for parameter a
        var_rand_a.Uniform(MAX_NEGATIVE_VALUE,MAX_POSITIVE_VALUE), -- Random value for parameter b
        operator_enum'VAL(var_rand_a.Uniform(0,7))); -- Random value for a mode
      end loop;
    end testcase2;

    begin

        -- Logger initialization
        logger.enable_write_on_file;
        logger.set_log_file_name("ALU_TB.txt");
        logger.set_severity_level(level => note);

        -- Print supported input values
        print_supported_values;

        -- a_sti    <= default_value;
        -- b_sti    <= default_value;
        -- mode_sti <= default_value;
        -- add, sub, op_or, op_and, get_first_arg, get_second_arg,first_bit_test, zero

        -- do something
        case TESTCASE is
            when 0      =>
              testcase1; -- test bounds pertinents case
            when 1 =>
              testcase2; -- test 1000 random values
            when 2 =>
              testcase1;
              testcase2;
            when others => logger.log_failure("Unsupported testcase : "
                                  & integer'image(TESTCASE));
        end case;

        -- end of simulation
        sim_end_s <= true;

        -- Summary and close logger
        logger.final_report;
        logger.close_file;

        -- stop the process
        wait;

    end process; -- stimulus_proc

end testbench;
