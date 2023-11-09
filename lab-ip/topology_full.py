from mininet.node import Host
from mininet.node import OVSSwitch
from mininet.link import Intf
from rl_labs.topology import (
    get_default_net, standard_container, entrypoint, link_host_container
)


def lab_full_bridge(options=None):
    net = get_default_net(options)

    hred = standard_container(net, "red")
    hgreen = standard_container(net, "green")
    hblue = standard_container(net, "blue")

    switch_class = OVSSwitch
    sr = net.addSwitch('s1', cls=switch_class)
    sg = net.addSwitch('s2', cls=switch_class)
    sb = net.addSwitch('s3', cls=switch_class)

    net.addLink(hred, sr)
    net.addLink(hgreen, sg)
    net.addLink(hblue, sb)

    Intf("vff0000", node=sr)
    Intf("v00ff00", node=sg)
    Intf("v0000ff", node=sb)

    net.start()


if __name__ == '__main__':
    entrypoint(lab_full_bridge)

