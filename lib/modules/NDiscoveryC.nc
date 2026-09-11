configuration NDiscoveryC{
   provides interface NDiscovery;
}

implementation{
    components NDiscoveryP;
    NDiscovery = NDiscoveryP;

    components new SimpleSendC(AM_PACK);
    NDiscoveryP.Sender -> SimpleSendC;
    
}

