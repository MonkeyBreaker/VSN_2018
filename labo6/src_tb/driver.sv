`ifndef DRIVER_SV
`define DRIVER_SV

`include "state.sv"

class Driver;

    int testcase;

    ble_fifo_t sequencer_to_driver_fifo;

    // This variable is used to save the packets received from the sequencer
    BlePacket ble_packets_channels [0:39];
    ble_fifo_t ble_packets_fifo = new();

    int bits_to_send[0:39];

    int nb_packets_to_process;
    int nb_packets_received_from_sequencer = 0;
    int nb_packets_sent_to_dut = 0;

    virtual ble_itf vif;

    `define packet_channel_invalid (41)

    task send_packet_bit(BlePacket packet);
      vif.valid_i <= 1;

      // Decraement before sending,
      bits_to_send[packet.channel] = bits_to_send[packet.channel] - 1;

      vif.serial_i <= packet.dataToSend[bits_to_send[packet.channel]];
      // The driver need to send values from 0 -> 78 (only even values)
      vif.channel_i <= packet.channel*2;
      // Generate different values of rssi just for check after the mean
      // value returned by the DUT
      vif.rssi_i <= packet.rssi;


      @(posedge vif.clk_i);

      // Check that there are remaining bit to send
      if(0 == bits_to_send[packet.channel]) begin
        // All the bits of the packet were send
      $display("[INFO] [DRIVER] Complete packet send, on channel %d", packet.channel);
        nb_packets_sent_to_dut++;
        packet = new;
        packet.channel = `packet_channel_invalid;
        nb_packets_to_process = nb_packets_to_process-1;
      end

    endtask

    task clear_and_wait();
      // Wait clk between after frame sent to dut
      // All the inputs signals are reset
      // vif.serial_i <= 1;
      vif.valid_i <= 0;
      vif.channel_i <= 0;
      // vif.rssi_i <= 0;
      @(posedge vif.clk_i);
    endtask

    task run;
        automatic BlePacket packet;
        packet = new;
        $display("[INFO] [DRIVER] : start");

        vif.serial_i <= 0;
        vif.valid_i <= 0;
        vif.channel_i <= 0;
        vif.rssi_i <= 0;
        vif.rst_i <= 1;
        @(posedge vif.clk_i);
        vif.rst_i <= 0;
        @(posedge vif.clk_i);
        @(posedge vif.clk_i);

        nb_packets_to_process = 0;

        for(int i=0; i < $size(ble_packets_channels); i++) begin
          ble_packets_channels[i] = new;
          ble_packets_channels[i].channel = `packet_channel_invalid;
        end

        while(1) begin

            // Try to get a packet
            // If not packet could be read, the function returns 0
            if(0 != sequencer_to_driver_fifo.try_get(packet)) begin
              // If the channel has already a packet, drop the new packet
              nb_packets_received_from_sequencer++;

              $display("[INFO] [DRIVER] I got a packet, channel : %d, size bytes : %d", packet.channel, (packet.sizeToSend - 1)/8);

              if(`packet_channel_invalid == ble_packets_channels[packet.channel].channel) begin
                nb_packets_to_process += 1;
                
                // Saves the packet at the corresponding channel to send
                ble_packets_channels[packet.channel] = packet;
                bits_to_send[packet.channel] = packet.sizeToSend - 1;
              end
              else begin
                $display("[INFO] [DRIVER] Channel already used, the packed is store");
                ble_packets_fifo.put(packet);
              end
            end

            if(0 < nb_packets_to_process) begin
              // Check the 40 channels and send a bit if the channel is valid
              for(int i=0; i < $size(ble_packets_channels); i++) begin
                // send a bit if the channel is a valid one
                if(`packet_channel_invalid != ble_packets_channels[i].channel) begin
                  if(i == ble_packets_channels[i].channel) begin
                    send_packet_bit(ble_packets_channels[i]);
                    clear_and_wait();
                  end
                  else begin
                    $display("[ERROR] [DRIVER] The channel is currently busy");
                    ble_packets_channels[i].channel = `packet_channel_invalid;
                  end
                end
              end
            end
            else begin

              if (!ble_packets_fifo.num()) begin
                // If all the packets sent from the sequencer are sent, finish the driver
                if (sequencer_finish) begin
                  break;
                end
              end
              else begin
                nb_packets_to_process++;
                ble_packets_fifo.get(packet);

                ble_packets_channels[packet.channel] = packet;
                bits_to_send[packet.channel] = packet.sizeToSend - 1;
                $display("[INFO] [DRIVER] A packet will be retrieve, channel : %d, size bytes : %d", packet.channel, bits_to_send[packet.channel]/8);
              end

              @(posedge vif.clk_i);
            end
        end

      driver_finish = 1; //nb_packets_sent_to_dut
      $display("[INFO] [DRIVER] Number of packets received from sequencer : %d", nb_packets_received_from_sequencer);
      $display("[INFO] [DRIVER] Number of packets sent to dut : %d", nb_packets_sent_to_dut);
      $display("[INFO] [DRIVER] : end");
    endtask : run

endclass : Driver



`endif // DRIVER_SV
