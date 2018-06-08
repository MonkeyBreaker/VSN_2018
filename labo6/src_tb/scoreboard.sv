`ifndef SCOREBOARD_SV
`define SCOREBOARD_SV

`include "state.sv"

class Scoreboard;

    int testcase;

    ble_fifo_t sequencer_to_scoreboard_fifo;
    usb_fifo_t monitor_to_scoreboard_fifo;

    int ble_packets_counter = 0;
    int ble_valid_packets_counter = 0;
    mailbox #(BlePacket) ble_fifo_per_channel [0:39];

    int usb_packets_counter = 0;

    int address_advertasized [0:15];
    int index_tab_address_advertasized = 0;
    int nb_bad_packets = 0;

    //Function to check packet (ble & usb) is valid
    //  return 0 -> false
    //         1 -> true
    function bit compare_ble_and_usb_packet(input BlePacket ble, input AnalyzerUsbPacket usb);
      bit result = 1;

      int size_excepted_on_usb = (ble.sizeToSend-(16+32+8))/8 + 10;

      logic[15:0] header_on_ble = ble.size;

      logic [`ble_max_data_size*8-1:0] data_on_ble = 0;
      bit [`ble_max_data_size-1:0][7:0] data_on_usb = 0;
      int size_octets_data_on_usb = usb.usb_generic.usb_packet.size-10;

      for(int i=0;i<(ble.sizeToSend-(8+32+16));i++)
        data_on_ble[i] = ble.dataToSend[i];

      for(int i = 0 ; i < size_octets_data_on_usb ; i++)
        data_on_usb[size_octets_data_on_usb-1-i] = usb.usb_generic.usb_packet.data[(`ble_max_data_size-1)-i];

      // Correct data on the usb packets
      //usb.usb_generic.usb_packet.rssi++; // I don't know why there's a difference of 1 between expected and the value get
      usb.usb_generic.usb_packet.header  = ((usb.usb_generic.usb_packet.header & 16'h00ff) << 8) | ((usb.usb_generic.usb_packet.header & 16'hFF00) >> 8);
      usb.usb_generic.usb_packet.address = ((usb.usb_generic.usb_packet.address & 32'h0FF) << 24) | ((usb.usb_generic.usb_packet.address & 32'hFF000000) >> 24) |
                                           ((usb.usb_generic.usb_packet.address & 32'h0FF00) << 8) | ((usb.usb_generic.usb_packet.address & 32'h00FF0000) >> 8) ;
      usb.usb_generic.usb_packet.channel /= 2;

      //Check size of packet
      if(size_excepted_on_usb != usb.usb_generic.usb_packet.size) begin
        $display("[ERROR] [SCOREBOARD] Size packet invalid ! (excepted : %d, actual : %d)", size_excepted_on_usb, usb.usb_generic.usb_packet.size);
        result = 0;
      end

      //Check Rssi of packet
      if(!(((usb.usb_generic.usb_packet.rssi-5) < ble.rssi) && (ble.rssi < (usb.usb_generic.usb_packet.rssi+5)))) begin
        $display("[ERROR] [SCOREBOARD] rssi of packet is not valid! (excepted : %d, actual : %d)", ble.rssi, usb.usb_generic.usb_packet.rssi);
        result = 0;
      end

      //Check if is a advertising packet
      if(ble.isAdv != usb.usb_generic.usb_packet.isAdv) begin
        $display("[ERROR] [SCOREBOARD] advertising of packet is not valid! (excepted : %d, actual : %d)", ble.isAdv, usb.usb_generic.usb_packet.isAdv);
        result = 0;
      end

      //Check channel of packet
      if(ble.channel != usb.usb_generic.usb_packet.channel) begin
        $display("[ERROR] [SCOREBOARD] channel of packet is not valid! (excepted : %d, actual : %d)", ble.channel, usb.usb_generic.usb_packet.channel);
        result = 0;
      end

      //Check address of packet
      if(ble.addr != usb.usb_generic.usb_packet.address) begin
        $display("[ERROR] [SCOREBOARD] address of packet is not valid! (excepted : 0x%h, actual : 0x%h)", ble.addr, usb.usb_generic.usb_packet.address);
        result = 0;
      end

      //Check header of packet
      if(header_on_ble != usb.usb_generic.usb_packet.header) begin
        $display("[ERROR] [SCOREBOARD] header of packet is not valid! (excepted : 0x%h, actual : 0x%h)", header_on_ble, usb.usb_generic.usb_packet.header);
        result = 0;
      end

      //Check data if packet
      if(data_on_ble != data_on_usb) begin
        $display("[ERROR] [SCOREBOARD] data of packet is not valid! (excepted : 0x%h, actual : 0x%h)", data_on_ble, data_on_usb);
        result = 0;
      end

      //Show content of packet (ble & usb) when packet is not valid
      if(result == 0) begin
        $display("[ERROR] [SCOREBOARD] %s", ble.psprint());
        $display("[ERROR] [SCOREBOARD] %s", usb.psprint());
      end
      else
        $display("[INFO] [SCOREBOARD] Valid usb packet");

      return result;
    endfunction

    function bit address_is_advertasized(input int address);
      bit result = 0;

      for(int i = 0; i < 16; i++) begin
        if(address_advertasized[i] == address)
          result=1;
      end

      return result;
    endfunction

    task check_sequencer;
      automatic BlePacket ble_packet = new;
      int channel;

      // Loop as long as the sequencer has not finished or a packets remains in the fifo
      while(!sequencer_finish || sequencer_to_scoreboard_fifo.num()) begin
        if(sequencer_to_scoreboard_fifo.try_get(ble_packet)) begin

          if(ble_packet.isAdv) begin
            address_advertasized[index_tab_address_advertasized] = ble_packet.advertasing_address;
            index_tab_address_advertasized++;
            index_tab_address_advertasized%=16; // index_tab_address_advertasized => 0 -> 15
          end

          if(address_is_advertasized(ble_packet.addr) || ble_packet.isAdv) begin
            channel = ble_packet.channel;
            $display("[INFO] [SCOREBOARD] Packet received from sequencer, channel : %d", channel);
            ble_valid_packets_counter++;
            ble_packet.channel = channel;
            ble_fifo_per_channel[ble_packet.channel].put(ble_packet);
            ble_packet = new;
          end
          else begin
            ble_packets_counter++;
            $display("[INFO] [SCOREBOARD] Packet address not advertize, packed drop : %d", ble_packet.addr);
          end;
        end
        else begin
          // Wait a clock
          #1;
        end
      end

      $display("[INFO] [SCOREBOARD] All packets received from the sequencer");

    endtask : check_sequencer

    task check_monitor;
      automatic AnalyzerUsbPacket usb_packet = new;
      automatic BlePacket ble_packet = new;
      automatic int timeout = 0;

      // Loop as long as the sequencer has not finished or a packets remains in the fifo
      while(!monitor_finish || monitor_to_scoreboard_fifo.num()) begin
        if(monitor_to_scoreboard_fifo.try_get(usb_packet)) begin
          $display("[INFO] [SCOREBOARD] Packet received from monitor, channel : %d", usb_packet.usb_generic.usb_packet.channel);
          ble_fifo_per_channel[usb_packet.usb_generic.usb_packet.channel/2].get(ble_packet);
          usb_packets_counter++;

          // If the packet has an error, increment the error counter
          if(!compare_ble_and_usb_packet(ble_packet , usb_packet))
            nb_bad_packets++;
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

        for(int i = 0; i < 40; i++)
          ble_fifo_per_channel[i] = new();

        for(int i = 0; i < 16; i++)
          address_advertasized[i] = 0;

        fork
          check_sequencer();
          check_monitor();
        join;

        if(ble_valid_packets_counter != usb_packets_counter)
          $display("[INFO] [ERROR] All packets send to the DUT where not received via USB, number remaining");
          $display("[INFO] [ERROR] BLE Packets : %d", ble_packets_counter);
          $display("[INFO] [ERROR] BLE Packets : %d", usb_packets_counter);

        $display("[INFO] [SCOREBOARD] : End");
    endtask : run

endclass : Scoreboard

`endif // SCOREBOARD_SV
