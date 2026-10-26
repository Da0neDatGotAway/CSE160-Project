#include "../../includes/routing.h"

interface Routing{
   command void setRoute(uint8_t destination, uint8_t bestRoute, uint8_t bestRouteCost, uint8_t secondBestRoute, uint8_t secondBestRouteCost);
   command void removeRouteThrough(uint8_t node);
   command bestRouteToNeighbor getRoute(uint8_t destination);
   command uint8_t getSize();
   command uint8_t* getRoutes();
}