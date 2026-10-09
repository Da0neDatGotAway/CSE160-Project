configuration PacketCacheC{
   provides interface PacketCache;
}

implementation{
    components PacketCacheP;
    PacketCache = PacketCacheP;

    components new HashmapC(uint16_t, 255);
    PacketCacheP.Hashmap -> HashmapC;
}