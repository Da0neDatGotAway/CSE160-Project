
module RoutingP{
   provides interface Routing;
}

implementation{
   bestRouteToNeighbor routes[256];
   
   command void Routing.sendPacket(pack *msg) {
      call AMSend.send(AM_BROADCAST_ADDR, msg, sizeof(pack));
   }
}