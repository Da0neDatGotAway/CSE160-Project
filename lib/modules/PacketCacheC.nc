configuration PacketCacheC{
   provides interface PacketCache;
}

implementation{
    components PacketCacheP;
    PacketCache = PacketCacheP;
}