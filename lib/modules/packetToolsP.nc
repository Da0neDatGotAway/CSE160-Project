module PacketToolsP{
   provides interface PacketTools;
}

implementation{
   command pack PacketTools.makePack(uint16_t src, uint16_t dest, uint16_t TTL, uint8_t protocol, uint16_t seq, uint8_t *payload, uint8_t payloadSize){
      pack newPack;
      newPack.src = src;
      newPack.dest = dest;
      memcpy(newPack.payload, payload, payloadSize);
      return newPack;
   }
}