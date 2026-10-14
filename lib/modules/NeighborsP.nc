#include <stddef.h>
module NeighborsP{
   provides interface Neighbors;
   uses interface SimpleSend as Sender;
   uses interface Hashmap<neighbor> as Hashmap;
   uses interface LocalTime<TMilli>;
}

implementation{
   //if neighbor gets too big making this a pointer so that we don't copy would be good
   neighbor newNeb;
   uint32_t i = 0;
   uint32_t j = 0;
   uint8_t timeBuffer[sizeof(uint32_t)];
   uint32_t doubleBuffer[MAP_SIZE];

   void updateNeighbor(uint8_t neighborID, uint32_t sentTime){
      if(NeighborMap.contains(neighborID)){
         newNeb = NeighborMap.get(neighborID);
      }else{
         newNeb.id = neighborID;
      }
      //TODO: replace with moving window or something some day (see neighbors.h)
      newNeb.lastRecieveTime = call LocalTime.get();
      NeighborMap.insert(neighborID, newNeb);
   }

   command error_t Neighbors.discover(pack sendPackage){
      dbg(NEIGHBOR_CHANNEL, "Called discoved event\n");

      //clean out values that are expired
      j = 0;
      for(i = 0; i < NeighborMap.size(); i++){
         //TODO: replace with the other one some day see (neighbors.h and updateNeighbor above)
         if(call LocalTime.get() - (NeighborMap.get(NeighborMap.getKeys[i])).lastRecieveTime > N_FORGET_WEIGHT){
            doubleBuffer[j] = NeighborMap.getKeys[i]
            ++j;
         }
      }
      for(i = 0; i < j; i++){
         NeighborMap.remove(doubleBuffer[i]);
      }

      //pack bytes into our time array
      PacketTools.packUint32(&timeBuffer, LocalTime.get());
      PacketTools.makePackNew(&sendPackage, TOS_NODE_ID, EMPTY_DEST, 1, 6, , PACKET_HEADER_LENGTH + sizeof(uint32_t));

      call Sender.send(msg, PACKET_BLAST);
      return SUCCESS;
   }
   command error_t Neighbors.recieveSend(pack sendPackage, message_t* msg, void* payload, uint8_t len){
      dbg(NEIGHBOR_CHANNEL, "Recieved neighbor send packet from: %d", msg->src);

      //reuse our temp var i
      i = PacketTools.unpackUint32(sendPackage->payload);
      updateNeighbor(msg->src, i);

      //pack bytes into our time array
      PacketTools.packUint32(&timeBuffer, LocalTime.get());
      PacketTools.makePackNew(&sendPackage, TOS_NODE_ID, msg->src, 1, 6, 0, CMD_PACKET_HEADER_LENGTH + sizeof(i));

      return SUCCESS;
   }
   command error_t Neighbors.recieveResp(pack sendPackage, ){
      dbg(NEIGHBOR_CHANNEL, "Recieved neighbor recieve packet from: %d", msg->src);

      updateNeighbor(msg->src);

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