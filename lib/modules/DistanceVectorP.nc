#include <stddef.h>
module DistanceVectorP{
   provides interface DistanceVector;
   uses interface SimpleSend as Sender;
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
   //PAYLOAD SIZE / 2
   routeToNeighbor routes[10];

   void sendPack(pack* sendPackage, uint32_t length){
      sendPackage->length = PACKET_HEADER_LENGTH + length + 2;
      Sender.send(*sendPackage, neighbors[i]);
   }

   command error_t DistanceVector.sendRoutes(pack* sendPackage){
      validRoutes = call Routing.getRoutes();
      routesSize = call Routing.getSize();

      neighbors = call Neighbors.getNeighbors();
      neighborsSize = call Neighbors.neighborSize();

      call PacketTools.makePackNew(sendPackage, TOS_NODE_ID, 0, 1, PROTOCOL_DV, sendPackage->payload, 0);
      for(i = 0; i < neighborsSize; i++){
         sendPackage->dest = neighbors[i];
         k = 0;
         for(j = 0; j < routesSize; j++){
            tempBestRoute = call Routing.getRoute(validRoutes[j]);
            if(validRoutes[j] != neighbors[i]){
               sendPackage->payload[k] = validRoutes[j];
               sendPackage->payload[k+1] = tempBestRoute.bestRouteCost;
            }else{
               sendPackage->payload[k] = validRoutes[i];
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
      return SUCCESS;
   }
   command error_t DistanceVector.recieveRoute(pack* sendPackage, pack* msg){
      k = (pack->length - PACKET_HEADER_LENGTH)/2;
      for(i = 0; i < k; i++){
         routes[i].route = (msg->src) 
         routes[i].node = (pack->payload)[(i*2)]
         routes[i].cost = (pack->payload)[(i*2)+1]
      }
      call DistanceVector.updateRoutes(routes, k);

      return SUCCESS;
   }

   //TODO: call when receving neighbors for dirrect neighbors
   command error_t DistanceVector.updateRoutes(routeToNeighbor* synced, uint16_t size){ 
      for(i = 0; i < size; i++){
         tempRoute = synced[i];
         ++(tempRout.cost);
         tempBestRoute = call Routing.getRoute(synced[i].node);
         if(tempBestRoute.bestRouteCost > synced[i].cost + 1){
            if(tempBestRoute.bestRouteCost < tempRoute.cost && tempRoute.route != tempBestRoute.bestRoute){
               tempRoute.route = tempBestRoute.bestRoute;
               tempRoute.cost = tempBestRoute.bestRouteCost;
            }

            tempBestRoute.bestRoute = synced[i].route;
            tempBestRoute.bestRouteCost = synced[i].cost + 1;
         }
         if(tempBestRoute.secondBestRouteCost < tempRoute.cost && tempRoute.route != tempBestRoute.bestRoute){
            tempBestRoute.secondBestRoute = tempRoute.route;
            tempBestRoute.secondBestRouteCost = tempRoute.cost + 1;
         }
         call Routing.setRoute(synced[i].node, tempBestRoute.bestRoute, tempBestRoute.bestRouteCost, tempBestRoute.secondBestRoute, tempBestRoute.secondBestRouteCost);
      }

      return SUCCESS;
   }
}