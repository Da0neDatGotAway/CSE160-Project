#include "../../includes/packet.h"
#include "../../includes/neighbors.h"

interface Neighbors{
   command error_t updateNeighbor(uint8_t neighborID);
   command error_t discover();
   command error_t recieveSend();
   command error_t recieveResp();
   command uint32_t * getNeighbors();
   command bool containsNeighbor(uint32_t key);
   command uint16_t neighborSize();
   command neighbor getNeighbor(uint32_t key);
}