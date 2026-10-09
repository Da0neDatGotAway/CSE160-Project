module packetToolsP{
   provides interface packetTools;
}

implementation{
   command pack packetTools.makePack(uint16_t src, uint16_t dest, uint16_t prevNeighbor, uint8_t type, uint8_t *payload, uint8_t payloadSize){
      pack newPack;
      newPack.src = src;
      newPack.dest = dest;
      newPack.prevNeighbor = prevNeighbor;
      newPack.type = type;
      memcpy(newPack.payload, payload, payloadSize);
      return newPack;
   }
}