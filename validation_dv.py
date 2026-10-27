"""Reproducible routing validation scenarios for the TinyOS/TOSSIM project.

Run inside the TinyOS Docker environment after building the simulation:

    python validation_tests.py all
    python validation_tests.py line
    python validation_tests.py alternative
    python validation_tests.py partition
    python validation_tests.py poison
    python validation_tests.py capacity
    python validation_tests.py loss
    python validation_tests.py lifetime

All times passed to runTime() are simulated time units.  Nodes boot in
ascending node-ID order at TestSim's deterministic 1333*node-ID schedule.
Every scenario uses no_noise.txt except "loss", which uses validation_loss.txt.
The startup wait is 100 units: it covers boot, neighbor discovery, and several
500-tick DV exchanges.  After a link or node failure, the wait is 250 units:
it exceeds neighbor expiration (N_FORGET_WEIGHT) and allows withdrawals and
replacement routes to propagate.
"""

import re
import subprocess
import sys
import tempfile

from TestSim import TestSim


ROOT = "validation_"
STARTUP_WAIT = 100
FAILURE_WAIT = 250
SETTLE_WAIT = 5


def make_sim(topology, noise="no_noise.txt"):
    output = tempfile.TemporaryFile(mode="w+")
    sim = TestSim()
    sim.moteids = []
    sim.numMote = 0
    sim.loadTopo(ROOT + topology + ".topo")
    sim.loadNoise(noise)

    for node_id in sorted(sim.moteids):
        sim.bootNode(node_id)

    sim.addChannel(sim.COMMAND_CHANNEL, output)
    sim.addChannel(sim.GENERAL_CHANNEL, output)
    sim.runTime(STARTUP_WAIT)
    return sim, output


def route_dump(sim, output, node_id):
    output.seek(0)
    output.truncate(0)
    sim.routeDMP(node_id)
    sim.runTime(SETTLE_WAIT)
    return read_output(output)


def read_output(output):
    output.seek(0)
    return output.read()


def route(log, node_id, destination):
    pattern = (
        r"Node: %d accessible routes:.*?"
        r"Destination: %d Next hop: (\d+) Cost: (\d+)"
    ) % (node_id, destination)
    match = re.search(pattern, log, re.S)
    if not match:
        return None
    return int(match.group(1)), int(match.group(2))


def assert_route(log, node_id, destination, next_hop, cost):
    actual = route(log, node_id, destination)
    expected = (next_hop, cost)
    if actual != expected:
        raise AssertionError(
            "node %d route to %d: expected %s, got %s\n%s"
            % (node_id, destination, expected, actual, log)
        )


def assert_no_route(log, node_id, destination):
    if route(log, node_id, destination) is not None:
        raise AssertionError(
            "node %d unexpectedly still routes to %d\n%s"
            % (node_id, destination, log)
        )


def assert_log(log, text):
    if text not in log:
        raise AssertionError("expected log text %r\n%s" % (text, log))


def bidirectional_links(sim, links):
    for source, destination in links:
        sim.r.add(source, destination, -54.0)
        sim.r.add(destination, source, -54.0)


def remove_bidirectional(sim, source, destination):
    sim.r.remove(source, destination)
    sim.r.remove(destination, source)


def line():
    """1-2-3-4; route dumps and routed ping/reply in both directions."""
    sim, output = make_sim("line")
    log = route_dump(sim, output, 1)
    assert_route(log, 1, 4, 2, 3)
    log = route_dump(sim, output, 4)
    assert_route(log, 4, 1, 3, 3)

    sim.ping(1, 4, "line-forward")
    sim.runTime(SETTLE_WAIT)
    sim.ping(4, 1, "line-reverse")
    sim.runTime(SETTLE_WAIT)
    assert_log(read_output(output), "Ping Recieved from 1")
    assert_log(read_output(output), "Ping Recieved from 4")
    print "PASS line: bidirectional 1-2-3-4, startup=%d, settle=%d" % (
        STARTUP_WAIT, SETTLE_WAIT
    )


def alternative():
    """Two paths from 1 to 4; remove and restore the 2-4 link."""
    sim, output = make_sim("alternative")
    log = route_dump(sim, output, 1)
    assert_route(log, 1, 4, 2, 2)

    remove_bidirectional(sim, 2, 4)
    sim.runTime(FAILURE_WAIT)
    log = route_dump(sim, output, 1)
    assert_route(log, 1, 4, 3, 3)

    bidirectional_links(sim, [(2, 4)])
    sim.runTime(FAILURE_WAIT)
    log = route_dump(sim, output, 1)
    assert_route(log, 1, 4, 2, 2)
    print "PASS alternative: remove/restore 2-4, failure_wait=%d" % FAILURE_WAIT


def partition():
    """Break 5-6 in a ten-node line, then restore it."""
    sim, output = make_sim("partition")
    remove_bidirectional(sim, 5, 6)
    sim.runTime(FAILURE_WAIT)
    log = route_dump(sim, output, 1)
    assert_no_route(log, 1, 10)

    sim.ping(1, 10, "partitioned")
    sim.runTime(SETTLE_WAIT)
    assert_log(read_output(output), "No route to destination 10")

    bidirectional_links(sim, [(5, 6)])
    sim.runTime(FAILURE_WAIT)
    log = route_dump(sim, output, 1)
    assert_route(log, 1, 10, 2, 9)
    print "PASS partition: withdrawal and recovery, failure_wait=%d" % FAILURE_WAIT


def poison():
    """Exercise poison reverse on the 1-2-3 line.

    The current application does not print raw DV advertisements, so this
    scenario records the route state that drives the advertisement rule:
    node 1 reaches 3 through 2, while node 3 reaches 1 through 2.  The
    expected wire behavior is 1 advertising destination 3 as INF to 2 and
    destination 3 at finite cost to any other neighbor.
    """
    sim, output = make_sim("line")
    log = route_dump(sim, output, 1)
    assert_route(log, 1, 3, 2, 2)
    log = route_dump(sim, output, 3)
    assert_route(log, 3, 1, 2, 2)
    print "PASS poison: route state requires INF toward the current next hop"


def capacity():
    """Star topology: 1 has 12 destinations, requiring multiple DV packets."""
    sim, output = make_sim("capacity")
    log = route_dump(sim, output, 1)
    for destination in range(2, 14):
        assert_route(log, 1, destination, destination, 1)

    remove_bidirectional(sim, 1, 2)
    sim.runTime(FAILURE_WAIT)
    log = route_dump(sim, output, 1)
    assert_no_route(log, 1, 2)
    assert_route(log, 1, 13, 13, 1)
    print "PASS capacity: later-packet destinations survive unrelated omission"


def loss():
    """Use a documented lossy trace, then allow exchanges to recover."""
    sim, output = make_sim("line", "validation_loss.txt")
    sim.runTime(FAILURE_WAIT)
    log = route_dump(sim, output, 1)
    assert_route(log, 1, 4, 2, 3)
    print "PASS loss: route recovered after lossy startup/exchanges"


def lifetime():
    """Inject a TTL=1 routed packet from 1 toward 4; it expires at node 2."""
    sim, output = make_sim("line")
    packet = sim.t.newPacket()
    packet.setType(6)

    # AM_PACK payload is the generated pack structure:
    # dest, src, seq, TTL, protocol, payload.
    from packet import pack
    message = pack()
    message.set_dest(4)
    message.set_src(1)
    message.set_seq(60000)
    message.set_TTL(1)
    message.set_protocol(0)
    message.set_payload([0] * 20)
    packet.setData(message.data)
    packet.setDestination(2)
    packet.deliver(2, sim.t.time() + 5)
    sim.runTime(SETTLE_WAIT)
    assert_log(read_output(output), "Packet Dropped, TTL: 0")
    if "Ping Recieved from 4" in read_output(output):
        raise AssertionError("TTL-expired packet reached destination")
    print "PASS lifetime: TTL=1 expired before the three-hop path completed"


SCENARIOS = {
    "line": line,
    "alternative": alternative,
    "partition": partition,
    "poison": poison,
    "capacity": capacity,
    "loss": loss,
    "lifetime": lifetime,
}


def main():
    requested = sys.argv[1:] or ["all"]
    if "all" in requested:
        scenarios = ["line", "alternative", "partition", "poison",
                     "capacity", "loss", "lifetime"]
        status = 0
        for scenario in scenarios:
            status |= subprocess.call([sys.executable, sys.argv[0], scenario])
        raise SystemExit(status)

    failures = 0
    for name in requested:
        if name not in SCENARIOS:
            raise SystemExit("unknown scenario: %s" % name)
        try:
            SCENARIOS[name]()
        except AssertionError as error:
            failures += 1
            print "FAIL %s: %s" % (name, error)

    if failures:
        raise SystemExit("%d validation scenario(s) failed" % failures)


if __name__ == "__main__":
    main()
