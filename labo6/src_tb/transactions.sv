`ifndef TRANSACTIONS_SV
`define TRANSACTIONS_SV



/******************************************************************************
  Input transaction
******************************************************************************/
class BlePacket;

  `define ble_max_data_size (64)

  bit[(`ble_max_data_size*8+16+32+8):0] dataToSend;
  int sizeToSend;

  /* Champs generes aleatoirement */
  bit isAdv;
  bit dataValid = 1;
  bit[31:0] advertasing_address;
  rand bit[31:0] addr;
  rand bit[15:0] header;

  rand bit[(`ble_max_data_size*8):0] rawData;

  rand bit[5:0] size;
  rand bit[7:0] rssi;

  //In case of data packet only (do not care when advertising)
  // Device address for data packet... must have been advertised before. (according to BLE norm)
  // Not random because set in sequencer!
  int data_device_addr;

  //channel is random and constrained
  rand int channel;

  /* Ensure that the size of the packets is a valid one when randomize */
  constraint size_range {
    (isAdv == 1) -> size inside {[4:15]};
    (isAdv == 0) -> size inside {[0:63]};
  }

  constraint channel_range {
      // On BLE only half available channels are used
      (isAdv == 0) -> channel inside{[1:11], [13:38]};
      //Only the channels 0, 24, and 78 are used for advertising
      (isAdv == 1) -> channel inside{0, 12, 39};
  }


  function string psprint();
  $sformat(psprint, "BlePacket, isAdv : %b, addr= %h, channel= %d, rssi = %d,  SizeSend = %d, dataSend = %h",
                      this.isAdv, this.addr, this.channel, this.rssi,this.sizeToSend, this.dataToSend);
  endfunction : psprint

  function void post_randomize();

	  bit[7:0] preamble=8'h55;

	/* Initialisation des données à envoyer */
  	dataToSend = 0;
  	sizeToSend=size*8+16+32+8;


  	if (isAdv == 1) begin
  		addr = 32'h12345678;
  	end
    else if (isAdv == 0) begin
  	    addr = data_device_addr;
    end


  	/* Affectation des données à envoyer */
  	for(int i=0;i<8;i++)
   		dataToSend[sizeToSend-8+i]=preamble[i];

  	for(int i=0;i<32;i++)
  		dataToSend[sizeToSend-8-32+i]=addr[i];

    $display("Sending packet with address %h\n",addr);

    for(int i=0;i<16;i++)
  		dataToSend[sizeToSend-8-32-16+i]=0;

    for(int i=0;i<6;i++)
  		dataToSend[sizeToSend-8-32-16+i]=size[i];

    for(int i=0;i<size*8;i++)
  		dataToSend[sizeToSend-8-32-16-1-i]=rawData[size*8-1-i];

    if (isAdv) begin
        for(int i=0; i < 32; i++)
            advertasing_address[i] = dataToSend[sizeToSend-8-32-16-32+i];
        $display("Advertising with address %h\n",advertasing_address);
    end
  endfunction : post_randomize

endclass : BlePacket

class AnalyzerUsbPacket;
    `define usb_max_data_size ((64+10)) // 64 data + 10 header size in bytes

    typedef struct packed{
      bit[0:7] size;
      bit[0:7] rssi;
      bit[0:6] channel;
      bit isAdv;
      bit[0:7] reserved;
      bit[0:31] address;
      bit[0:15] header;
      bit [0:(`ble_max_data_size)-1][0:7] data;
    } usb_packet_t;

    union packed{
      usb_packet_t usb_packet;
      bit [0:(`usb_max_data_size)-1][7:0] usb_packets_bits;
    } usb_generic;

    //formatting data to be printed
    function string psprint();
      // $sformat(psprint, "UsbPacket, %h", this.usb_generic.usb_packets_bits);
      $sformat(psprint, "UsbPacket, size : %d, rssi= %h, channel = %d, isAdv = %d, address = %h,  header = %h, data = %h",
                                              this.usb_generic.usb_packet.size, this.usb_generic.usb_packet.rssi,
                                              this.usb_generic.usb_packet.channel, this.usb_generic.usb_packet.isAdv,
                                              this.usb_generic.usb_packet.address, this.usb_generic.usb_packet.header,
                                              this.usb_generic.usb_packet.data);
    endfunction : psprint

endclass : AnalyzerUsbPacket


typedef mailbox #(BlePacket) ble_fifo_t;

typedef mailbox #(AnalyzerUsbPacket) usb_fifo_t;

`endif // TRANSACTIONS_SV
