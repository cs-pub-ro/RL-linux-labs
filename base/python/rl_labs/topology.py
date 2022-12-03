"""
Base RL Lab topology definitions.
"""

import argparse
import sys
import time
import signal

from mininet.net import Containernet
from mininet.node import Controller, RemoteController, OVSSwitch, Host
from mininet.log import setLogLevel, info, warn
from mininet.link import Link


RUNTIME_DIR = "/run/rl-labs"
NOTIFY_FILE = RUNTIME_DIR + "/.notify-started"
# CONTAINER_NAMES_FILE = RUNTIME_DIR + "/all-containers.txt"


class RLCustomLink(Link):
    """ Custom link class with workarounds. """

    def __init__(self, node1, node2, **kwargs):
        super().__init__(node1, node2, **kwargs )

    def makeIntfPair(self, intfname1, intfname2, addr1=None, addr2=None,
                     node1=None, node2=None, deleteIntfs=True):
        super().makeIntfPair(intfname1, intfname2, addr1, addr2,
                             node1, node2, deleteIntfs=deleteIntfs)
        # Need to reduce the MTU of the virtual interfaces (for cloud usage)
        node1.cmd('ip link set dev %s mtu 1450' % intfname1)
        node2.cmd('ip link set dev %s mtu 1450' % intfname2)


def build_controller(remote_controller=""):
    if not remote_controller:
        return Controller(name='c0', port=6633)
    else:
        conn_params = remote_controller.split(':')
        if len(conn_params) == 1:
            ctrl_port = 6633
        else:
            ctrl_port = int(conn_params[1])
        return RemoteController(name='c0', ip=conn_params[0], port=ctrl_port)
    

def build_container_net(options=None):
    """ Builds a ContainerNet network object. """
    if not options:
        options = {}

    remote_controller = options.pop("remote_controller", None)

    net = Containernet(waitConnected=True)
    net.addController(build_controller(remote_controller))

    return net


def rl_container(net, name, **options):
    DEFAULT_OPTIONS = {
        "dimage": "rlrules/base:latest",
        "dcmd": "/lib/systemd/systemd",
        "ip": '', "network_mode": 'none',
        # don't mount cgroup for systemd (for cgroups v2)
        # "volumes": ["/sys/fs/cgroup:/sys/fs/cgroup:ro"],
        "tmpfs": {"/tmp": "", "/run": "", "/run/lock": ""},
        "sysctls": {
            "net.ipv6.conf.all.disable_ipv6": "0"
        },
        "cap_add": ["sys_admin"],
        "persist": False,
    }
    STANDARD_CONTAINER_OPTIONS = {
        "red": {
            "hostname": "red",
            "environment": {"RL_PS1_FORMAT": "\\e[0;31m\\u@\\h:\\W\\$ \\e[m"}
        },
        "green": {
            "hostname": "green",
            "environment": {"RL_PS1_FORMAT": "\\e[0;32m\\u@\\h:\\W\\$ \\e[m"}
        },
        "blue": {
            "hostname": "blue",
            "environment": {"RL_PS1_FORMAT": "\\e[0;34m\\u@\\h:\\W\\$ \\e[m"}
        },
    }

    options = dict(DEFAULT_OPTIONS, **options)
    options = dict(STANDARD_CONTAINER_OPTIONS.get(name, {}), **options)

    return net.addDocker(name, **options)


def link_host_container(host, container):
    intfName1 = "veth-" + container.name
    intfName2 = container.name + "-eth0"
    return RLCustomLink(host, container, intfName1=intfName1, intfName2=intfName2)


def signal_topology_started():
    """ Writes the guard file to signal that the topoloy has been set up. """
    with open(NOTIFY_FILE, "w") as f:
        f.write("ContainerNet started!")


def entrypoint(build_func):
    setLogLevel('output')
    parser = argparse.ArgumentParser(description='Running modes')
    parser.add_argument('--remote-controller', action="store", dest="remote_controller", default='')
    parser.add_argument('--persist', action="store_true", dest="persist")
    params = parser.parse_args(sys.argv[1:])

    stopped = [False]

    # register SIGTERM handler (when ran as systemd service)
    def _sigterm_handler(*_):
        warn('SIGTERM received...')
        stopped[0] = True
    signal.signal(signal.SIGTERM, _sigterm_handler)

    net = build_func(vars(params))

    net.start()
    signal_topology_started()
    while not stopped[0]:
        try:
            time.sleep(0.5)
        except KeyboardInterrupt:
            try:
                warn('SIGINT received, stopping ContainerNet...')
            except Exception:
                # pylint: enable=broad-except
                pass
            break
    net.stop()

