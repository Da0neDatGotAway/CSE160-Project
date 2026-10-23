enum{
   INF = 16,
};

typedef struct routeToNeighbor{
   uint8_t node;
   uint8_t route;
   uint8_t routeCost;
}

typedef struct bestRouteToNeighbor{
   uint8_t bestRoute;
   uint8_t bestRouteCost;
   uint8_t secondBestRoute;
   uint8_t secondBestRouteCost;
} RoutingMsg;