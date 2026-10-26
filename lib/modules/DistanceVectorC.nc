configuration DistanceVectorC{
    provides interface DistanceVector;
    uses interface Neighbors;
    uses interface Routing;
}

implementation{
    components DistanceVectorP;
    DistanceVector = DistanceVectorP;

    components new SimpleSendC(AM_PACK);
    DistanceVectorP.Sender -> SimpleSendC;

    components PacketToolsC;
    DistanceVectorP.PacketTools -> PacketToolsC;

    Neighbors = DistanceVectorP.Neighbors;
    Routing = DistanceVectorP.Routing;
}