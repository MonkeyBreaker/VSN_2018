

library common_lib;
use common_lib.logger_pkg;

package complex_comparator_pkg is
    generic(
        type data_type;
        function data_to_string(data : data_type) return string;
        function complex_compare(data1 : data_type; data2 : data_type) return boolean
    );

    procedure compare(logger : inout logger_pkg.logger_t; value1 : data_type; value2: data_type);

end complex_comparator_pkg;

package body complex_comparator_pkg is

    procedure compare(logger: inout logger_pkg.logger_t; value1 : data_type; value2: data_type) is
    begin
        -- TODO : Complete
    end compare;

end complex_comparator_pkg;
