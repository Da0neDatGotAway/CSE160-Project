module NDiscoveryP{
   provides interface NDiscovery;
   uses interface SimpleSend as Sender;
}

implementation{
   command error_t NDiscovery.discover(pack msg){
      call Sender.send(msg, PACKET_BLAST);
      dbg(GENERAL_CHANNEL, "DISCOVER RAN \n");
      return SUCCESS;
   }
}