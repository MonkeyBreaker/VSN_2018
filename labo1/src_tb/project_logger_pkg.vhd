
library common_lib;
context common_lib.common_ctx;

package project_logger_pkg is

    -- Simply exports a logger that can be used accross entities
    shared variable logger : common_lib.logger_pkg.logger_t;

end project_logger_pkg;
