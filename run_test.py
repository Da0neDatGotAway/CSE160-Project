"""Run the test server, client transfer, and close in one TOSSIM session."""

import sys

import run


def main():
    clientAddress, serverAddress = 1, 4
    srcPort, destPort, transferBytes = 1, 7, 300

    sim, log = run.make_sim()
    run.cmdTestServer(sim, serverAddress, destPort)
    run.cmdTestClient(sim, clientAddress, serverAddress, srcPort, destPort, transferBytes)
    run.cmdClientClose(sim, clientAddress, serverAddress, srcPort, destPort)


if __name__ == "__main__":
    main()
