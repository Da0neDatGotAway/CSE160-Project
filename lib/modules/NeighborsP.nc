module NeighborsP{
   provides interface Neighbors;
   uses interface SimpleSend as Sender;
   uses interface Hashmap<neighbor> as Hashmap;
   uses interface LocalTime<TMilli>;
}

implementation{
   neighbor newNeb;

   command error_t Neighbors.updateNeighbor(uint8_t neighborID){
      if(NeighborMap.contains(neighborID)){
         newNeb = NeighborMap.get(neighborID);
      }else{
         newNeb.id = neighborID;
      }
      newNeb.lastRecieveTime = call LocalTime.get();
      NeighborMap.insert(neighborID, newNeb);
      return SUCCESS;
   }

   command error_t Neighbors.discover(pack sendPackage){
      dbg(NEIGHBOR_CHANNEL, "Called discoved event\n");
      PacketTools.makePackNew(&sendPackage, TOS_NODE_ID, EMPTY_DEST, 1, 6, 0, 0);

      call Sender.send(msg, PACKET_BLAST);
      return SUCCESS;
   }
   command error_t Neighbors.recieveSend(pack sendPackage, message_t* msg, void* payload, uint8_t len){
      dbg(NEIGHBOR_CHANNEL, "Recieved neighbor send packet from: %d", msg->src);
      PacketTools.makePackNew(&sendPackage, TOS_NODE_ID, msg->src, 1, 6, 0, 0);

      //update neighbors used to be here but it's probably better to have it dirrectly in the root receive method.

      return SUCCESS;
   }
   command error_t Neighbors.recieveResp(pack sendPackage, ){
      dbg(NEIGHBOR_CHANNEL, "Recieved neighbor recieve packet from: %d", msg->src);

      return SUCCESS;
   }
   command uint32_t* Neighbors.getNeighbors(){
      return NeighborMap.getKeys();
   }
   command bool Neighbors.containsNeighbor(uint32_t key){
      return NeighborMap.contains(key);
   }
   command uint16_t Neighbors.neighborSize(){
      return NeighborMap.size();
   }
   command neighbor Neighbors.getNeighbor(uint32_t key){
      return NeighborMap.get(key);
   }
}