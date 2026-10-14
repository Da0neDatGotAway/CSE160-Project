interface PacketTools{
   command void makePackNew(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint8_t* payload, uint8_t length);
   command void makePackPass(pack *Package);
   //packs a uint32_t to a uint8_t byte array
   command void packUint32(uint32_t value, uint8_t *bytes);
   command uint32_t unpackUint32(uint8_t* bytes);
}