`ifndef TRANSACTIONS_SV
`define TRANSACTIONS_SV



/******************************************************************************
  Input transaction
******************************************************************************/
class BlePacket;

  `define ble_max_data_size (64)

  logic[(`ble_max_data_size*8+16+32+8):0] dataToSend;
  int sizeToSend;

  /* Champs generes aleatoirement */
  logic isAdv;
  logic dataValid = 1;
  logic[31:0] advertasing_address;
  rand logic[31:0] addr;
  rand logic[15:0] header;

  rand logic[(`ble_max_data_size*8):0] rawData;

  rand logic[5:0] size;
  rand logic[7:0] rssi;

  //In case of data packet only (do not care when advertising)
  // Device address for data packet... must have been advertised before. (according to BLE norm)
  // Not random because set in sequencer!
  int data_device_addr;

  //channel is random and constrained
  rand int channel;

  /* Contrainte sur la taille des donnees en fonction du type de paquet */
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
    $sformat(psprint, "BlePacket, isAdv : %b, addr= %h, time = %t\nsizeSend = %d, dataSend = %h\n",
                                                       this.isAdv, this.addr, $time,sizeToSend,dataToSend);
  endfunction : psprint

  function void post_randomize();

	logic[7:0] preamble=8'h55;

	/* Initialisation des données à envoyer */
  	dataToSend = 0;
  	sizeToSend=size*8+16+32+8;

	/* Cas de l'envoi d'un paquet d'advertizing */
	if (isAdv == 1) begin
		addr = 32'h12345678;
        // DeviceAddr = 0. Pour l'exemple
        for(int i=0; i<32;i++)
            rawData[size*8-1-i] = 0;
	end

	/* Cas de l'envoi d'un paquet de données */
    else if (isAdv == 0) begin
        // Peut-être que l'adresse devra être définie d'une certaine manière
		addr = 0;
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
    `define usb_max_data_size (256)

    bit [0:`usb_max_data_size-1][7:0] data;

    //formatting data to be printed
    function string psprint();
      $sformat(psprint, "AnalyzerUsbPacket: data = %h", data);
    endfunction : psprint

endclass : AnalyzerUsbPacket


typedef mailbox #(BlePacket) ble_fifo_t;

typedef mailbox #(AnalyzerUsbPacket) usb_fifo_t;

`endif // TRANSACTIONS_SV
