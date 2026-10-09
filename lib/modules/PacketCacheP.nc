module PacketCacheP {
  provides interface PacketCache;
  uses interface Hashmap<uint16_t> as Hashmap;
  
}

implementation {
  uint16_t seqNum = 0;


  command error_t PacketCache.checkPacket(pack *msg) {
    if (msg->protocol == 6) {
      return SUCCESS;
    }
    dbg(ROUTING_CHANNEL, "PACKET SRC: %d, PACKET SEQ: %d, LAST SEQ: %d\n", msg->src, msg->seq, call Hashmap.get(msg->src));
    if (call Hashmap.contains(msg->src)) {
        if (call Hashmap.get(msg->src) < msg->seq) {
            call Hashmap.insert(msg->src, msg->seq);
        } else {
            return FAIL;
        }
    } else {
      call Hashmap.insert(msg->src, msg->seq);
    }
    return SUCCESS;
  }

  command uint16_t PacketCache.getSeqNum() {
    return seqNum;
  }

  command void PacketCache.incrementSeqNum() {
    seqNum++;
  }

  command uint16_t PacketCache.getAndIncrement() {
    uint16_t currentSeqNum = seqNum;
    seqNum++;
    return currentSeqNum;
  }
}