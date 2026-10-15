interface PacketTools{
   //TODO: we want to remove src from this field because that should be easilt passed in
   command void makePackNew(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint8_t* payload, uint8_t length);
   command void makePackPass(pack *Package);
   //packs a uint32_t to a uint8_t byte array
   command void packUint32(uint8_t *bytes, uint32_t value);
   command uint32_t unpackUint32(uint8_t* bytes);
}