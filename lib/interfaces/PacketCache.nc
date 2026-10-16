

interface PacketCache{
   command error_t checkPacket(pack *msg);

   command uint16_t getSeqNum(uint8_t protocol);

   command void incrementSeqNum(uint8_t protocol);

   command uint16_t getAndIncrement(uint8_t protocol);
}