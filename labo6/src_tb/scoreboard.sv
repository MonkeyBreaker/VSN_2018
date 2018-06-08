`ifndef SCOREBOARD_SV
`define SCOREBOARD_SV

`include "state.sv"

class Scoreboard;

    int testcase;

    ble_fifo_t sequencer_to_scoreboard_fifo;
    usb_fifo_t monitor_to_scoreboard_fifo;

    int ble_packets_counter = 0;
    ble_fifo_t ble_fifo_per_channel[0:39];

    int usb_packets_counter = 0;
    usb_fifo_t usb_fifo_per_channel[0:39];

    task check_sequencer;
      automatic BlePacket ble_packet = new;

      // Loop as long as the sequencer has not finished or a packets remains in the fifo
      while(!sequencer_finish || sequencer_to_scoreboard_fifo.num()) begin
        sequencer_to_scoreboard_fifo.get(ble_packet);
        $display("[INFO] [SCOREBOARD] Packet received from sequencer");
      end

      $display("[INFO] [SCOREBOARD] All packets received from the sequencer");

    endtask : check_sequencer

    task check_monitor;
      automatic AnalyzerUsbPacket usb_packet = new;
      automatic int timeout = 0;

      // Loop as long as the sequencer has not finished or a packets remains in the fifo
      while(!monitor_finish || monitor_to_scoreboard_fifo.num()) begin
        if(monitor_to_scoreboard_fifo.try_get(usb_packet)) begin
          $display("[INFO] [SCOREBOARD] Packet received from monitor");
        end
        else begin
          // Wait a clock
          #1;
        end
      end

      $display("[INFO] [SCOREBOARD] All packets received from the monitor");

    endtask : check_monitor

    task run;
        $display("[INFO] [SCOREBOARD] : Start");


        fork
          check_sequencer();
          check_monitor();
        join;

        $display("[INFO] [SCOREBOARD] : End");
    endtask : run

endclass : Scoreboard

`endif // SCOREBOARD_SV
