

use work.transactions_pkg.all;

library tlmvm;
use tlmvm.tlm_unbounded_fifo_pkg;

-- Create a specialized package that will offer unbounded FIFOs with the
-- specific user type of data in it
package input_transaction_fifo_pkg is new tlm_unbounded_fifo_pkg
    generic map (element_type => input_transaction_t);


use work.transactions_pkg.all;

library tlmvm;
use tlmvm.tlm_unbounded_fifo_pkg;

-- Create a specialized package that will offer unbounded FIFOs with the
-- specific user type of data in it
package input_transaction_fifo1_pkg is new tlm_unbounded_fifo_pkg
    generic map (element_type => input_transaction_t,
                 nb_max_data => 1);


use work.transactions_pkg.all;

library tlmvm;
use tlmvm.tlm_unbounded_fifo_pkg;

package output_transaction_fifo_pkg is new tlm_unbounded_fifo_pkg
    generic map (element_type => output_transaction_t);
