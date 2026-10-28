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
#include "includes/routing.h"

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
   uses interface PacketCache;
   uses interface Routing;
   uses interface DistanceVector;
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

   event void Neighbors.signalNeighborRemoved(uint32_t neighborID) {
      return;
   }

   event void Boot.booted(){
      call AMControl.start();

      dbg(GENERAL_CHANNEL, "Booted\n");
   }

   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");

         discoverNeighbors();
         call LoopTimer.startPeriodic(500);
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err){}

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      bestRouteToNeighbor tempRoute;
      //dbg(GENERAL_CHANNEL, "Packet Received\n");
      if(len==sizeof(pack)){
         pack* myMsg=(pack*) payload;
         //dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
                  if (myMsg->TTL < 1){
            dbg(GENERAL_CHANNEL, "Packet Dropped, TTL: %d \n", myMsg->TTL);
            return msg;
         }
         if (call PacketCache.checkPacket(myMsg) == FAIL){
            dbg(GENERAL_CHANNEL, "Packet Dropped, Duplicate Packet \n");
            return msg;
         }
         
         myMsg->TTL--;
         
         switch (myMsg->protocol){
            case PROTOCOL_NDISCOVERY:
               call Neighbors.recieveSend(&sendPackage, myMsg);
               break;
            case PROTOCOL_NDISCOVERYREPLY:
               call Neighbors.recieveResp(&sendPackage, myMsg);
               break;
            case PROTOCOL_DV:
               call DistanceVector.receiveRoute(&sendPackage, myMsg);
               break;
            //TODO: we should make all the forwarding logic that we now have copy and pasted 3 times into a method for code cleanleness at some point
            case PROTOCOL_PING:
               if (myMsg->dest == TOS_NODE_ID){
                  dbg(GENERAL_CHANNEL, "Ping Recieved from %d with data %s\n", myMsg->src, myMsg->payload);
                  call PacketTools.makePackNew(&sendPackage, TOS_NODE_ID, myMsg->src, 16, PROTOCOL_PINGREPLY, myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
                  tempRoute = call Routing.getRoute(sendPackage.dest);
                  if(tempRoute.bestRoute == 0){
                     dbg(ROUTING_CHANNEL, "No route to destination %d\n", sendPackage.dest);
                     return msg;
                  }
                  call Sender.send(sendPackage, tempRoute.bestRoute);
               }
               else if (myMsg->dest != TOS_NODE_ID){
                  tempRoute = call Routing.getRoute(myMsg->dest);
                  if(tempRoute.bestRoute == 0){
                     dbg(ROUTING_CHANNEL, "No route to destination %d\n", myMsg->dest);
                     return msg;
                  }
                  dbg(ROUTING_CHANNEL, "Forwarding Ping from %d to %d via %d\n", myMsg->src, myMsg->dest, tempRoute.bestRoute);
                  call Sender.send(*myMsg, tempRoute.bestRoute);
               } 
               break;
            case PROTOCOL_PINGREPLY:
               if (myMsg->dest == TOS_NODE_ID){
                  dbg(GENERAL_CHANNEL, "Ping Reply Recieved from %d\n", myMsg->src);
               }
               else if (myMsg->dest != TOS_NODE_ID){
               tempRoute = call Routing.getRoute(myMsg->dest);
                  if(tempRoute.bestRoute == 0){
                     dbg(ROUTING_CHANNEL, "No route to destination %d\n", myMsg->dest);
                     return msg;
                  }
                  dbg(ROUTING_CHANNEL, "Forwarding Ping Reply from %d to %d via %d\n", myMsg->src, myMsg->dest, tempRoute.bestRoute);
                  call Sender.send(*myMsg, tempRoute.bestRoute);
               } 
               break;
            default:
               dbg(GENERAL_CHANNEL, "Unknown Protocol %d\n", myMsg->protocol);
         }
         return msg;
      }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }

   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      bestRouteToNeighbor tempRoute;

      dbg(GENERAL_CHANNEL, "PING EVENT \n");
      tempRoute = call Routing.getRoute(destination);
      if(tempRoute.bestRoute == 0){
         dbg(GENERAL_CHANNEL, "No route to destination %d\n", destination);
         return;
      }
      i = tempRoute.bestRoute;
      call PacketTools.makePackNew(&sendPackage, TOS_NODE_ID, destination, 16, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      dbg(GENERAL_CHANNEL, "Sending Ping from %d to %d via %d\n", TOS_NODE_ID, destination, i);
      call Sender.send(sendPackage, i);
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

   event void CommandHandler.printRouteTable(){
      uint8_t routeCount;
      uint8_t routeIndex;
      uint8_t* destinations;
      bestRouteToNeighbor route;

      destinations = call Routing.getRoutes();
      routeCount = call Routing.getSize();

      dbg(COMMAND_CHANNEL, "Node: %d accessible routes:\n", TOS_NODE_ID);
      for(routeIndex = 0; routeIndex < routeCount; routeIndex++){
         route = call Routing.getRoute(destinations[routeIndex]);
         dbg(COMMAND_CHANNEL, "  Destination: %d Next hop: %d Cost: %d\n",
             destinations[routeIndex], route.bestRoute, route.bestRouteCost);
      }
   }

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
        call DistanceVector.sendRoutes(&sendPackage);
   }
}
