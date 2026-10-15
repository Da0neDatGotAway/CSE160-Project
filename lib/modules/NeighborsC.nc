configuration NeighborsC{
   provides interface Neighbors;
}

implementation{
    components NeighborsP;
    Neighbors = NeighborsP;

    components new SimpleSendC(AM_PACK);
    NeighborsP.Sender -> SimpleSendC;

    components PacketToolsC;
    NeighborsP.PacketTools -> PacketToolsC;

    components new HashMapC(neighbor, MAP_SIZE);
    NeighborsP.NeighborMap -> HashMapC;

    components LocalTimeMilliC;
    NeighborsP.LocalTime -> LocalTimeMilliC;
}