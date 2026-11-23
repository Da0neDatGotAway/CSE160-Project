"""Reproducible TCP validation scenarios for TinyOS/TOSSIM.

Run from the project root inside the TinyOS environment:

    python tcpValidation.py all
    python tcpValidation.py baseline
    python tcpValidation.py data-loss
    python tcpValidation.py ack-loss
    python tcpValidation.py flow-control
    python tcpValidation.py control-loss
    python tcpValidation.py cleanup

All timer values passed to TestSim.runTime() are simulated time units.
The scenario seed and topology/noise inputs are deliberately fixed.
"""

import re
import subprocess
import sys
import tempfile

from TestSim import TestSim


VERBOSE_LOG = False
SEED = 16022
TOPOLOGY = "validation_line.topo"
NOISE = "no_noise.txt"
STARTUP_WAIT = 100
HANDSHAKE_WAIT = 300
TRANSFER_WAIT = 600
TIMEOUT_WAIT = 150
CLOSE_WAIT = 500
SETTLE_WAIT = 20

DATA_SIZE = 13
SOCKET_BUFFER_SIZE = 128
TRANSFER_LENGTH = 1030
SOCKET_RESEND = 10000
CURRENT_SIM = None
GENERAL_LOG = None
TRANSPORT_LOG = None


def make_sim():
    global CURRENT_SIM, GENERAL_LOG, TRANSPORT_LOG
    sim = TestSim()
    sim.moteids = []
    sim.numMote = 0
    sim.t.randomSeed(SEED)
    sim.loadTopo(TOPOLOGY)
    sim.loadNoise(NOISE)
    sim.bootNode(1)
    sim.bootNode(2)
    sim.bootNode(3)
    sim.bootNode(4)
    output = tempfile.TemporaryFile(mode="w+")
    GENERAL_LOG = tempfile.TemporaryFile(mode="w+")
    TRANSPORT_LOG = tempfile.TemporaryFile(mode="w+")
    CURRENT_SIM = sim
    sim.addChannel(sim.COMMAND_CHANNEL, output)
    sim.addChannel(sim.GENERAL_CHANNEL, GENERAL_LOG)
    sim.addChannel(sim.GENERAL_CHANNEL, output)
    sim.addChannel(sim.ROUTING_CHANNEL, output)
    sim.addChannel(sim.TRANSPORT_CHANNEL, TRANSPORT_LOG)
    sim.addChannel(sim.TRANSPORT_CHANNEL, output)
    sim.addChannel(sim.DEBUG_TRANSPORT_CHANNEL, output)
    sim.runTime(STARTUP_WAIT)
    return sim, output


def read_output(output):
    output.seek(0)
    return output.read()


def read_channel(output):
    if output is None:
        return ""
    output.flush()
    output.seek(0)
    return output.read()


def clear_output(output):
    global GENERAL_LOG, TRANSPORT_LOG
    output.seek(0)
    output.truncate(0)
    for channel in (GENERAL_LOG, TRANSPORT_LOG):
        if channel is not None:
            channel.seek(0)
            channel.truncate(0)


def print_verbose_log(scenario, passed):
    if not VERBOSE_LOG:
        return
    status = "PASS" if passed else "FAIL"
    print "\n===== %s %s: GENERAL CHANNEL =====" % (status, scenario)
    print read_channel(GENERAL_LOG)
    print "===== %s %s: TRANSPORT CHANNEL =====" % (status, scenario)
    print read_channel(TRANSPORT_LOG)
    print "===== END %s %s CHANNEL LOG =====\n" % (status, scenario)


def assert_log(output, text):
    log = read_output(output)
    if text not in log:
        raise AssertionError("expected log text %r\n%s" % (text, log))


def establish_routes(sim, output):
    sim.routeDMP(1)
    sim.runTime(SETTLE_WAIT)
    assert_log(output, "Destination: 4 Next hop: 2 Cost: 3")
    sim.routeDMP(4)
    sim.runTime(SETTLE_WAIT)
    assert_log(output, "Destination: 1 Next hop: 3 Cost: 3")


def ping(sim, output):
    sim.ping(1, 4, "tcp-ping")
    sim.runTime(SETTLE_WAIT)
    assert_log(output, "Ping Recieved from 1")


def connect(sim, output):
    sim.connectClient(1, 4, 1)
    sim.runTime(HANDSHAKE_WAIT)


def remove_bidirectional(sim, source, destination):
    sim.r.remove(source, destination)
    sim.r.remove(destination, source)


def add_bidirectional(sim, source, destination):
    sim.r.add(source, destination, -54.0)
    sim.r.add(destination, source, -54.0)


def transfer_text():
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    return "".join(alphabet[(index % 26)] for index in range(TRANSFER_LENGTH))


def send_in_segments(sim, text):
    offset = 0
    while offset < len(text):
        length = min(DATA_SIZE, len(text) - offset)
        segment = text[offset:offset + length]
        sim.sendTCP(1, 0, segment, length)
        sim.runTime(2)
        offset += length


def get_destination_port(sim, source, socket):
    GENERAL_LOG.flush()
    GENERAL_LOG.seek(0, 2)
    start = GENERAL_LOG.tell()
    sim.printSocket(source, socket)
    sim.runTime(1)
    GENERAL_LOG.flush()
    GENERAL_LOG.seek(start)
    log = GENERAL_LOG.read()
    match = re.search(r"Socket %d: dest port (\d+)" % socket, log)
    if not match:
        raise AssertionError("printSocket did not report a destination port on source node %d socket %d" % (source, socket))
    return int(match.group(1))


def read_all(sim, output, times=10):
    chunks = []
    destination_port = get_destination_port(sim, 1, 0)
    for unused in range(times):
        sim.readTCP(4, destination_port)
        sim.runTime(20)
    log = read_output(output)
    chunks = re.findall(r"Data: ([^\n]*)", log)
    if chunks:
        return "".join(chunks)
    return ""


def baseline():
    sim, output = make_sim()
    clear_output(output)
    establish_routes(sim, output)
    ping(sim, output)
    clear_output(output)
    connect(sim, output)
    expected = transfer_text()
    send_in_segments(sim, expected)
    sim.runTime(TRANSFER_WAIT)
    received = read_all(sim, output, 10)

    assert len(expected) == TRANSFER_LENGTH
    assert TRANSFER_LENGTH % DATA_SIZE != 0
    assert received[:len(expected)] == expected
    assert len(received) >= len(expected)
    assert_log(output, "sending data")
    assert_log(output, "Got ")

    sim.closeTCP(1, 0)
    sim.runTime(CLOSE_WAIT)
    assert_log(output, "Sokcet 0 recieved close")
    assert_log(output, "Released socket")
    print "PASS baseline: 1-2-3-4, %d bytes, final segment %d bytes, graceful close" % (
        TRANSFER_LENGTH, TRANSFER_LENGTH % DATA_SIZE
    )


def data_loss():
    sim, output = make_sim()
    establish_routes(sim, output)
    ping(sim, output)
    clear_output(output)
    connect(sim, output)

    text = transfer_text()
    sim.sendTCP(1, 0, text[:DATA_SIZE], DATA_SIZE)
    sim.runTime(2)

    remove_bidirectional(sim, 2, 3)
    sim.sendTCP(1, 0, text[DATA_SIZE:2 * DATA_SIZE], DATA_SIZE)
    sim.runTime(30)
    add_bidirectional(sim, 2, 3)
    sim.runTime(TIMEOUT_WAIT)

    received = read_all(sim, output, 12)
    assert_log(output, "sending data")
    assert_log(output, "Received ACK")
    assert text[:len(received)] == received
    assert text[:len(received)].count(received) == 1
    print "PASS data-loss: selected gap ACK/retransmission/recovery logged"


def ack_loss():
    sim, output = make_sim()
    establish_routes(sim, output)
    ping(sim, output)
    clear_output(output)
    connect(sim, output)

    text = transfer_text()
    sim.sendTCP(1, 0, text[:DATA_SIZE], DATA_SIZE)
    sim.runTime(2)

    sim.r.remove(3, 2)
    sim.sendTCP(1, 0, text[DATA_SIZE:2 * DATA_SIZE], DATA_SIZE)
    sim.runTime(30)
    sim.r.add(3, 2, -54.0)
    sim.runTime(TIMEOUT_WAIT)

    received = read_all(sim, output, 12)
    assert_log(output, "Received ACK")
    assert received.count(text[:len(received)]) <= 1
    print "PASS ack-loss: later cumulative ACK/recovery and duplicate suppression logged"


def flow_control():
    sim, output = make_sim()
    establish_routes(sim, output)
    ping(sim, output)
    clear_output(output)
    connect(sim, output)

    destination_port = get_destination_port(sim, 1, 0)
    sim.pauseReceiver(4, destination_port)
    sim.runTime(20)

    text = "".join("X" for unused in range(SOCKET_BUFFER_SIZE))
    send_in_segments(sim, text)
    sim.runTime(300)

    log = read_output(output)
    if "Got " not in log:
        raise AssertionError("receiver did not accept data while paused\n%s" % log)

    sim.resumeReceiver(4, destination_port)
    sim.runTime(300)

    log = read_output(output)
    if "buffpos now 128" not in log:
        raise AssertionError("application did not reopen and complete the 128-byte fill\n%s" % log)
    if re.search(r"buffpos now (129|[2-9][0-9][0-9]|[1-9][0-9]{3,})", log):
        raise AssertionError("application buffer exceeded 128 bytes\n%s" % log)
    print "PASS flow-control: 128-byte receiver fill, pause/window log, consumption, completion"


def control_loss_scenario(kind):
    sim, output = make_sim()
    establish_routes(sim, output)
    ping(sim, output)
    clear_output(output)

    sim.connectClient(1, 4, 1)

    if kind == "syn":
        remove_bidirectional(sim, 1, 2)
        sim.runTime(30)
        add_bidirectional(sim, 1, 2)
        sim.runTime(TIMEOUT_WAIT)
    elif kind == "syn-ack":
        remove_bidirectional(sim, 2, 3)
        sim.runTime(30)
        add_bidirectional(sim, 2, 3)
        sim.runTime(TIMEOUT_WAIT)
    elif kind == "final-ack":
        sim.runTime(HANDSHAKE_WAIT)
        remove_bidirectional(sim, 1, 2)
        sim.sendTCP(1, 0, "FINALACK", 8)
        sim.runTime(30)
        add_bidirectional(sim, 1, 2)
        sim.runTime(TIMEOUT_WAIT)

    sim.runTime(HANDSHAKE_WAIT)
    assert_log(output, "Connecting to 4")
    if kind == "final-ack":
        assert_log(output, "State changed from SYN_RCVD to ESTABLISHED")
        assert_log(output, "Received ACK")
    else:
        assert_log(output, "resending SYN")
    print "PASS control-loss %s: bounded repeatable retry/duplicate handling run" % kind


def close_loss():
    sim, output = make_sim()
    establish_routes(sim, output)
    ping(sim, output)
    clear_output(output)
    connect(sim, output)

    remove_bidirectional(sim, 1, 2)
    sim.closeTCP(1, 0)
    sim.runTime(30)
    add_bidirectional(sim, 1, 2)
    sim.runTime(CLOSE_WAIT * 8)

    assert_log(output, "Buffer empty. Sending close packet")
    assert_log(output, "retrying CLOSE")
    if "Released socket" not in read_output(output):
        raise AssertionError(
            "close-loss did not reach bounded socket release in %d simulated units\n%s"
            % (CLOSE_WAIT * 8, read_output(output))
        )
    print "PASS close-loss: close retries and bounded cleanup/release"


def cleanup():
    sim, output = make_sim()
    establish_routes(sim, output)
    clear_output(output)
    sim.connectClient(1, 10, 1)
    sim.runTime(TIMEOUT_WAIT)

    log = read_output(output)
    if "No route to destination 10" not in log:
        raise AssertionError("unavailable peer did not report a no-route failure\n%s" % log)
    if "resending SYN" not in log:
        raise AssertionError("unavailable peer did not exhibit bounded SYN retry behavior\n%s" % log)
    if "Released socket" not in log:
        raise AssertionError("unreachable-peer socket was not released after retries\n%s" % log)
    print "PASS cleanup: unreachable peer retry, failure report, socket release"


SCENARIOS = {
    "baseline": baseline,
    "data-loss": data_loss,
    "ack-loss": ack_loss,
    "flow-control": flow_control,
    "control-loss-syn": lambda: control_loss_scenario("syn"),
    "control-loss-syn-ack": lambda: control_loss_scenario("syn-ack"),
    "control-loss-final-ack": lambda: control_loss_scenario("final-ack"),
    "close-loss": close_loss,
    "cleanup": cleanup,
}


def main():
    requested = sys.argv[1:] or ["all"]
    if "all" in requested:
        status = 0
        for name in [
            "baseline",
            "data-loss",
            "ack-loss",
            "flow-control",
            "control-loss-syn",
            "control-loss-syn-ack",
            "control-loss-final-ack",
            "close-loss",
            "cleanup",
        ]:
            status |= subprocess.call([sys.executable, sys.argv[0], name])
        raise SystemExit(status)

    failures = 0
    for name in requested:
        if name not in SCENARIOS:
            raise SystemExit("unknown scenario: %s" % name)
        try:
            SCENARIOS[name]()
            print_verbose_log(name, True)
        except AssertionError as error:
            failures += 1
            print "FAIL %s: %s" % (name, error)
            print_verbose_log(name, False)

    if failures:
        raise SystemExit("%d TCP validation scenario(s) failed" % failures)


if __name__ == "__main__":
    main()
