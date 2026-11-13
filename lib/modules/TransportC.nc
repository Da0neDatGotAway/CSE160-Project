configuration TransportC{
   provides interface Transport;
}

implementation{
   components new SimpleSendC(AM_PACK);
   TransportP.Sender -> SimpleSendC;

   components PacketToolsC;
   TransportP.PacketTools -> PacketToolsC;

   components RoutingC;
   TransportP.Routing -> RoutingC;

   components TransportP;
   Transport = TransportP;
}