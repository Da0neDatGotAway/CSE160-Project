module TransportP{
   provides interface Transport;
   uses interface Routing;
   uses interface PacketTools;
   uses interface SimpleSend as Sender;
   uses interface LocalTime<TMilli> as LocalTime;
}

implementation{
   uint32_t i = 0;
   uint32_t j = 0;
   socket_store_t sockets[MAX_NUM_OF_SOCKETS];
   uint8_t *payload;
   socket_addr_t destAddr;
   pack sendPack;


   void shrinkList(uint16_t shrink, uint8_t *array, uint16_t size){
      //TODO: TEST THIS.
      for(i = 0; i < size-shrink; i++){
         array[i] = array[i+shrink];
      }
   }

   //ack or seq of 0 is a bug. That means none for us.
   error_t sendTCP(socket_port_t src, socket_addr_t* dest, uint8_t flag, uint8_t seq, uint8_t recieve_window, uint8_t ack, uint8_t* data, uint8_t data_len){
      bestRouteToNeighbor tempRoute;
      sendPack.payload[0] = (uint8_t)src;
      sendPack.payload[1] = (uint8_t)(dest->port);
      sendPack.payload[2] = flag;
      sendPack.payload[3] = seq;
      sendPack.payload[4] = recieve_window;
      sendPack.payload[5] = ack;
      sendPack.payload[6] = data_len;
      memcpy(sendPack.payload, data, data_len);
      payload = ((uint8_t*)(&(sendPack.payload)));
      call PacketTools.makePackNew(&sendPack, TOS_NODE_ID, (uint8_t)(dest->addr), /*TTL*/255, PROTOCOL_TCP, payload, PACKET_MAX_PAYLOAD_SIZE);

      tempRoute = call Routing.getRoute((uint8_t)(dest->addr));
      if(tempRoute.bestRoute == 0){
         dbg(TRANSPORT_CHANNEL, "No route to destination %d\n", (uint8_t)(dest->addr));
         return FAIL;
      }
      i = tempRoute.bestRoute;

      dbg(TRANSPORT_CHANNEL, "Sending TCP packet to %d on port %d with source port %d\n", (uint8_t)(dest->addr), (uint8_t)(dest->port), src);
      call Sender.send(sendPack, i, 0);
      return SUCCESS;
   }

   /**
    * Get a socket if there is one available.
    * @Side Client/Server
    * @return
    *    socket_t - return a socket file descriptor which is a number
    *    associated with a socket. If you are unable to allocated
    *    a socket then return a NULL socket_t.
    */
   command socket_t Transport.socket(){
      for(i = 0; i < MAX_NUM_OF_SOCKETS; i++){
         if(sockets[i].state == CLOSED){
            return (uint8_t)i;
         }
      }
      return MAX_NUM_OF_SOCKETS;
   }

   /**
    * Bind a socket with an address.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       you are binding.
    * @param
    *    socket_addr_t *addr: the source port and source address that
    *       you are biding to the socket, fd.
    * @Side Client/Server
    * @return error_t - SUCCESS if you were able to bind this socket, FAIL
    *       if you were unable to bind.
    */
   command error_t Transport.bind(socket_t fd, socket_addr_t *addr){
      dbg(TRANSPORT_CHANNEL, "Binding socket %d to address %d on port %d\n", fd, addr->addr, addr->port);
      if(fd >= MAX_NUM_OF_SOCKETS){
         return FAIL;
      }
      //TODO: fail if already in use / not closed
      sockets[fd].dest = *addr;
      return SUCCESS;
   }

   /**
    * Checks to see if there are socket connections to connect to and
    * if there is one, connect to it.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that is attempting an accept. remember, only do on listen. 
    * @side Server
    * @return socket_t - returns a new socket if the connection is
    *    accepted. this socket is a copy of the server socket but with
    *    a destination associated with the destination address and port.
    *    if not return a null socket.
    */
   command socket_t Transport.accept(socket_t fd){
      return 0;
   }

   /**
    * Write to the socket from a buffer. This data will eventually be
    * transmitted through your TCP implimentation.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that is attempting a write.
    * @param
    *    uint8_t *buff: the buffer data that you are going to wrte from.
    * @param
    *    uint16_t bufflen: The amount of data that you are trying to
    *       submit.
    * @Side For your project, only client side. This could be both though.
    * @return uint16_t - return the amount of data you are able to write
    *    from the pass buffer. This may be shorter then bufflen
    */
   command uint16_t Transport.write(socket_t fd, uint8_t *buff, uint16_t bufflen){
      j = SOCKET_BUFFER_SIZE - sockets[fd].lastWritten;

      for(i = 0; i < j; i++){
         sockets[fd].sendBuff[sockets[fd].lastWritten] = buff[i];
         sockets[fd].lastWritten++;
      }
      return i;
   }

   /**
    * This will pass the packet so you can handle it internally. 
    * @param
    *    pack *package: the TCP packet that you are handling.
    * @Side Client/Server 
    * @return uint16_t - return SUCCESS if you are able to handle this
    *    packet or FAIL if there are errors.
    */
   command error_t Transport.receive(pack* package){
      dbg(TRANSPORT_CHANNEL, "Received TCP packet from %d\n with source port: %d and destination port: %d", package->src, package->payload[0], package->payload[1]);
      switch(package->payload[2]){
         case SYN:
            dbg(TRANSPORT_CHANNEL, "Received SYN from %d on port %d\n", package->src, package->payload[0]);
            i = call Transport.socket();
            if (i == MAX_NUM_OF_SOCKETS){
               dbg(TRANSPORT_CHANNEL, "No available sockets to accept connection from %d on port %d\n", package->src, package->payload[0]);
               return FAIL;
            }
            destAddr.addr = package->src;
            destAddr.port = package->payload[0];
            call Transport.bind(i, &destAddr);
            sockets[i].state = SYN_RCVD;
            sendTCP((uint8_t)i, &(sockets[i].dest), SYN_ACK, 1, SOCKET_BUFFER_SIZE, 0, (uint8_t*)&(sendPack.payload),0);
            break;
         case SYN_ACK:
            dbg(TRANSPORT_CHANNEL, "Received SYN_ACK from %d on port %d\n", package->src, package->payload[0]);
            i = package->payload[1];
            sockets[i].state = ESTABLISHED;
            sockets[i].dest.port = package->payload[0];
            break;
         default:
            dbg(TRANSPORT_CHANNEL, "Received unknown TCP flag %d from %d on port %d\n", package->payload[2], package->src, package->payload[0]);
            break;
         }
      return SUCCESS;
   }

   /**
    * Read from the socket and write this data to the buffer. This data
    * is obtained from your TCP implimentation.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that is attempting a read.
    * @param
    *    uint8_t *buff: the buffer that is being written.
    * @param
    *    uint16_t bufflen: the amount of data that can be written to the
    *       buffer.
    * @Side For your project, only server side. This could be both though.
    * @return uint16_t - return the amount of data you are able to read
    *    from the pass buffer. This may be shorter then bufflen
    */
   command uint16_t Transport.read(socket_t fd, uint8_t *buff, uint16_t bufflen){
      j = bufflen;
      if(sockets[fd].maxRead < bufflen){
         j = sockets[fd].maxRead;
      }
      for(i = 0; i < j; i++){
         buff[i] = sockets[fd].rcvdBuff[sockets[fd].lastWritten];
      }
      shrinkList((uint16_t)i, sockets[fd].rcvdBuff, SOCKET_BUFFER_SIZE);
      return j;
   }

   /**
    * Attempts a connection to an address.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that you are attempting a connection with. 
    * @param
    *    socket_addr_t *addr: the destination address and port where
    *       you will atempt a connection.
    * @side Client
    * @return socket_t - returns SUCCESS if you are able to attempt
    *    a connection with the fd passed, else return FAIL.
    */
   command error_t Transport.connect(socket_t fd, socket_addr_t * addr){
      dbg(TRANSPORT_CHANNEL, "Connecting to %d on port %d\n", addr->addr, addr->port);
      if(call Transport.bind(fd, addr) == SUCCESS){
         sendTCP(fd, addr, SYN, 1, SOCKET_BUFFER_SIZE, 0, (uint8_t*)&(sendPack.payload),0);
         sockets[fd].state = SYN_SENT;
         sockets[fd].lastRecievedTime = call LocalTime.get();
         return SUCCESS;
      }
      dbg(TRANSPORT_CHANNEL, "Failed to bind socket %d to address %d on port %d\n", fd, addr->addr, addr->port);
      return FAIL;
   }

   /**
    * Closes the socket.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that you are closing. 
    * @side Client/Server
    * @return socket_t - returns SUCCESS if you are able to attempt
    *    a closure with the fd passed, else return FAIL.
    */
   command error_t Transport.close(socket_t fd) {
      return FAIL;
   }

   /**
    * A hard close, which is not graceful. This portion is optional.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that you are hard closing. 
    * @side Client/Server
    * @return socket_t - returns SUCCESS if you are able to attempt
    *    a closure with the fd passed, else return FAIL.
    */
   command error_t Transport.release(socket_t fd){
      return FAIL;
   }

   /**
    * Listen to the socket and wait for a connection.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that you are hard closing. 
    * @side Server
    * @return error_t - returns SUCCESS if you are able change the state 
    *   to listen else FAIL.
    */
   command error_t Transport.listen(socket_t fd){
      sockets[fd].state = LISTEN;
      return SUCCESS;
   }

   command void Transport.tick(){
      for (i = 0; i < MAX_NUM_OF_SOCKETS; i++){
         if(sockets[i].state == SYN_SENT){
            if(call LocalTime.get() - sockets[i].lastRecievedTime > SOCKET_RESEND){
               dbg(TRANSPORT_CHANNEL, "No response from %d on port %d, resending SYN\n", sockets[i].dest.addr, sockets[i].dest.port);
               sendTCP(i, &(sockets[i].dest), SYN, 1, SOCKET_BUFFER_SIZE, 0, (uint8_t*)&(sendPack.payload),0);
               sockets[i].lastRecievedTime = call LocalTime.get();
            }
         }
      }
   }
}
