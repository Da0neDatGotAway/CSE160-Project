configuration PacketToolsC{
   provides interface PacketTools;
}

implementation{
    components new PacketToolsP();
    packTools = PacketToolsP;
}