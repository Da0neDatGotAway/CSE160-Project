module RoutingP{
   provides interface Transport;
}

implementation{
   uint32_t i = 0;
   uint32_t j = 0;
   socket_store_t sockets[MAX_NUM_OF_SOCKETS];

   pack sendPack;


   void shrinkList(uint16_t shrink, *uint8_t array, uint16_t size){
      //TODO: TEST THIS.
      for(i = 0; i < size-shrink; i++){
         array[i] = array[i+shrink];
      }
   }

   //ack or seq of 0 is a bug. That means none for us.
   error_t sendTCP(socket_port_t src, socket_addr_t* dest, uint8_t flag, uint8_t seq, uint8_t recieve_window, uint8_t ack, uint8_t* data, uint8_t data_len){

      sendPack.payload[0] = (uint8_t)src;
      sendPack.payload[1] = (uint8_t)(dest->port);
      sendPack.payload[2] = flag;
      sendPack.payload[3] = seq;
      sendPack.payload[4] = recieve_window;
      sendPack.payload[5] = ack;
      sendPack.payload[6] = data_len;
      memcpy(sendPack.payload, data, data_len);
      call PacketTools.makePackNew(&sendPack, TOS_NODE_ID, (uint8_t)(dest->addr), /*TTL*/255, PROTOCOL_TCP, sendPack.payload, PACKET_MAX_PAYLOAD_SIZE);
   
      bestRouteToNeighbor tempRoute;
      tempRoute = call Routing.getRoute((uint8_t)(dest->addr));
      if(tempRoute.bestRoute == 0){
         dbg(GENERAL_CHANNEL, "No route to destination %d\n", (uint8_t)(dest->addr));
         return;
      }
      i = tempRoute.bestRoute;

      call Sender.send(&sendPack, i);
   }

   /**
    * Get a socket if there is one available.
    * @Side Client/Server
    * @return
    *    socket_t - return a socket file descriptor which is a number
    *    associated with a socket. If you are unable to allocated
    *    a socket then return a NULL socket_t.
    */
   command socket_t socket(){
      for(i = 0; i < MAX_NUM_OF_SOCKETS; i++){
         if(sockets[i].state != socket_state.CLOSED){
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
   command error_t bind(socket_t fd, socket_addr_t *addr){
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
   command socket_t accept(socket_t fd);

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
   command uint16_t write(socket_t fd, uint8_t *buff, uint16_t bufflen){
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
   command error_t receive(pack* package){
      dbg();
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
   command uint16_t read(socket_t fd, uint8_t *buff, uint16_t bufflen){
      j = bufflen;
      if(maxRead < bufflen){
         j = maxRead;
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
   command error_t connect(socket_t fd, socket_addr_t * addr){
      if(call Transport.bind(fd, addr) == SUCCESS){
         sendTCP(fd, addr, flag.SYN, 1, SOCKET_BUFFER_SIZE, 0, &(sendPack.payload),0);
         sockets[fd].state = socket_state.SYN_SENT;
         return SUCCESS;
      }
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
   command error_t close(socket_t fd);

   /**
    * A hard close, which is not graceful. This portion is optional.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that you are hard closing. 
    * @side Client/Server
    * @return socket_t - returns SUCCESS if you are able to attempt
    *    a closure with the fd passed, else return FAIL.
    */
   command error_t release(socket_t fd);

   /**
    * Listen to the socket and wait for a connection.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that you are hard closing. 
    * @side Server
    * @return error_t - returns SUCCESS if you are able change the state 
    *   to listen else FAIL.
    */
   command error_t listen(socket_t fd);
}
