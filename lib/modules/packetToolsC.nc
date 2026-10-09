configuration packetToolsC{
   provides interface packetTools;
}

implementation{
    components new packetToolsP();
    packTools = packetToolsP;
}