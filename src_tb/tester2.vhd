

library project_lib;
context project_lib.project_ctx;

entity tester2 is

end tester2;

architecture fake of tester2 is

begin

    process is
    begin
        for i in 0 to 999 loop
            wait for 10 ns;
            logger.log_warning("tester2");
        end loop;

        wait;
    end process;

end fake;
