#include <stddef.h>

module InputBufferP {
  provides interface InputBuffer;
  uses interface Transport;
}

implementation {
  uint32_t i = 0;
  uint32_t j = 0;
  buffer_t buffer[MAX_NUM_OF_SOCKETS];


  command uint16_t InputBuffer.write(socket_t fd, uint8_t *buff, uint16_t bufflen) {
    if (fd >= MAX_NUM_OF_SOCKETS) {
      return FAIL;
    }

    buffer[fd].socket = fd;
    //dbg(GENERAL_CHANNEL, "Writing %d bytes to socket %d, bufferlen now %d\n", bufflen, fd, buffer[fd].bufferlen);
    for (i = buffer[fd].bufferlen; i < bufflen; i++) {
      buffer[fd].buffer[buffer[fd].buffpos + i] = buff[i];
    }
    buffer[fd].bufferlen += bufflen;

    return SUCCESS;
  }

  command void InputBuffer.tick() {
    for (i = 0; i < MAX_NUM_OF_SOCKETS; i++) {
        j = 0;
      if (buffer[i].bufferlen > 0 && buffer[i].buffpos < buffer[i].bufferlen) {
        j=call Transport.write(buffer[i].socket, buffer[i].buffer, buffer[i].bufferlen);
        buffer[i].buffpos += j;
        if (j > 0) {
          dbg(GENERAL_CHANNEL, "Wrote %d bytes to socket %d, buffpos now %d\n", j, buffer[i].socket, buffer[i].buffpos);
        }
      }
    }
  }
}