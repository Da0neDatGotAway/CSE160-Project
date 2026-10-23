
module RoutingP{
   provides interface Routing;
}

implementation{
   bestRouteToNeighbor routes[256];
   uint8_t validRoutes[256];
   uint8_t i=0;
   uint8_t size=0;

   command void Routing.sendPacket(pack *msg) {
      call AMSend.send(AM_BROADCAST_ADDR, msg, sizeof(pack));
   }
   command void Routing.setRoute(uint8_t neighbor, uint8_t bestRoute, uint8_t bestRouteCost, uint8_t secondBestRoute, uint8_t secondBestRouteCost) {
      routes[neighbor].bestRoute = bestRoute;
      routes[neighbor].bestRouteCost = bestRouteCost;
      routes[neighbor].secondBestRoute = secondBestRoute;
      routes[neighbor].secondBestRouteCost = secondBestRouteCost;
   }
   command bestRouteToNeighbor Routing.getRoute(uint8_t neighbor) {
      if (routes[neighbor].bestRoute == 0) {
         routes[neighbor].bestRoute = 0;
         routes[neighbor].bestRouteCost = INF;
         routes[neighbor].secondBestRoute = 0;
         routes[neighbor].secondBestRouteCost = INF;
      }
      return routes[neighbor];
   }

   command uint8_t* Routing.getRoutes() {
      size =0;
      for (i = 0; i < 256; i++) {
         if (routes[i].bestRoute == 0) {
            routes[i].bestRoute = 0;
            routes[i].bestRouteCost = INF;
            routes[i].secondBestRoute = 0;
            routes[i].secondBestRouteCost = INF;
         } else {
            validRoutes[size] = i;
            size++;
         }
      }
      return validRoutes;
   }

   command uint8_t Routing.getSize() {
      size =0;
      for (i = 0; i < 256; i++) {
         if (routes[i].bestRoute != 0) {
            size++;
         }
      }
      return size;
   }
}