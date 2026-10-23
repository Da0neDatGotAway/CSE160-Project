#include "../../includes/packet.h"
#include "../../includes/routing.h"

interface DistanceVector{
    command error_t sendRoutes(pack* sendPackage);
    command error_t recieveRoute(pack* sendPackage, pack* msg);
    command error_t updateRoutes(routeToNeighbor* synced, uint16_t size);
}