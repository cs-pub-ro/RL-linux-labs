from mininet.node import Host
from rl_labs.topology import (
    get_default_net, standard_container, entrypoint, link_host_container,
    signal_topology_started
)


def lab10_main(options=None):
    net = get_default_net(options)

    hroot = Host('host', inNamespace=False)
    hred = standard_container(net, "red")
    hgreen = standard_container(net, "green")
    hblue = standard_container(net, "blue")

    link_host_container(hroot, hred)
    link_host_container(hroot, hgreen)
    link_host_container(hroot, hblue)

    net.start()
    signal_topology_started()


if __name__ == '__main__':
    entrypoint(lab10_main)

