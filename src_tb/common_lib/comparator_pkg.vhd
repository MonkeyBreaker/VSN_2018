
library common_lib;
use common_lib.logger_pkg;

package comparator_pkg is
    generic(
        type data_type;
        function data_to_string(data : data_type) return string
    );

    procedure compare(logger : inout logger_pkg.logger_t; value1 : data_type; value2: data_type);

    function compare(value1 : data_type; value2: data_type) return boolean;

end comparator_pkg;

package body comparator_pkg is

    procedure compare(logger: inout logger_pkg.logger_t; value1 : data_type; value2: data_type) is
    begin
        -- TODO : Complete
    end compare;


    function compare(value1 : data_type; value2: data_type) return boolean is
    begin
        -- TODO : Complete
    end compare;

end comparator_pkg;
