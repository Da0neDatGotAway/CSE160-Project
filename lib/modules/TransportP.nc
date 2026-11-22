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
   uint32_t k = 0;
   uint32_t l = 0;
   uint32_t m = 0;
   
   short signedI = 0;
   socket_store_t sockets[MAX_NUM_OF_SOCKETS];
   uint8_t *payload;
   socket_addr_t destAddr;
   pack sendPack;


   void shrinkList(uint16_t shrink, uint8_t *array, uint16_t size){
      //TODO: TEST THIS.
      if (shrink > size){
         shrink = size;
      }
      for(i = 0; i < size-shrink; i++){
         array[i] = array[i+shrink];
      }
   }

   short isAckNew(socket_t fd, uint8_t ack){
      short returnValue = ack;
      if(sockets[fd].lastAck > 200 && ack < 100){
         returnValue += 200;
         return returnValue - sockets[fd].lastAck;
      }
      return returnValue - sockets[fd].lastAck;
   }

   short isSeqNew(socket_t fd, uint8_t seq){
      short returnValue = seq;
      if(sockets[fd].lastByteRcvd > 200 && seq < 100){
         returnValue += 200;
         return returnValue - sockets[fd].lastByteRcvd;
      }
      return returnValue - sockets[fd].lastByteRcvd;
   }

   //ack or seq of 0 is a bug. That means none for us.
   error_t sendTCP(socket_port_t src, socket_addr_t* dest, uint8_t flag, uint8_t seq, uint8_t recieve_window, uint8_t ack, uint8_t* data, uint8_t data_len){
      uint32_t iTemp = 0;
      bestRouteToNeighbor tempRoute;
      sendPack.payload[0] = (uint8_t)src;
      sendPack.payload[1] = (uint8_t)(dest->port);
      sendPack.payload[2] = flag;
      sendPack.payload[3] = seq;
      sendPack.payload[4] = recieve_window;
      sendPack.payload[5] = ack;
      sendPack.payload[6] = data_len;
      memcpy(&(sendPack.payload[7]), data, data_len);
      payload = ((uint8_t*)(&(sendPack.payload[0])));
      call PacketTools.makePackNew(
            &sendPack,
            TOS_NODE_ID,
            (uint8_t)(dest->addr),
            255,
            PROTOCOL_TCP,
            payload,
            PACKET_MAX_PAYLOAD_SIZE
      );

      tempRoute = call Routing.getRoute((uint8_t)(dest->addr));
      if(tempRoute.bestRoute == 0){
         dbg(TRANSPORT_CHANNEL, "No route to destination %d, (port %d)\n", (uint8_t)(dest->addr),(uint8_t)(dest->port));
         return FAIL;
      }
      iTemp = tempRoute.bestRoute;

      //dbg(TRANSPORT_CHANNEL, "Sending TCP packet to %d on port %d with source port %d and flag %d\n", (uint8_t)(dest->addr), (uint8_t)(dest->port), src, flag);
      call Sender.send(sendPack, iTemp, 0);
      return SUCCESS;
   }

   error_t sendTCPData(socket_t fd, uint8_t seq, uint8_t* data, uint8_t data_len){
      dbg(TRANSPORT_DEBUG_CHANNEL, "sending data from port %d with seq %d and ack %d\n", fd, seq, sockets[fd].lastAck);
      return sendTCP(fd, &(sockets[fd].dest), DATA, seq, SOCKET_BUFFER_SIZE - sockets[fd].maxRead, sockets[fd].lastByteRcvd, data, data_len);
   }

   bool canSendClose(socket_t fd){
      return (sockets[fd].closeState != NO_CLOSE && sockets[fd].lastWritten == 0);
   }

   //Handles sending the close once our write buffer is empty
   void informClose(socket_t fd){
      dbg(TRANSPORT_CHANNEL, "Buffer empty. Sending close packet\n");
      sendTCP(fd, &(sockets[fd].dest), CLOSE, 0, SOCKET_BUFFER_SIZE - sockets[fd].maxRead, 0, (uint8_t*)&(sendPack.payload), 0);
      if(sockets[fd].closeState == RECEIVE_CLOSE){
         sockets[fd].closeState = AWAIT_CLOSE;
      }
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
      if(sockets[fd].closeState != NO_CLOSE){
         return 0;
      }
      j = SOCKET_BUFFER_SIZE - sockets[fd].lastWritten;
      dbg(TRANSPORT_CHANNEL, "Writing to socket %d with buffer length %d\n", fd, bufflen);

      if(bufflen < j){
         j = bufflen;
      }

      for(i = 0; i < j; i++){
         sockets[fd].sendBuff[sockets[fd].lastWritten] = buff[i];
         sockets[fd].lastWritten++;
      }
      dbg(TRANSPORT_CHANNEL, "Wrote %d bytes to socket %d, last written: %d\n", j, fd, sockets[fd].lastWritten);
      dbg(TRANSPORT_CHANNEL, "write: asked %d, wrote %d, lastWritten now %d\n", bufflen, j, sockets[fd].lastWritten);
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
      sockets[package->payload[1]].recieveWindow = package->payload[4];
      //dbg(TRANSPORT_CHANNEL, "Received TCP packet from %d with port: %d and dest: %d and seq: %d\n", package->src, package->payload[0], package->payload[1], package->payload[3]);
      //dbg(TRANSPORT_CHANNEL, "Current Receive Window: %d\n", sockets[package->payload[1]].recieveWindow);
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
         //case ACK:
         case DATA:
            //We use l here because a bunch of functions use i as a temp variable :P
            //This is because I am still not as familiar as I would like to be with nesC
            l = package->payload[1];
            signedI = isAckNew(l, package->payload[5]);
            sockets[l].recieveWindow = package->payload[4];
            if(signedI > 0){
               //Finish the handshake
               if(sockets[l].state == SYN_RCVD){
                  sockets[l].state = ESTABLISHED;
                  dbg(TRANSPORT_CHANNEL, "State changed from SYN_RCVD to ESTABLISHED communicating with %d on port %d", package->src, package->payload[0]);
               }
               sockets[l].lastAck = package->payload[5];
               sockets[l].lastWritten-=(uint8_t)signedI;
               shrinkList((uint8_t)signedI, (uint8_t*)(&(sockets[l].sendBuff[0])), SOCKET_BUFFER_SIZE);
               sockets[l].lastRecievedTime = call LocalTime.get();
               dbg(TRANSPORT_CHANNEL, "Received ACK %d from %d on port %d, seq %d\n", package->payload[5], package->src, package->payload[0], package->payload[3]);
               
               //Handles sending the close once our write buffer is empty
               if(canSendClose(l)){
                  informClose(l);
               }
            }
            else{
               dbg(TRANSPORT_DEBUG_CHANNEL, "Received out of date ACK %d from %d on port %d\n", package->payload[5], package->src, package->payload[0]);
            }
            signedI = isSeqNew(l, package->payload[3]);
            if(signedI > 0 && package->payload[6] != 0){
               //currently we just test if the payload is exactly the one that we want. We could do caching here if we cared instead
               if(signedI == 1){
                  j = SOCKET_BUFFER_SIZE - sockets[l].maxRead;

                  if(package->payload[6] < j){
                     j = package->payload[6];
                  }

                  dbg(TRANSPORT_CHANNEL, "SOCKET STATE: %d\n", sockets[l].state);
                  if(sockets[l].state == SYN_RCVD){
                     sockets[l].state = ESTABLISHED;
                     dbg(TRANSPORT_CHANNEL, "State changed from SYN_RCVD to ESTABLISHED communicating with %d on port %d\n", package->src, package->payload[0]);
                  }

                  for(i = 0; i < j; i++){
                     sockets[l].rcvdBuff[sockets[l].maxRead] = package->payload[i+7];
                     sockets[l].maxRead++;
                  }
                  dbg(TRANSPORT_CHANNEL, "Got %d bytes (seq %d), maxRead now %d\n", j, package->payload[3], sockets[l].maxRead);

                  //i is now the amount of bytes we were able to write
                  sockets[l].lastByteRcvd += i;

                  //Now we send an ack here if we don't have our own data to send (otherwise we use that)
                  if(sockets[l].lastWritten == 0){
                     sendTCPData(i, sockets[l].lastAck+1+l, (uint8_t*)&(payload[8]), 0);
                  }
                  dbg(TRANSPORT_CHANNEL, "Byte seq num %d read from connection to %d on port %d, read buffer size: %d\n", package->payload[3], package->src, package->payload[0], sockets[l].maxRead);
               }else{
                  dbg(TRANSPORT_CHANNEL, "Received skipped SQN %d. Expected %d, from %d on port %d\n", package->payload[3], sockets[l].lastByteRcvd, package->src, package->payload[0]);
               }
            }else{
               dbg(TRANSPORT_DEBUG_CHANNEL, "Received out of date SQN %d from %d on port %d\n", package->payload[3], package->src, package->payload[0]);
            }
            break;
         case CLOSE:
            l = package->payload[1];
            if(sockets[l].state == ESTABLISHED){
               dbg(TRANSPORT_CHANNEL, "Sokcet %d recieved close\n", l);
               if(sockets[l].closeState == LOCAL_CLOSE){
                  sockets[l].closeState = AWAIT_CLOSE;
               }else{
                  if(sockets[l].closeState != AWAIT_CLOSE){
                     sockets[l].closeState = RECEIVE_CLOSE;
                  }
                  sockets[l].lastRecievedTime = call LocalTime.get();
                  if(canSendClose(l)){
                     informClose(l);
                  }
               }
            }
            break;
         default:
            dbg(TRANSPORT_CHANNEL, "Received unknown TCP flag %d from %d on port %d\n", package->payload[2], package->src, package->payload[0]);
            return FAIL;
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
      shrinkList((uint16_t)i, (uint8_t*)(&(sockets[fd].rcvdBuff[0])), SOCKET_BUFFER_SIZE);
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
      sockets[fd].closeState = LOCAL_CLOSE;
      if(canSendClose(fd)){
         informClose(fd);
      }
      
      return SUCCESS;
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
      sockets[fd].flag = 0;
      sockets[fd].state = CLOSED;
      sockets[fd].dest.port = 0;
      sockets[fd].dest.addr = 0;
      //this is the line where we update the data in send buff if we cared about security. But we don't
      sockets[fd].lastWritten = 0;
      sockets[fd].lastAck = 0;
      sockets[fd].lastSent = 0;
      sockets[fd].maxRead = 0;
      sockets[fd].lastByteRcvd = 0;
      sockets[fd].recieveWindow = 0;
      sockets[fd].lastRecievedTime = 0;

      sockets[fd].closeState = 0;

      dbg(TRANSPORT_CHANNEL, "Released socket %d\n", fd);

      return SUCCESS;
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
         else if(sockets[i].state == ESTABLISHED){
            if(canSendClose(i)) {
               //Closing since we don't use sates because :(
               j = call LocalTime.get();

               if(sockets[i].closeState == AWAIT_CLOSE){
                  if(j - sockets[i].lastRecievedTime > SOCKET_RESEND*4){
                     call Transport.release(i);
                  }
               }else{
                  if(j - sockets[i].lastRecievedTime > SOCKET_RESEND) {
                     dbg(TRANSPORT_CHANNEL, "No response from %d on port %d, retrying CLOSE\n", sockets[i].dest.addr, sockets[i].dest.port);
                     informClose(i);
                     sockets[i].lastRecievedTime = j;
                  }
               }
            }
            else {
               m = sockets[i].lastSent;
               j = call LocalTime.get();
               if(j - sockets[i].lastRecievedTime > SOCKET_RESEND){
                  m = 0;
                  sockets[i].lastRecievedTime = j;
               }
               //setup loop
               k = sockets[i].recieveWindow;
               if(sockets[i].lastWritten < k){
                  //dbg(TRANSPORT_CHANNEL, "Recieve window is %d, last written is %d, socket %d\n", k, sockets[i].lastWritten, i);
                  k = sockets[i].lastWritten;
               }
               l = 0;
               //loop all data we are able to send (that is our window)
               for(j = m; j < k; j++){
                  if(j%DATA_SIZE == DATA_SIZE-1){
                     sendTCPData(i, sockets[i].lastAck + 1 + l, (uint8_t*)(&(sockets[i].sendBuff[l])), DATA_SIZE);
                     l+=DATA_SIZE;
                     sockets[i].lastSent+=DATA_SIZE;
                  }
               } //greater than
               if(j != m && k - l > 0){
                  //dbg(TRANSPORT_CHANNEL, "k-l is %d, sending last data packet with data %s\n", k-l, (uint8_t*)(&(sockets[i].sendBuff[l])));
                  //dbg(TRANSPORT_CHANNEL, "Sending last data packet with data %s\n", (uint8_t*)(&(sockets[i].sendBuff[l])));
                  sendTCPData(i, sockets[i].lastAck + 1 + l, (uint8_t*)(&(sockets[i].sendBuff[l])), k-l);
                  sockets[i].lastSent+=(k-l);
               }
            }
         }
      }
   }
}
