#include "../../includes/packetCache.h"

module PacketCacheP {
  provides interface PacketCache;
}

implementation {
  uint16_t seqNum[sizeof(uint8_t)]; // This is a bit of a hack but I don't know how else to do it. I want to have a seqNum for each protocol so I can keep track of them separately but I don't know how many protocols there will be so I'm just going to make an array of 255 and use the protocol as the index. This is a bit of a hack but it works for now. If I want to add more protocols in the future I'll have to change this but for now it's fine.
  packetCache cache[PACKET_CACHE_SIZE]; // This fuckass language sucks ass if I wanna use a list I have to declare the max size anyways so why even bother at that point?
  packetCache packet;
  uint8_t cachePos = 0;
  uint8_t i=0;


  command error_t PacketCache.checkPacket(pack *msg) {
    if (msg->protocol == 6) {
      return SUCCESS;
    }
    for (i = 0; i < PACKET_CACHE_SIZE; i++) {
      if (cache[i].src == msg->src && cache[i].protocol == msg->protocol && cache[i].seqNum == msg->seq) {
        return FAIL;
      }
    } 

    if (cachePos >= PACKET_CACHE_SIZE) {
      cachePos = 0;
    }
    packet.src = msg->src;
    packet.protocol = msg->protocol;
    packet.seqNum = msg->seq;
    cache[cachePos] = packet;
    cachePos++;
    return SUCCESS;
  }

  command uint16_t PacketCache.getSeqNum(uint8_t protocol) {
    return seqNum[protocol];
  }

  command void PacketCache.incrementSeqNum(uint8_t protocol) {
    seqNum[protocol] = seqNum[protocol] + 1;
  }

  command uint16_t PacketCache.getAndIncrement(uint8_t protocol) {
    seqNum[protocol] = seqNum[protocol] + 1;
    return seqNum[protocol]-1;
  }
}