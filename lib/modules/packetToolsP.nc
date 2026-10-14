module PacketToolsP{
   provides interface PacketTools;
}

implementation{
   command void PacketTools.makePackNew(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      //set sequence number to the one from packetCache
      Package->seq = 0;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
   command void PacketTools.makePackPass(pack *Package){
      --(Package->TTL)
   }
   command void PacketTools.packUint32(uint8_t *bytes, uint32_t value) {
    bytes[0] = (uint8_t)(value >> 24);
    bytes[1] = (uint8_t)(value >> 16);
    bytes[2] = (uint8_t)(value >> 8);
    bytes[3] = (uint8_t)value;
   }
   command uint32_t PacketTools.unpackUint32(uint8_t* bytes) {
      return ((uint32_t)bytes[0] << 24) |
        ((uint32_t)bytes[1] << 16) |
        ((uint32_t)bytes[2] <<  8) |
        ((uint32_t)bytes[3]);
   }
}