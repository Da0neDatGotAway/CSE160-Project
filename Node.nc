/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"

module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface SimpleSend as Sender;

   uses interface CommandHandler;

   uses interface Timer<TMilli> as LoopTimer;
   uses interface StringTools;
   uses interface PacketTools;
   uses interface Neighbors;
}

implementation{
   pack sendPackage;
   uint32_t i = 0;
   void* tempPointer;
   //we need to do this because we can't print dbg on multiple lines since it come pre-packed with all the log data. Honestly because of that it should auto newline. Seems like a jank logging function honestly
   char strBuf[300];

   // Prototypes
   //void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   void discoverNeighbors(){
      call Neighbors.discover(&sendPackage);
   }

   event void Boot.booted(){
      call AMControl.start();

      dbg(GENERAL_CHANNEL, "Booted\n");
   }

   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");

         discoverNeighbors();
         call LoopTimer.startPeriodic(3000);
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err){}

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      dbg(GENERAL_CHANNEL, "Packet Received\n");
      if(len==sizeof(pack)){
         pack* myMsg=(pack*) payload;
         dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);

         
         switch (myMsg->protocol){
            case PROTOCOL_NDISCOVERY:
               call Neighbors.recieveSend(&sendPackage, myMsg);
            case PROTOCOL_NDISCOVERYREPLY:
               call Neighbors.recieveResp(&sendPackage, myMsg);
            default:
               dbg(GENERAL_CHANNEL, "Unknown Protocol %d\n", myMsg->protocol);
         }
         return msg;
      }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }

   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
      call PacketTools.makePackNew(&sendPackage, TOS_NODE_ID, destination, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Sender.send(sendPackage, destination);
   }

   //TODO: use awfulTextManipulation variable and convert to int because this is NOT legible right now
   event void CommandHandler.printNeighbors(){
      i = call Neighbors.neighborSize();
      i = i*sizeof(uint32_t);
      tempPointer = call Neighbors.getNeighbors();
      //protective wrapper because we are using unsigned ints so we can't go less than 0 and might be empty
      if(!(call StringTools.getUintListAsString(strBuf, sizeof(strBuf), tempPointer, i, sizeof(uint32_t)))){
         memcpy(strBuf, "Could not display list. (overflow?)", 36);
      }
      
      dbg(COMMAND_CHANNEL, "Node: %d Neighbor IDs: [ %s ]\n", TOS_NODE_ID, strBuf);
   }

   event void CommandHandler.printRouteTable(){}

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   //this is called at the end of our loop. We may want to replace this with a clock cycle that loops as fast as possible while still giving priority to other threads
   //and just check the time manually but this works for now
   event void LoopTimer.fired() {
        discoverNeighbors();
   }
}
