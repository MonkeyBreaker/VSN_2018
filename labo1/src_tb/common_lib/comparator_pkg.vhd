
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
        if(true = compare(value1, value2)) then
            logger.log_note(LF & "val1 : " & LF & data_to_string(value1) & LF & "val2 : " & LF &
            data_to_string(value2) & LF & "are equal" & LF);
        else
            logger.log_error(LF & "val1 : " & LF & data_to_string(value1) & LF & "val2 : " & LF &
            data_to_string(value2) & LF & "are not equal" & LF);
        end if;
    end compare;


    function compare(value1 : data_type; value2: data_type) return boolean is
    begin
        return value1 = value2;
    end compare;

end comparator_pkg;
