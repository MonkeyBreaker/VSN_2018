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
    * This task sends a data packet
    */
    task send_data_packet(int channel, int data_device_addr);
      automatic BlePacket packet_data;

      packet_data = new;
      packet_data.isAdv = 0; // Set as "data" packet
      packet_data.data_device_addr = data_device_addr; // Set the address we have advertized just before
      void'(packet_data.randomize());

      if(channel != -1)
        packet_data.channel = channel;

      //Send to driver and scoreboard
      sequencer_to_driver_fifo.put(packet_data);
      sequencer_to_scoreboard_fifo.put(packet_data);
      nb_packets_generated++;

      $display("[INFO] [SEQUENCER] [AD N:%d] %s", packet_counter,packet_data.psprint());
      //$display("[INFO] [SEQUENCER] [AD N:%d] Sent an advertising packet on channel %d, for the device 0x%h with dataToSend: 0x%h",
      //packet_counter, packet_advertising.channel, packet_advertising.advertasing_address, packet_advertising.dataToSend);

       //Count how many packet we sent
      packet_counter = packet_counter + 1;
    endtask

    /**
    * This task sends an advertasing packet, it outputs the address advertized
  * The channel need to be specified because of the implementation of the sequencer, this prevent to send consecutively two advertising on the same channel
    */
    task send_advertizing_packet(int channel, output int address_advertasized);
      automatic BlePacket packet_advertising;

      packet_advertising = new;
      packet_advertising.isAdv = 1; // Set as "advertizing" packet
      void'(packet_advertising.randomize());

      if(channel != -1)
        packet_advertising.channel = channel;

      //Send to driver and scoreboard
      sequencer_to_driver_fifo.put(packet_advertising);
      sequencer_to_scoreboard_fifo.put(packet_advertising);
      nb_packets_generated++;

      $display("[INFO] [SEQUENCER] [AD N:%d] %s", packet_counter,packet_advertising.psprint());
      //$display("[INFO] [SEQUENCER] [AD N:%d] Sent an advertising packet on channel %d, for the device 0x%h with dataToSend: 0x%h",
      //packet_counter, packet_advertising.channel, packet_advertising.advertasing_address, packet_advertising.dataToSend);

      //Count how many packet we sent
      packet_counter = packet_counter + 1;

      // get the address advertasized
      address_advertasized = packet_advertising.advertasing_address;
    endtask

    /**
    * This task sends data randomly without advertising
    */
    task noise_packet_generator(int nb_packets);
       for(int i=0;i<nb_packets;i++) begin
         send_data_packet(-1,$random);
       end
    endtask

    /*
    * This testcase advertized and then send 10 valid packets
    */
    task testcase0();
         int address_advertasized;
         //----------------------------------------------------
         //Send an advertizing packet
         //----------------------------------------------------
         send_advertizing_packet(-1, address_advertasized);
         nb_valid_packets_generated++;

         // Needeed to ensure that all the addresses are advertaized
         for(int i = 0; i < 1000; i++) begin
           #10;
         end

         for(int i=0;i<10;i++) begin

             //----------------------------------------------------
             //Send a data packet with the corresponding advertising address
             //----------------------------------------------------
             send_data_packet(-1, address_advertasized);
             nb_valid_packets_generated++;
         end
     endtask

     /*
     * This testcase First generates some noise and then advertized for 10 valid packets
     */
     task testcase1();
         noise_packet_generator(10);
         testcase0();
     endtask

     /*
      * This testcase only generate 2 advertazing and then send packets over the 2 advertized address
     */
     task testcase2();
       noise_packet_generator(20);
     endtask

     task testcase3();
       int address_advertasized_1;
       int address_advertasized_2;
       //----------------------------------------------------
       //Send an advertizing packet
       //----------------------------------------------------
       send_advertizing_packet(0, address_advertasized_1);
       nb_valid_packets_generated++;
       send_advertizing_packet(12, address_advertasized_2);
       nb_valid_packets_generated++;

       // Needeed to ensure that all the addresses are advertaized
       for(int i = 0; i < 1000; i++) begin
         #10;
       end


       for(int i=0;i<20;i++) begin

           //----------------------------------------------------
           //Send a data packet with the corresponding advertising address
           //----------------------------------------------------
           // Send alternatively one packet with a valid adress and then another with another valid address
           send_data_packet(-1, (i%2) ? address_advertasized_1 : address_advertasized_2);
           nb_valid_packets_generated++;
       end
     endtask

     /*
      * This testcase only generate a packet advertize and the generete 10 Packets
      * that the channel only increase, these validate the ERRNO 1
     */
     task testcase4();
       int address_advertasized;
       //----------------------------------------------------
       //Send an advertizing packet
       //----------------------------------------------------
       send_advertizing_packet(0, address_advertasized);
       nb_valid_packets_generated++;

       //----------------------------------------------------
       //Send a data packet with the corresponding advertising address
       //----------------------------------------------------
       for(int i = 0; i < 10; i++) begin
         send_data_packet(i+1, address_advertasized);
         nb_valid_packets_generated++;
       end
     endtask

     /*
      * This testcase checks that the DUT drop effectively the last advertsaing after 16 address are stored
     */
     task testcase5();
       int address_advertasized_first;
       int address_advertasized;
       //----------------------------------------------------
       //Send an advertizing packet
       //----------------------------------------------------
       send_advertizing_packet(-1, address_advertasized_first);
       nb_valid_packets_generated++;

       // Send 16 advertazing packets to drop the first packet
       for(int i = 0; i < 16; i++) begin
        send_advertizing_packet(-1, address_advertasized);
        nb_valid_packets_generated++;
       end

       // Needeed to ensure that all the addresses are advertaized
       for(int i = 0; i < 100000; i++) begin
         #10;
       end

       // This packet will be droped, the address wil not be advertasized
       send_data_packet(-1, address_advertasized_first);
       //----------------------------------------------------
       //Send a data packet with the corresponding advertising address
       //----------------------------------------------------
       for(int i = 0; i < 10; i++) begin
         send_data_packet(i+1, address_advertasized);
         nb_valid_packets_generated++;
       end
     endtask

     /*
      * Bad channel for the advertasing packet
     */
     task testcase6();
       int address_advertasized;
       //----------------------------------------------------
       //Send an advertizing packet
       //----------------------------------------------------
       send_advertizing_packet(9, address_advertasized);

       //----------------------------------------------------
       //Send a data packet with the corresponding advertising address
       //----------------------------------------------------
       for(int i = 0; i < 1; i++) begin
         send_data_packet(-1, address_advertasized);
       end
     endtask

     /*
      * Bad channel for the data packet
     */
     task testcase7();
       int address_advertasized;
       //----------------------------------------------------
       //Send an advertizing packet
       //----------------------------------------------------
       send_advertizing_packet(-1, address_advertasized);
       nb_valid_packets_generated++;

       //----------------------------------------------------
       //Send a data packet with the corresponding advertising address
       //----------------------------------------------------
       send_data_packet(0, address_advertasized);
       for(int i = 0; i < 10; i++) begin
         send_data_packet(-1, address_advertasized);
         nb_valid_packets_generated++;
       end
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
         else if (3 == testcase)
             testcase3();
         else if (4 == testcase)
             testcase4();
         else if (5 == testcase)
             testcase5();
         else if (6 == testcase)
             testcase6();
         else if (7 == testcase)
             testcase7();
         else begin
             testcase0();
             testcase1();
             testcase2();
             testcase3();
             testcase4();
             testcase5();
             testcase6();
             testcase7();
         end

         sequencer_finish = 1;

       $display("[INFO] [SEQUENCER] Packets generated : %d", nb_packets_generated);
       $display("[INFO] [SEQUENCER] end");
     endtask : run

endclass : Sequencer


`endif // SEQUENCER_SV
