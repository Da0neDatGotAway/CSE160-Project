#include <stddef.h>

module ConsumerP {
  provides interface Consumer;
  uses interface Transport;
}

implementation {
  uint32_t i = 0;
  uint32_t j = 0;
  buffer_t buffer[MAX_NUM_OF_SOCKETS];

    command uint8_t* Consumer.read(socket_t fd) {
        //return the current buffer pointer
        if (fd >= MAX_NUM_OF_SOCKETS) {
            return NULL;
        }
        dbg(GENERAL_CHANNEL, "Reading from socket %d, bufferlen: %d, buffpos: %d\n", fd, buffer[fd].bufferlen, buffer[fd].buffpos);
        return buffer[fd].buffer;
    }

    command void Consumer.tick() {
        //read from the transport buffer and store it in the buffer
        for (i = 0; i < MAX_NUM_OF_SOCKETS; i++) {
            j = call Transport.read(buffer[i].socket, (uint8_t*)&(buffer[i].buffer[buffer[i].buffpos]), BUFFER_SIZE- buffer[i].buffpos);
            buffer[i].buffpos += j;
            if (j > 0) {
                dbg(GENERAL_CHANNEL, "Read %d bytes from socket %d, buffpos now %d, buffer now %s\n", j, buffer[i].socket, buffer[i].buffpos, buffer[i].buffer);
            }
        }
    }
}