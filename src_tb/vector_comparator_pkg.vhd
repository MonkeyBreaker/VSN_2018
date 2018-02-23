
library common_lib;
context common_lib.common_ctx;

package vector_comparator_pkg is new comparator_pkg
    generic map (
        data_type      => std_logic_vector,
        data_to_string => to_string
    );
