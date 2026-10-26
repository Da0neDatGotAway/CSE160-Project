#include <stddef.h>
module NeighborsP{
   provides interface Neighbors;
   uses interface SimpleSend as Sender;
   uses interface PacketTools;
   uses interface Hashmap<neighbor> as NeighborMap;
   uses interface LocalTime<TMilli>;
   uses interface Routing;
}

implementation{
   //if neighbor gets too big making this a pointer so that we don't copy would be good
   neighbor newNeb;
   uint32_t i = 0;
   uint32_t j = 0;
   uint32_t* neighborsPointer;
   uint8_t timeBuffer[sizeof(uint32_t)];
   uint32_t doubleBuffer[MAP_SIZE];
   bestRouteToNeighbor directRoute;

   void updateNeighbor(uint8_t neighborID, uint32_t sentTime){
      if(call NeighborMap.contains(neighborID)){
         newNeb = call NeighborMap.get(neighborID);
      }else{
         newNeb.id = neighborID;
      }
      //TODO: replace with moving window or something some day (see neighbors.h)
      newNeb.lastRecieveTime = call LocalTime.get();
      call NeighborMap.insert(neighborID, newNeb);

      directRoute = call Routing.getRoute(neighborID);
      if(directRoute.bestRoute == 0){
         call Routing.setRoute(neighborID, neighborID, 1, 0, INF);
      }
   }

   command error_t Neighbors.discover(pack* sendPackage){
      dbg(NEIGHBOR_CHANNEL, "Called discoved event\n");

      //clean out values that are expired
      j = 0;
      neighborsPointer = call NeighborMap.getKeys();
      for(i = 0; i < call NeighborMap.size(); i++){
         //TODO: replace with the other one some day see (neighbors.h and updateNeighbor above)
         newNeb = call NeighborMap.get(neighborsPointer[i]);
         if(call LocalTime.get() - newNeb.lastRecieveTime > N_FORGET_WEIGHT){
            doubleBuffer[j] = neighborsPointer[i];
            ++j;
         }
      }
      for(i = 0; i < j; i++){
         call NeighborMap.remove(doubleBuffer[i]);
      }

      //pack bytes into our time array
      call PacketTools.packUint32(timeBuffer, call LocalTime.get());
      call PacketTools.makePackNew(sendPackage, TOS_NODE_ID, EMPTY_DEST, 1, PROTOCOL_NDISCOVERY, timeBuffer, PACKET_HEADER_LENGTH + sizeof(uint32_t));

      call Sender.send(*sendPackage, PACKET_BLAST);
      return SUCCESS;
   }
   command error_t Neighbors.recieveSend(pack* sendPackage, pack* msg){
      dbg(NEIGHBOR_CHANNEL, "Recieved neighbor send packet from: %d\n", msg->src);

      //reuse our temp var i
      i = call PacketTools.unpackUint32((uint8_t*)(msg->payload));
      updateNeighbor(msg->src, i);

      //pack bytes into our time array
      call PacketTools.packUint32(timeBuffer, call LocalTime.get());
      //Double check length impl. Length is stupid.
      call PacketTools.makePackNew(sendPackage, TOS_NODE_ID, msg->src, 1, PROTOCOL_NDISCOVERYREPLY, timeBuffer, CMD_PACKET_HEADER_LENGTH + sizeof(i));

      call Sender.send(*sendPackage, msg->src);
      return SUCCESS;
   }
   //include sendPackage in the header even though we are not using it for consitancy since this method needs to be called from elsewhere
   command error_t Neighbors.recieveResp(pack* sendPackage, pack* msg){
      dbg(NEIGHBOR_CHANNEL, "Recieved neighbor recieve packet from: %d\n", msg->src);

      //reuse our temp var i
      i = call PacketTools.unpackUint32((uint8_t*)(msg->payload));
      updateNeighbor(msg->src, i);

      return SUCCESS;
   }
   command uint32_t* Neighbors.getNeighbors(){
      return call NeighborMap.getKeys();
   }
   command bool Neighbors.containsNeighbor(uint32_t key){
      return call NeighborMap.contains(key);
   }
   command uint16_t Neighbors.neighborSize(){
      return call NeighborMap.size();
   }
   command neighbor Neighbors.getNeighbor(uint32_t key){
      return call NeighborMap.get(key);
   }
}