"""
Base RL Lab topology definitions.
"""

import argparse
import sys

from mininet.net import Containernet
from mininet.node import Controller, RemoteController, OVSSwitch, Host
from mininet.cli import CLI
from mininet.log import setLogLevel, info
from mininet.link import Intf, Link


GUARD_FILE = "/tmp/.containernet-init"


def get_controller(remote_controller=""):
    if not remote_controller:
        return Controller(name='c0', port=6633)
    else:
        conn_params = remote_controller.split(':')
        if len(conn_params) == 1:
            ctrl_port = 6633
        else:
            ctrl_port = int(conn_params[1])
        return RemoteController(name='c0', ip=conn_params[0], port=ctrl_port)
    

def get_default_net(options=None):
    """ """
    if not options:
        options = {}

    net = Containernet()
    remote_controller = options.get("remote_controller", None)
    net.addController(get_controller(remote_controller))

    return net


def standard_container(net, name, options=None):
    DEFAULT_OPTIONS = {
        "dimage": "rlrules/base:latest",
        "dcmd": "/lib/systemd/systemd",
        "ip": '', "network_mode": 'none',
        # mount cgroup for systemd
        "volumes": ["/sys/fs/cgroup:/sys/fs/cgroup:ro"],
        "sysctls": {
            "net.ipv6.conf.all.disable_ipv6": "0"
        }
    }
    CONTAINER_OPTIONS = {
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

    if not options:
        options = DEFAULT_OPTIONS
    else:
        options = dict(DEFAULT_OPTIONS, **options)
    options = dict(CONTAINER_OPTIONS.get(name, {}), **options)

    return net.addDocker(name, **options)


def link_host_container(host, container):
    intfName1 = "veth-" + container.name
    intfName2 = container.name + "-eth0"
    return Link(host, container, intfName1=intfName1, intfName2=intfName2)


def signal_topology_started():
    """ Writes the guard file to signal that the topoloy has been set up. """
    with open(GUARD_FILE, "w") as f:
        f.write("Containernet started!")


def entrypoint(main_func):
    setLogLevel('output')
    parser = argparse.ArgumentParser(description='Running modes')
    parser.add_argument('--remote-controller', action="store", dest="remote_controller", default='')
    params = parser.parse_args(sys.argv[1:])
    
    main_func(vars(params))
    
