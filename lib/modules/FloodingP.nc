#include <stddef.h>

module FloodingP {
  provides interface Flooding;
  uses interface SimpleSend as Sender;
}

implementation {
  command error_t Flooding.flood(neighbor *neighborList, int size, pack msg, uint16_t prevNeighbor) {
    int i;
    error_t result = SUCCESS;

    if (neighborList == NULL || size <= 0) {
      return SUCCESS;
    }

    dbg(FLOODING_CHANNEL, "Flooding to %d neighbors\n", size);
    for (i = 0; i < size; i++) {
      if (neighborList[i].id != TOS_NODE_ID && neighborList[i].id != prevNeighbor) {
        dbg(FLOODING_CHANNEL, "Flooding to neighbor %d at I=%d\n", neighborList[i].id, i);
        if (call Sender.send(msg, neighborList[i].id) != SUCCESS) {
          result = FAIL;
        }
      }
    }
    return result;
  }
}