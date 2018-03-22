


library ieee;
use ieee.std_logic_1164.all;

package spike_detection_pkg is

    type port0_input_t is record
        sample               :  std_logic_vector(15 downto 0);
        sample_valid         :  std_logic;
        valid : std_logic;
    end record;

    type port0_output_t is record
        ready : std_logic;
    end record;


    type port1_output_t is record
        samples_spikes       : std_logic_vector(15 downto 0);
        samples_spikes_valid : std_logic;
        spike_detected       : std_logic;
    end record;

end spike_detection_pkg;
