`ifndef SEQUENCER_SV
`define SEQUENCER_SV

`include "state.sv"

class Sequencer;

    int testcase;
    int packet_counter = 0;

    ble_fifo_t sequencer_to_driver_fifo;
    ble_fifo_t sequencer_to_scoreboard_fifo;

    int nb_packets_generated = 0;
    int nb_valid_packets_generated = 0;

    /**
    * This task sends data randomly without advertising
    */
    task noise_packet_generator(int nb_packets);
       automatic BlePacket packet_advertising;
       automatic BlePacket packet_data;

       for(int i=0;i<nb_packets;i++) begin
          packet_data = new;
          nb_packets_generated++;
          packet_data.isAdv = 0; // Set as "data" packet
          packet_data.data_device_addr = $random;
          void'(packet_data.randomize());

          //Send to driver and scoreboard
          sequencer_to_driver_fifo.put(packet_data);
          sequencer_to_scoreboard_fifo.put(packet_data);

        $display("[INFO] [SEQUENCER] [Packet N:%d] sent a data packet on channel %d, for the device 0x%h with a dataToSend: 0x%h",
               packet_counter, packet_data.channel, packet_data.data_device_addr, packet_data.dataToSend);
       end
    endtask

    task testcase0();
         automatic BlePacket packet_advertising;
         automatic BlePacket packet_data;

         // We generate x pairs of advertizing + data packets which are sent in the right order to the DUT using driver + fifo.
         // With that example, we should not have problems of data packets without prior advertising,... => we should get 20 valid packets on the USB side.

         //----------------------------------------------------
         //Send an advertizing packet
         //----------------------------------------------------
         packet_advertising = new;
         nb_valid_packets_generated++;
         packet_advertising.isAdv = 1; // Set as "advertizing" packet
         void'(packet_advertising.randomize());

         //Send to driver and scoreboard
         sequencer_to_driver_fifo.put(packet_advertising);
         sequencer_to_scoreboard_fifo.put(packet_advertising);

         $display(packet_advertising.psprint());
         $display("[INFO] [SEQUENCER] [AD N:%d] Sent an advertising packet on channel %d, for the device 0x%h with dataToSend: 0x%h",
         packet_counter, packet_advertising.channel, packet_advertising.advertasing_address, packet_advertising.dataToSend);

         //Count how many packet we sent
         packet_counter = packet_counter + 1;

         for(int i=0;i<10;i++) begin

             //----------------------------------------------------
             //Send a data packet with the corresponding advertising address
             //----------------------------------------------------
             packet_data = new;
             nb_valid_packets_generated++;
             packet_data.isAdv = 0; // Set as "data" packet
             packet_data.data_device_addr = packet_advertising.advertasing_address; // Set the address we have advertized just before
             void'(packet_data.randomize());

             //Send to driver and scoreboard
             sequencer_to_driver_fifo.put(packet_data);
             sequencer_to_scoreboard_fifo.put(packet_data);

             $display(packet_data.psprint());

             $display("[INFO] [SEQUENCER] [Packet N:%d] sent a data packet on channel %d, for the device 0x%h with a dataToSend: 0x%h",
                      packet_counter, packet_data.channel, packet_data.data_device_addr, packet_data.dataToSend);

             //Count how many packet we sent
             packet_counter = packet_counter + 1;
         end
     endtask

     task testcase1();
         automatic BlePacket packet_advertising;
         automatic BlePacket packet_data;

         noise_packet_generator(10);
         //----------------------------------------------------
         //Send an advertizing packet
         //----------------------------------------------------
         packet_advertising = new;
         nb_valid_packets_generated++;
         packet_advertising.isAdv = 1; // Set as "advertizing" packet
         void'(packet_advertising.randomize());

         //Send to driver and scoreboard
         sequencer_to_driver_fifo.put(packet_advertising);
         sequencer_to_scoreboard_fifo.put(packet_advertising);

         $display("[INFO] [SEQUENCER] [AD N:%d] Sent an advertising packet on channel %d, for the device 0x%h with dataToSend: 0x%h",
         packet_counter, packet_advertising.channel, packet_advertising.advertasing_address, packet_advertising.dataToSend);

         //Count how many packet we sent
         packet_counter = packet_counter + 1;

         for(int i=0;i<10;i++) begin
             //----------------------------------------------------
             //Send a data packet with the corresponding advertising address
             //----------------------------------------------------
             packet_data = new;
             nb_valid_packets_generated++;
             // Data packet
             packet_data.isAdv = 0;
            // Set the address we have advertized just before
             packet_data.data_device_addr = packet_advertising.advertasing_address;
             void'(packet_data.randomize());

             //Send to driver and scoreboard
             sequencer_to_driver_fifo.put(packet_data);
             sequencer_to_scoreboard_fifo.put(packet_data);

             // $display("[INFO] [SEQUENCER] [Packet N:%d] sent a data packet on channel %d, for the device 0x%h with a dataToSend: 0x%h",
             //        packet_counter, packet_data.channel, packet_data.data_device_addr, packet_data.dataToSend);

             $display("[INFO] [SEQUENCER] %s", packet_data.psprint());

             //Count how many packet we sent
             packet_counter = packet_counter + 1;
         end
     endtask

     task testcase2();
       noise_packet_generator(20);
     endtask

     // Programme lancé au démarrage de la simulation
     task run;
         $display("[INFO] [SEQUENCER] start, test case number : %d", testcase);

         if (0 == testcase)
             testcase0();
         else if (1 == testcase)
             testcase1();
         else if (2 == testcase)
             testcase2();

         sequencer_finish = 1;
         nb_packets_generated += nb_valid_packets_generated;

       $display("[INFO] [SEQUENCER] Packets generated : %d", nb_packets_generated);
       $display("[INFO] [SEQUENCER] end");
     endtask : run

endclass : Sequencer


`endif // SEQUENCER_SV
