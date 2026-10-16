configuration DistanceVectorC{
    provides interface DistanceVector;
}

implementation{
    components DistanceVectorP;
    DistanceVector = DistanceVectorP;

    components new SimpleSendC(AM_PACK);
    DistanceVectorP.Sender -> SimpleSendC;
}