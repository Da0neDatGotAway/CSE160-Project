
module RoutingP{
   provides interface Routing;
}

implementation{
   bestRouteToNeighbor routes[256];
   uint8_t validRoutes[256];
   uint8_t i=0;
   uint8_t size=0;

   command void Routing.setRoute(uint8_t destination, uint8_t bestRoute, uint8_t bestRouteCost, uint8_t secondBestRoute, uint8_t secondBestRouteCost) {
      routes[destination].bestRoute = bestRoute;
      routes[destination].bestRouteCost = bestRouteCost;
      routes[destination].secondBestRoute = secondBestRoute;
      routes[destination].secondBestRouteCost = secondBestRouteCost;
   }
   command bestRouteToNeighbor Routing.getRoute(uint8_t destination) {
      if (routes[destination].bestRoute == 0) {
         routes[destination].bestRoute = 0;
         routes[destination].bestRouteCost = INF;
         routes[destination].secondBestRoute = 0;
         routes[destination].secondBestRouteCost = INF;
      }
      return routes[destination];
   }

   command uint8_t* Routing.getRoutes() {
      size =0;
      for (i = 0; i < 255; i++) {
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
      for (i = 0; i < 255; i++) {
         if (routes[i].bestRoute != 0) {
            size++;
         }
      }
      return size;
   }
}