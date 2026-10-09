interface PacketTools{
   command void makePackNew(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint8_t* payload, uint8_t length);
   command void makePackPass(pack *Package);
}