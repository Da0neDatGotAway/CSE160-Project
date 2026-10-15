configuration PacketToolsC{
   provides interface PacketTools;
}

implementation{
    components PacketToolsP;
    PacketTools = PacketToolsP;
}