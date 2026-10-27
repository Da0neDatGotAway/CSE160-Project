module DistanceVectorP{
   provides interface DistanceVector;
   uses interface SimpleSend as Sender;
   uses interface PacketTools;
   uses interface Neighbors;
   uses interface Routing;
}

implementation{
   uint32_t i = 0;
   uint32_t j = 0;
   uint32_t k = 0;
   uint8_t* validRoutes;
   uint8_t routesSize;
   uint32_t* neighbors;
   uint16_t neighborsSize;
   bestRouteToNeighbor tempBestRoute;
   routeToNeighbor tempRoute;

   uint8_t removedNode = 0;
   //PAYLOAD SIZE / 2
   routeToNeighbor routes[10];
   //This is a really dumb fix to init everything to 0
   uint8_t zeroPayload[PACKET_MAX_PAYLOAD_SIZE];

   void sendPack(pack* sendPackage, uint32_t length){
      //sendPackage->length = PACKET_HEADER_LENGTH + length + 2;
      call Sender.send(*sendPackage, neighbors[i]);
   }

   event void Neighbors.signalNeighborRemoved(uint32_t neighborID) {
        // Handle the notification
        removedNode = (uint8_t)neighborID;
        call Routing.removeRouteThrough((uint8_t)neighborID);
   }

   command error_t DistanceVector.sendRoutes(pack* sendPackage){
      //dbg(GENERAL_CHANNEL, "Sending routes to neighbors\n");
      validRoutes = call Routing.getRoutes();
      routesSize = call Routing.getSize();

      neighbors = call Neighbors.getNeighbors();
      neighborsSize = call Neighbors.neighborSize();

      call PacketTools.makePackNew(sendPackage, TOS_NODE_ID, EMPTY_DEST, 1, PROTOCOL_DV, zeroPayload, PACKET_MAX_PAYLOAD_SIZE);
      for(i = 0; i < neighborsSize; i++){
         sendPackage->dest = neighbors[i];
         k = 0;
         if(removedNode != 0){
            sendPackage->payload[k] = removedNode;
            sendPackage->payload[k+1] = INF;
            k += 2;
         }
         for(j = 0; j < routesSize; j++){
            tempBestRoute = call Routing.getRoute(validRoutes[j]);
            if(tempBestRoute.bestRoute != neighbors[i]){
               sendPackage->payload[k] = validRoutes[j];
               sendPackage->payload[k+1] = tempBestRoute.bestRouteCost;
            }else{
               sendPackage->payload[k] = validRoutes[j];
               sendPackage->payload[k+1] = INF;
            }
            if(k == 18){
               sendPack(sendPackage, k);
               k = 0;
            }else{
               k += 2;
            }
         }
         if(k != 0){
            sendPack(sendPackage, k);
         }
      }
      removedNode = 0;
      return SUCCESS;
   }
   command error_t DistanceVector.receiveRoute(pack* sendPackage, pack* msg){
      routesSize = PACKET_MAX_PAYLOAD_SIZE / 2;
      k = 0;

      for(i = 0; i < routesSize; i++){
         if(msg->payload[i * 2] == 0){
            break;
         }

         routes[k].route = msg->src;
         routes[k].node = msg->payload[i * 2];
         routes[k].routeCost = msg->payload[(i * 2) + 1];
         k++;
      }

      if(k > 0){
         call DistanceVector.updateRoutes(routes, k);
      }

      return SUCCESS;
   }

   //TODO: call when receving neighbors for dirrect neighbors
   command error_t DistanceVector.updateRoutes(routeToNeighbor* synced, uint16_t size){ 
      for(i = 0; i < size; i++){
         tempBestRoute = call Routing.getRoute(synced[i].node);
         //if we were sent a cost of inf for our current best route to a node
         //update the table to remove the value
         if(synced[i].routeCost >= INF){
            if(tempBestRoute.bestRoute == synced[i].route){
               call Routing.setRoute(synced[i].node, 0, INF, 0, INF);
            }else if(tempBestRoute.secondBestRoute == synced[i].route){
               call Routing.setRoute(synced[i].node,
                  tempBestRoute.bestRoute, tempBestRoute.bestRouteCost,
                  0, INF);
            }
            continue;
         }

         tempRoute = synced[i];
         ++(tempRoute.routeCost);
         if(tempBestRoute.bestRouteCost > synced[i].routeCost + 1){
            if(tempBestRoute.bestRouteCost < tempRoute.routeCost && tempRoute.route != tempBestRoute.bestRoute){
               tempRoute.route = tempBestRoute.bestRoute;
               tempRoute.routeCost = tempBestRoute.bestRouteCost;
            }

            tempBestRoute.bestRoute = synced[i].route;
            tempBestRoute.bestRouteCost = synced[i].routeCost + 1;
         }
         if(tempBestRoute.secondBestRouteCost < tempRoute.routeCost && tempRoute.route != tempBestRoute.bestRoute){
            tempBestRoute.secondBestRoute = tempRoute.route;
            tempBestRoute.secondBestRouteCost = tempRoute.routeCost + 1;
         }
         call Routing.setRoute(synced[i].node, tempBestRoute.bestRoute, tempBestRoute.bestRouteCost, tempBestRoute.secondBestRoute, tempBestRoute.secondBestRouteCost);
      }

      return SUCCESS;
   }
}