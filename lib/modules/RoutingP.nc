
module RoutingP{
   provides interface Routing;
}

implementation{
   bestRouteToNeighbor routes[256];

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
      return routes[neighbor];
   }
}