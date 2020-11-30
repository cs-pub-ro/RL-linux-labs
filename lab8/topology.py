from mininet.net import Containernet
from mininet.node import Controller, RemoteController, OVSSwitch, Host
from mininet.cli import CLI
from mininet.log import setLogLevel, info
from mininet.link import Intf, Link
import argparse
import sys


def rl_lab_network(remote_controller=""):

    net = Containernet()
    info('*** Adding controller\n')

    if not remote_controller:
        c = Controller(name='c0', port=6633)
    
    else:
        conn_params = remote_controller.split(':')
        if len(conn_params) == 1:
            ctrl_port = 6633
        else:
            ctrl_port = int(conn_params[1])
        c = RemoteController(name='c0', ip=conn_params[0], port=ctrl_port)
    
    net.addController(c)

    info('*** Adding virtual hosts\n')
    docker_img = 'rlrules/lab8:latest'
    network_mode = 'none'

    root = Host( 'root', inNamespace=False )

    hostr = net.addDocker(
        'red', dimage=docker_img, ip='', network_mode=network_mode, 
        hostname='red', 
        environment={"RL_PS1_FORMAT": "\\e[0;31m\\u@\\h:\\W\\$ \\e[m"})
    hostg = net.addDocker(
        'green', dimage=docker_img, ip='', network_mode=network_mode, 
        hostname='green',
        environment={"RL_PS1_FORMAT": "\\e[0;32m\\u@\\h:\\W\\$ \\e[m"})
    hostb = net.addDocker(
        'blue', dimage=docker_img, ip='', network_mode=network_mode, 
        hostname='blue',
        environment={"RL_PS1_FORMAT": "\\e[0;34m\\u@\\h:\\W\\$ \\e[m"})

    info('*** Connecting hardware interfaces\n')
    Link(root, hostr, intfName1="veth-red", intfName2="red-eth0")
    Link(root, hostg, intfName1="veth-green", intfName2="green-eth0")
    Link(root, hostb, intfName1="veth-blue", intfName2="blue-eth0")

    info('*** Enable IPv6 on virtual hosts\n')
    ipv6_sysctl_cmd = 'sysctl -w net.ipv6.conf.all.disable_ipv6=0'
    hostr.cmd(ipv6_sysctl_cmd)
    hostg.cmd(ipv6_sysctl_cmd)
    hostb.cmd(ipv6_sysctl_cmd)

    info('*** Set PS1\n')
    set_ps1_cmd = '/bin/bash /usr/local/bin/setprompt.sh'
    hostr.cmd(set_ps1_cmd)
    hostg.cmd(set_ps1_cmd)
    hostb.cmd(set_ps1_cmd)

    info('*** Start sshd\n')
    sshd_bash_cmd = '/bin/bash /usr/local/bin/startsshd.sh'
    hostr.cmd(sshd_bash_cmd)
    hostg.cmd(sshd_bash_cmd)
    hostb.cmd(sshd_bash_cmd)

    info('*** Start vsftpd\n')
    sshd_bash_cmd = '/bin/bash /usr/local/bin/vsftpd.sh'
    hostr.cmd(sshd_bash_cmd)
    hostg.cmd(sshd_bash_cmd)
    hostb.cmd(sshd_bash_cmd)

    info('*** Start telnetd\n')
    sshd_bash_cmd = '/bin/bash /usr/local/bin/telnetd.sh'
    hostr.cmd(sshd_bash_cmd)
    hostg.cmd(sshd_bash_cmd)
    hostb.cmd(sshd_bash_cmd)



    info('*** Starting network\n')
    net.start()
    #info('*** Running CLI\n')

    #CLI(net)
    #info('*** Stopping network')
    #net.stop()
    
if __name__ == '__main__':
    setLogLevel( 'info' )
    
    parser = argparse.ArgumentParser(description='Running modes')

    parser.add_argument('--remote-controller', action="store", dest="remote_controller", default='')
    params = parser.parse_args(sys.argv[1:])
    
    rl_lab_network(remote_controller=params.remote_controller)
    
