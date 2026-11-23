#include "../../includes/buffer.h"

interface CommandHandler{
   // Events
   event void ping(uint16_t destination, uint8_t *payload);
   event void printNeighbors();
   event void printRouteTable();
   event void printLinkState();
   event void printDistanceVector();
   event void setTestServer(uint8_t listenPort);
   event void setTestClient();
   event void setAppServer();
   event void setAppClient();
   event uint8_t connectClient(uint8_t destination, uint8_t port);
   event void sendTCP(uint8_t socket, uint8_t *payload, uint16_t length);
   event void closeTCP(uint8_t socket);
   event void readTCP(uint8_t socket);
   event void printSocket(uint8_t socket);
   event void testClose(uint8_t serverAddress, uint8_t srcPort, uint8_t destPort);
   event void testPause(uint8_t socket);
   event void testResume(uint8_t socket);
}
