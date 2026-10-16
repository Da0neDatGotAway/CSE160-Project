typedef nx_struct packetCache{
   nx_uint8_t src;
   nx_uint16_t seqNum;
   nx_uint8_t protocol;
   nx_uint32_t timestamp;
}packetCache;

enum{
   PACKET_CACHE_SIZE = 255
};