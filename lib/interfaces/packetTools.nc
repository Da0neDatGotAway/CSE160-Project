interface packetTools{
   command pack makePack(uint16_t src, uint16_t dest, uint16_t prevNeighbor, uint8_t type, uint8_t *payload, uint8_t payloadSize);
}