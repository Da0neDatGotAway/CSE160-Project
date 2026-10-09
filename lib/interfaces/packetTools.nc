#include "../../includes/packet.h"

interface PacketTools{
   command pack makePack(uint16_t src, uint16_t dest, uint16_t TTL, uint8_t protocol, uint16_t seq, uint8_t *payload, uint8_t payloadSize);
}