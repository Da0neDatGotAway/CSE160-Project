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
#include "includes/protocol.h"



module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface SimpleSend as Sender;

   uses interface CommandHandler;

   uses interface NDiscovery as Discovery;

   uses interface Flooding;
}

implementation{
   uint8_t i = 0;
   bool b = 0;

   bool ranDiscover = 0;

   pack sendPackage;
   uint8_t discoveryPayload[2];

   uint8_t nextAvaliable = 0;
   neighbor neighbors[10];
   neighbor newNeb;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   event void Boot.booted(){
      call AMControl.start();

      dbg(GENERAL_CHANNEL, "Booted\n");
   }

   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   void handleRouting(pack* msg){
      dbg(GENERAL_CHANNEL, "Flooding!");
      signal CommandHandler.flood(msg->dest, (uint8_t*)(msg->payload));

   }
   
   event void AMControl.stopDone(error_t err){}

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      dbg(GENERAL_CHANNEL, "Packet Received\n");
      if(len==sizeof(pack)){
         pack* myMsg = (pack*) payload;
         switch (myMsg->protocol){
            case PROTOCOL_NDISCOVERY:
               dbg(GENERAL_CHANNEL, "Discovery Packet Received\n");
               switch (myMsg->payload[0]){
                  case SEND:
                     dbg(GENERAL_CHANNEL, "Discovery Packet Type: Receive %d\n", myMsg->payload[1]);
                     
                     discoveryPayload[0] = RECEIVE;
                     discoveryPayload[1] = TOS_NODE_ID;
                     makePack(&sendPackage, TOS_NODE_ID, myMsg->src, 1, 6, 0, discoveryPayload, sizeof(discoveryPayload)); 
                     call Sender.send(sendPackage, myMsg->src);

                     //This is bad
                     if(!ranDiscover){
                        signal CommandHandler.discover();
                     }
                     ranDiscover = 1;

                     break;
                  case RECEIVE:
                     dbg(GENERAL_CHANNEL, "Discovery Packet Type: Receive %d\n", myMsg->payload[1]);

                     newNeb.id = myMsg->payload[1];
                     neighbors[nextAvaliable] = newNeb;


                     ++nextAvaliable;
                     if(nextAvaliable >= sizeof(neighbors)){
                        nextAvaliable = 0;
                     }

                     for(i = 0; i < sizeof(neighbors); i++){
                        dbg(GENERAL_CHANNEL, "neighbor[%d]: %d\n",i,neighbors[i].id);
                     }
                  default:
                     dbg(GENERAL_CHANNEL, "Recieved unknown discovery packet \n");
               }


               break;
            case PROTOCOL_PING:
               dbg(GENERAL_CHANNEL, "Ping Packet Received, dest: %d\n", myMsg->dest);
               if(TOS_NODE_ID != myMsg->dest){
                  handleRouting(myMsg);
               }
               break;
         default:
            dbg(GENERAL_CHANNEL, "Unknown Protocol %d\n", myMsg->protocol);
         }
         if(TOS_NODE_ID == myMsg->dest){
            dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
         }
         return msg;
      }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      
      return msg;
   }

   //TODO: add not rerun if looped neighbors
   void checkUpdateNeighbor(){
      if(nextAvaliable == 0){
         signal CommandHandler.discover();
      }
   }

   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
      //checkUpdateNeighbor();
      //TODO: abstract the send in node for these functions to go to a buffer where it waits until it has neighbors / is free
      
      //b is our reuseable boolean
      b = 0;
      for(i = 0; i < sizeof(neighbors); i++){
         if(neighbors[i].id == destination){
            b = 1;
         }
      }
      if(b){
         dbg(GENERAL_CHANNEL, "Ping No Flood \n");
         makePack(&sendPackage, TOS_NODE_ID, destination, 20, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
         call Sender.send(sendPackage, destination);
      }else{
         dbg(GENERAL_CHANNEL, "Ping Flood \n");
         signal CommandHandler.flood(destination, payload);
      }
   }

   event void CommandHandler.printNeighbors(){}

   event void CommandHandler.printRouteTable(){}

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   event void CommandHandler.discover(){
      dbg(GENERAL_CHANNEL, "DISCOVER EVENT \n"); 
      discoveryPayload[0] = SEND;
      discoveryPayload[1] = TOS_NODE_ID;
      makePack(&sendPackage, TOS_NODE_ID, 2, 1, 6, 0, discoveryPayload, sizeof(discoveryPayload)); 
      dbg(GENERAL_CHANNEL, "DISCOVER STARTING \n"); 
      call Discovery.discover(sendPackage);
   }

   event void CommandHandler.flood(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "FLOOD EVENT \n");
      //magic number 20
      makePack(&sendPackage, TOS_NODE_ID, destination, 20, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Flooding.flood(neighbors, sizeof(neighbors), sendPackage);
   }

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
}
