configuration StringToolsC{
   provides interface StringTools;
}

implementation{
    components StringToolsP;
    StringTools = StringToolsP;
}