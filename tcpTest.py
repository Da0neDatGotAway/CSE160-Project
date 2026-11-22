import tempfile

from TestSim import TestSim
import io

def main():
    # Get simulation ready to run.
    s = TestSim();

    # Before we do anything, lets simulate the network off.
    s.runTime(1);

    log_capture = tempfile.TemporaryFile(mode='w+')

    # Load the the layout of the network.
    s.loadTopo("example.topo");

    # Add a noise model to all of the motes.
    s.loadNoise("no_noise.txt");

    # Turn on all of the sensors.
    s.bootAll();

    # Add the main channels. These channels are declared in includes/channels.h
    #s.addChannel(s.COMMAND_CHANNEL);
    s.addChannel(s.GENERAL_CHANNEL);
    s.addChannel(s.GENERAL_CHANNEL, out=log_capture);
    #s.addChannel(s.ROUTING_CHANNEL);
    s.addChannel(s.TRANSPORT_CHANNEL);
    #s.addChannel(s.DEBUG_TRANSPORT_CHANNEL);
    #s.addChannel(s.NEIGHBOR_CHANNEL);

    #kept just to make sure that this is still working
    # After sending a ping, simulate a little to prevent collision.
    s.runTime(100);
    s.routeDMP(1);
    s.runTime(1);
    print("AM I STUPID?")
    s.connectClient(1, 9, 1);  
    s.runTime(250);

    log_capture.seek(0, 2)
    start_pos = log_capture.tell()

    s.printSocket(9, 0);
    s.runTime(1);
    log_capture.flush()
    log_capture.seek(start_pos)
    port = log_capture.read()
    print(port)
    for i in range(0, 128):
        s.sendTCP(1, 0, "FOOTDIVE", 8);
        s.runTime(2);
        #this 2 runtime is needed or else the command does not get deliverd
    s.runTime(2);
    s.runTime(100);
    #this 2 runtime is needed or else the command does not get deliverd
    s.runTime(2);
    #s.sendTCP(9, 0, "aloha", 5);
    s.runTime(2000);
    print("Reading from socket 0 on node 9")
    s.readTCP(9, 0);
    s.runTime(20);

    s.sendTCP(9, 0, "Goodbye my only friend", 22);
    s.runTime(2);
    s.closeTCP(1, 0)
    s.runTime(200);

if __name__ == '__main__':
    main()
