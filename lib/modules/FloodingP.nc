module FloodingP {
  provides interface Flooding;
  uses interface SimpleSend as Sender;
}

implementation {
  int i = 0;
  command error_t Flooding.flood(neighbor *neighborList, int size, pack msg, uint16_t prevNeighbor) {
    dbg(FLOODING_CHANNEL, "Flooding to %d neighbors\n", size);
    for (i = 0; i < size; i++) {
      if (neighborList[i].id != TOS_NODE_ID && neighborList[i].id != prevNeighbor) {
        //dbg(GENERAL_CHANNEL, "Previous Neighbor: %d Current Neighbor: %d\n", prevNeighbor, neighborList[i].id);
        dbg(FLOODING_CHANNEL, "Flooding to neighbor %d at I=%d\n", neighborList[i].id, i);
        call Sender.send(msg, neighborList[i].id);
      }
    }
    dbg(FLOODING_CHANNEL, "FLOOD RAN \n");
    return SUCCESS;
  }
}