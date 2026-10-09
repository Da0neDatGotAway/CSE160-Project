#include "../../includes/packet.h"

interface Neighbors{
   command error_t discover();
   command error_t recieveSend();
   command error_t recieveResp();
}