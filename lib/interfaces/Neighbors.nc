#include "../../includes/packet.h"
#include "../../includes/neighbors.h"

interface Neighbors{
   command error_t discover(pack sendPackage);
   command error_t recieveSend(pack sendPackage, message_t* msg, void* payload, uint8_t len);
   command error_t recieveResp(pack sendPackage, message_t* msg, void* payload, uint8_t len);
   command uint32_t * getNeighbors();
   command bool containsNeighbor(uint32_t key);
   command uint16_t neighborSize();
   command neighbor getNeighbor(uint32_t key);
}