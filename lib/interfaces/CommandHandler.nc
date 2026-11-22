#include "../../includes/buffer.h"

interface CommandHandler{
   // Events
   event void ping(uint16_t destination, uint8_t *payload);
   event void printNeighbors();
   event void printRouteTable();
   event void printLinkState();
   event void printDistanceVector();
   event void setTestServer();
   event void setTestClient();
   event void setAppServer();
   event void setAppClient();
   event uint8_t connectClient(uint8_t destination, uint8_t port);
   event void sendTCP(uint8_t socket, uint8_t *payload, uint16_t length);
   event void closeTCP(uint8_t socket);
   event void readTCP(uint8_t socket);
   event void printSocket(uint8_t socket);
}
