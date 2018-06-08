`ifndef MONITOR_SV
`define MONITOR_SV


class Monitor;

    int testcase;

    virtual usb_itf vif;

    usb_fifo_t monitor_to_scoreboard_fifo;

    int nb_packets_received_from_dut = 0;
    int nb_packets_send_to_scoreboard = 0;

    task run;
        AnalyzerUsbPacket usb_packet = new;
        int i;
        int timeout;

        // frame_o state -> to detect edges (rising and falling)
        logic current_state = 0;
        logic previous_state = 0;
        $display("[INFO] [MONITOR] : start");

        //usb_generic_t usb_packet = new;

        while (1) begin
          previous_state = current_state;
          current_state = vif.frame_o;

          // Rising edge
          if (current_state && !previous_state) begin
            $display("[INFO] [MONITOR] Packet detected");
            nb_packets_received_from_dut++;
            usb_packet = new;
            i=0;
          end

          // Falling edge
          if (!current_state && previous_state) begin
            $display("[INFO] [MONITOR] Packet send to Scoreboard");
            nb_packets_send_to_scoreboard++;
            monitor_to_scoreboard_fifo.put(usb_packet);
          end

          // Both are High
          if (current_state) begin
            if (vif.valid_o) begin
              usb_packet.usb_generic.usb_packets_bits[i] = vif.data_o;
              i++;
            end;
          end;

          // If there data no the bus, maybe the sequencer ended
          if (current_state || previous_state) begin
            timeout = 0;
          end

          // If the driver finished and a timeout occurred, it can be concluded
          // that all the data was sent to the monitor
          if (driver_finish) begin
            if (timeout > 1500) begin
              break;
            end
            else begin
              timeout++;
            end
          end

          @(posedge vif.clk_i);
        end;

    monitor_finish = 1;

    $display("[INFO] [MONITOR] Packets received from dut : %d", nb_packets_received_from_dut);
    $display("[INFO] [MONITOR] Packets sent to scoreboard : %d", nb_packets_send_to_scoreboard);
    $display("[INFO] [MONITOR] : end");
    endtask : run

endclass : Monitor

`endif // MONITOR_SV
