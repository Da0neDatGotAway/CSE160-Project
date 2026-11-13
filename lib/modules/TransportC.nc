configuration TransportC { provides interface Transport; }

implementation {
  components new SimpleSendC(AM_PACK);
  TransportP.Sender->SimpleSendC;

  components PacketToolsC;
  TransportP.PacketTools->PacketToolsC;

  components RoutingC;
  TransportP.Routing->RoutingC;

  components LocalTimeMilliC;
  TransportP.LocalTime->LocalTimeMilliC;

  components TransportP;
  Transport = TransportP;
}