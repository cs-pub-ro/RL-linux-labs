from mininet.node import Host

from rl_labs.topology import (
    build_container_net, rl_container, entrypoint, link_host_container
)


def lab_prepare(options=None):
    net = build_container_net(options)

    container_opts = {
        "dimage": "rlrules/lab-mitm:latest",
        "persist": options.get("persist", False),
        "cap_add": ["CAP_NET_RAW"],
    }

    hroot = Host('host', inNamespace=False)
    hred = rl_container(net, "red", **container_opts)
    hgreen = rl_container(net, "green", **container_opts)
    hblue = rl_container(net, "blue", **container_opts)

    link_host_container(hroot, hred)
    link_host_container(hroot, hgreen)
    link_host_container(hroot, hblue)

    return net

if __name__ == '__main__':
    entrypoint(lab_prepare)

