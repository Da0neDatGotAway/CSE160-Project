#include "../../includes/packet.h"
#include "../../includes/buffer.h"
#include "../../includes/socket.h"

interface InputBuffer {
    command uint16_t write(socket_t fd, uint8_t *buff, uint16_t bufflen);

    command void tick();
}
