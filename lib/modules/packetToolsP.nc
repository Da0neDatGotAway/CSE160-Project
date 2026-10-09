module PacketToolsP{
   provides interface PacketTools;
}

implementation{
   command void makePackNew(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      //set sequence number to the one from packetCache
      Package->seq = 0;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
   command void makePackPass(pack *Package){
      --(Package->TTL)
   }
}