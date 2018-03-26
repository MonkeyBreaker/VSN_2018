
context project_ctx is -- To be compiled in project_lib

    library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    library common_lib;
    use project_lib.project_logger_pkg.all;

end context project_ctx;
