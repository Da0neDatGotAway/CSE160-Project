configuration DistanceVectorC{
    provides interface DistanceVector;
}

implementation{
    components DistanceVectorP;
    DistanceVector = DistanceVectorP;

    components new SimpleSendC(AM_PACK);
    DistanceVectorP.Sender -> SimpleSendC;

    components PacketToolsC;
    DistanceVectorP.PacketTools -> PacketToolsC;

    components NeighborsC;
    DistanceVectorP.Neighbors -> NeighborsC;

    components RoutingC;
    DistanceVectorP.Routing -> RoutingC;
}