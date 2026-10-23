#include "../../includes/routing.h"

interface Routing{
   command void sendPacket(pack *msg);
   command void setRoute(uint8_t neighbor, uint8_t bestRoute, uint8_t bestRouteCost, uint8_t secondBestRoute, uint8_t secondBestRouteCost);
   command bestRouteToNeighbor getRoute(uint8_t neighbor);
   command uint8_t getSize();
   command uint8_t* getRoutes();
}