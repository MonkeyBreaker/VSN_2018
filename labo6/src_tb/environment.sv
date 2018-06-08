`ifndef ENVIRONMENT_SV
`define ENVIRONMENT_SV

`include "interfaces.sv"
class Environment;

    int testcase;

    Sequencer sequencer;
    Driver driver;
    Monitor monitor;
    Scoreboard scoreboard;

    virtual ble_itf input_itf;
    virtual usb_itf output_itf;

    ble_fifo_t sequencer_to_driver_fifo;
    ble_fifo_t sequencer_to_scoreboard_fifo;
    usb_fifo_t monitor_to_scoreboard_fifo;

    task build;
    sequencer_to_driver_fifo     = new(10);
    sequencer_to_scoreboard_fifo = new(10);
    monitor_to_scoreboard_fifo   = new(100);

    sequencer = new;
    driver = new;
    monitor = new;
    scoreboard = new;

    sequencer.testcase = testcase;
    driver.testcase = testcase;
    monitor.testcase = testcase;
    scoreboard.testcase = testcase;

    driver.vif = input_itf;
    monitor.vif = output_itf;

    sequencer.sequencer_to_driver_fifo = sequencer_to_driver_fifo;
    driver.sequencer_to_driver_fifo = sequencer_to_driver_fifo;

    sequencer.sequencer_to_scoreboard_fifo = sequencer_to_scoreboard_fifo;
    scoreboard.sequencer_to_scoreboard_fifo = sequencer_to_scoreboard_fifo;

    monitor.monitor_to_scoreboard_fifo = monitor_to_scoreboard_fifo;
    scoreboard.monitor_to_scoreboard_fifo = monitor_to_scoreboard_fifo;

    endtask : build

    task run;

        fork
            sequencer.run();
            driver.run();
            monitor.run();
            scoreboard.run();
        join;

    $display("\n\n");
    $display("\n\n");
    $display("\n\n");
    $display("------------------------------------------------------------");
    $display("------------ END -------------------------------------------");
    $display("------------------------------------------------------------");
    $display("Sequencer packets generated %d", sequencer.nb_packets_generated);
    $display("Sequencer valid packets generated %d", sequencer.nb_valid_packets_generated);
    $display("Driver received %d packets", driver.nb_packets_received_from_sequencer);
    $display("Driver send %d packets to DUT", driver.nb_packets_sent_to_dut);
    $display("Monitor received %d packets from DUT", monitor.nb_packets_received_from_dut);
    $display("Monitor send %d packets to Scoreboard", monitor.nb_packets_send_to_scoreboard);
    $display("Scoreboard received %d BLE packets", scoreboard.ble_valid_packets_counter);
    $display("Scoreboard received %d USB packets", scoreboard.usb_packets_counter);

    $display("\n");
    $display("------------------------------------------------------------");
    $display("------------ RESULTS ---------------------------------------");
    $display("------------------------------------------------------------");

    $display("Scoreboard compared %d USB vs BLE packets", scoreboard.usb_packets_counter);
    $display("valid packets : %d", scoreboard.usb_packets_counter-scoreboard.nb_bad_packets);
    $display("errors : %d", scoreboard.nb_bad_packets);

    $display("\n");
    if((sequencer.nb_valid_packets_generated != scoreboard.ble_valid_packets_counter) || (scoreboard.nb_bad_packets)) begin
      $display("Test bench failed !");
    end
    else begin
      $display("Test bench Success !");
    end
    $display("\n");

    $display("------------------------------------------------------------");

    endtask : run

endclass : Environment


`endif // ENVIRONMENT_SV
