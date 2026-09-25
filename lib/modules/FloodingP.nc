module FloodingP {
  provides interface Flooding;
  uses interface SimpleSend as Sender;
}

implementation {
  int i = 0;
  command error_t Flooding.flood(neighbor *neighborList, int size, pack msg) {
    //dbg(GENERAL_CHANNEL, "Flooding to %d neighbors\n", size);
    for (i = 0; i < size; i++) {
      if (neighborList[i].id != TOS_NODE_ID) {
        //dbg(GENERAL_CHANNEL, "Flooding to neighbor %d at I=%d\n", neighborList[i].id, i);
        call Sender.send(msg, neighborList[i].id);
      }
    }
    dbg(GENERAL_CHANNEL, "FLOOD RAN \n");
    return SUCCESS;
  }
}