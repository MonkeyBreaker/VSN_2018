
library common_lib;
context common_lib.common_ctx;


library project_lib;
use project_lib.transactions_pkg.all;

package transaction_lazy_comparator_pkg is new complex_comparator_pkg
    generic map (
        data_type       => transaction_t,
        data_to_string  => transaction_to_string,
        complex_compare => lazy_compare
    );
