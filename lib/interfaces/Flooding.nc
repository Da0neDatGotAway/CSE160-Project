#include "../../includes/packet.h"

interface Flooding{
   command error_t flood(neighbor *neighborList, int size, pack msg);
}