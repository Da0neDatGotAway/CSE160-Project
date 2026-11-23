#include "../../includes/packet.h"
#include "../../includes/buffer.h"
#include "../../includes/socket.h"

interface Consumer {
    command uint8_t* read(socket_t fd);
    command uint16_t length(socket_t fd);
    command void pauseConsumer(socket_t fd);
    command void resumeConsumer(socket_t fd);

    command void tick();
}