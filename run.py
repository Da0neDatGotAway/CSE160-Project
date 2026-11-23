"""Simple TOSSIM test-driver commands.

This wrapper uses the existing TOSSIM command dispatcher.  Command payload
arguments are kept to 16 bytes or fewer.
"""

import re
import sys
import tempfile

from TestSim import TestSim


DEFAULT_TOPOLOGY = "validation_line.topo"
DEFAULT_NOISE = "no_noise.txt"


def make_sim(topology=DEFAULT_TOPOLOGY, noise=DEFAULT_NOISE):
    sim = TestSim()
    sim.loadTopo(topology)
    sim.loadNoise(noise)
    sim.bootAll()
    log = tempfile.TemporaryFile(mode="w+")
    sim.addChannel(sim.GENERAL_CHANNEL, log)
    sim.addChannel(sim.TRANSPORT_CHANNEL, log)
    sim.addChannel(sim.COMMAND_CHANNEL, log)
    sim.runTime(100)
    sim._run_log = log
    sim.routeDMP(1)
    sim.runTime(20)
    sim.routeDMP(4)
    sim.runTime(20)
    sim.ping(1, 4, "run-test")
    sim.runTime(100)
    return sim, log


def read_log(log):
    log.flush()
    log.seek(0)
    return log.read()


def clear_log(log):
    log.seek(0)
    log.truncate(0)


def cmdTestServer(sim, serverAddress, listenPort):
    """Listen on listenPort at serverAddress and keep the listener active."""
    if listenPort < 0 or listenPort > 255:
        raise ValueError("listenPort must be in the range 0-255")
    sim.testServer(serverAddress, listenPort)
    sim.runTime(20)
    print "Server %d listening on port %d" % (serverAddress, listenPort)


def cmdTestClient(sim, clientAddress, serverAddress, srcPort, destPort,
                  transferBytes):
    """Open a normal client connection and offer transferBytes incrementally."""
    if transferBytes <= 128:
        raise ValueError("transferBytes must be greater than 128")

    sim.testClient(clientAddress, serverAddress, srcPort, destPort, transferBytes)
    sim.runTime(1000)

    before = len(read_log(sim._run_log))
    sim.printSocket(clientAddress, 0)
    sim.runTime(20)
    socketLog = read_log(sim._run_log)[before:]
    socketMatch = re.search(r"Socket 0: dest port (\d+)", socketLog)
    if not socketMatch:
        raise AssertionError("printSocket did not report the destination port")
    destinationPort = int(socketMatch.group(1))

    offered = 0
    accepted = 0
    consumed = 0
    mismatches = 0
    consumerChunk = ""
    acknowledged = 0
    transferLog = ""

    while accepted < transferBytes:
        chunkSize = min(8, transferBytes - accepted)
        start = accepted
        payload = "".join(chr((offset % 256)) for offset in range(start, start + chunkSize))
        before = read_log(sim._run_log)
        sim.sendTCP(clientAddress, 0, payload, chunkSize)
        offered += chunkSize
        sim.runTime(2)
        after = read_log(sim._run_log)
        newLog = after[len(before):]
        transferLog += newLog
        writes = re.findall(r"Wrote (\d+) bytes to socket 0", newLog)
        newlyAccepted = sum(int(value) for value in writes)
        accepted += newlyAccepted

        if newlyAccepted == 0:
            sim.runTime(20)

    sim.runTime(1000)
    acknowledged = len(re.findall(r"Received ACK", read_log(sim._run_log)))
    clear_log(sim._run_log)
    for unused in range(20):
        sim.readTCP(serverAddress, destinationPort)
        sim.runTime(100)
        logText = read_log(getattr(sim, "_run_log", None))
        chunks = re.findall(
            r"DEBUG \(4\): Data: ([\s\S]*?)(?=\n\d+:\d+:\d+\.\d+ DEBUG|\Z)",
            logText
        )
        for chunk in chunks:
            if chunk.endswith("\n"):
                chunk = chunk[:-1]
            consumerChunk += chunk
        transferLog += logText
        clear_log(sim._run_log)

    mismatches = sum(
        1 for index, value in enumerate(consumerChunk)
        if ord(value) != index % 256
    )
    consumed = len(consumerChunk)

    for start in range(0, len(consumerChunk), 16):
        print "Consumed chunk %d: %s" % (
            start, consumerChunk[start:start + 16]
        )

    sim.runTime(300)

    print "Transfer requested=%d offered=%d accepted=%d acknowledged=%d consumed=%d mismatches=%d" % (
        transferBytes, offered, accepted, acknowledged, consumed, mismatches
    )
    if consumed != transferBytes:
        raise AssertionError(
            "incomplete transfer: consumed %d of %d bytes"
            % (consumed, transferBytes)
        )


def cmdClientClose(sim, clientAddress, serverAddress, srcPort, destPort):
    """Request an orderly close for the identified client connection."""
    sim.clientClose(clientAddress, serverAddress, srcPort, destPort)
    sim.runTime(500)
    print "Close requested for client=%d server=%d ports=%d/%d" % (
        clientAddress, serverAddress, srcPort, destPort
    )


def pauseReceiver(sim, receiverAddress, socket):
    """Pause Consumer reads for (receiverAddress, socket)."""
    sim.pauseReceiver(receiverAddress, socket)
    sim.runTime(20)


def resumeReceiver(sim, receiverAddress, socket):
    """Resume Consumer reads for (receiverAddress, socket)."""
    sim.resumeReceiver(receiverAddress, socket)
    sim.runTime(20)


def main():
    if len(sys.argv) < 2:
        raise SystemExit(
            "usage: python run.py server ADDRESS PORT | "
            "client ADDRESS SERVER SRC_PORT DEST_PORT BYTES | "
            "close ADDRESS SERVER SRC_PORT DEST_PORT | "
            "pause ADDRESS SOCKET | resume ADDRESS SOCKET | "
            "all ADDRESS SERVER SRC_PORT DEST_PORT BYTES"
        )

    sim, log = make_sim()

    command = sys.argv[1]
    if command == "all":
        args = [int(value) for value in sys.argv[2:]]
        if len(args) != 5:
            raise SystemExit("usage: python run.py all CLIENT SERVER SRC_PORT DEST_PORT BYTES")
        clientAddress, serverAddress, srcPort, destPort, transferBytes = args
        cmdTestServer(sim, serverAddress, destPort)
        cmdTestClient(sim, clientAddress, serverAddress, srcPort, destPort, transferBytes)
        cmdClientClose(sim, clientAddress, serverAddress, srcPort, destPort)
        return

    args = [int(value) for value in sys.argv[2:]]
    if command == "server" and len(args) == 2:
        cmdTestServer(sim, args[0], args[1])
    elif command == "client" and len(args) == 5:
        cmdTestClient(sim, args[0], args[1], args[2], args[3], args[4])
    elif command == "close" and len(args) == 4:
        cmdClientClose(sim, args[0], args[1], args[2], args[3])
    elif command == "pause" and len(args) == 2:
        pauseReceiver(sim, args[0], args[1])
    elif command == "resume" and len(args) == 2:
        resumeReceiver(sim, args[0], args[1])
    else:
        raise SystemExit("unknown command or wrong argument count")


if __name__ == "__main__":
    main()
