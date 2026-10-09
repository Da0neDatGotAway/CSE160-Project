interface PacketCache{
   command error_t checkPacket(pack *msg);

   command uint16_t getSeqNum();

   command void incrementSeqNum();

   command uint16_t getAndIncrement();
}