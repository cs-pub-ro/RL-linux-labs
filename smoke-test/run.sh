#!/bin/bash

#TODO add variables for IPs
#TODO for host in {red,green,blue}; do <>; done
#TODO ping -c ; $?

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
    exit 10
fi

if [ "$1" = 'add' ]; then
 echo "HOST IPv4 config"
 ip add add 10.100.10.1/24 dev veth-red   
 ip add add 10.100.20.1/24 dev veth-green 
 ip add add 10.100.30.1/24 dev veth-blue  

 echo "HOST IPv6 config"
 ip -6 address add 2210::1/64 dev veth-red
 ip -6 address add 2220::1/64 dev veth-green
 ip -6 address add 2230::1/64 dev veth-blue

 echo "VirtHOST IPv4 config"
 docker exec -it mn.red bash -c "ip add add 10.100.10.10/24 dev red-eth0"
 docker exec -it mn.red bash -c "ip route add default via 10.100.10.1"
 docker exec -it mn.green bash -c "ip add add 10.100.20.10/24 dev green-eth0"
 docker exec -it mn.green bash -c "ip route add default via 10.100.20.1"  
 docker exec -it mn.blue bash -c "ip add add 10.100.30.10/24 dev blue-eth0"   
 docker exec -it mn.blue bash -c "ip route add default via 10.100.30.1"  

 echo "VirtHOST IPv6 config"
 docker exec -it mn.red bash -c "ip -6 add add 2210::10/64 dev red-eth0"
 #docker exec -it mn.red bash -c "ip -6 route add 2210::/64 dev red-eth0"  
 docker exec -it mn.red bash -c "ip -6 route add default via 2210::1"

 docker exec -it mn.green bash -c "ip -6 add add 2220::10/64 dev green-eth0"   
 #docker exec -it mn.green bash -c "ip -6 route add 2220::/64 dev green-eth0"   
 docker exec -it mn.green bash -c "ip -6 route add default via 2220::1"   
 
 docker exec -it mn.blue bash -c "ip -6 add add 2230::10/64 dev blue-eth0"   
 #docker exec -it mn.blue bash -c "ip -6 route add 2230::/64 dev blue-eth0"   
 docker exec -it mn.blue bash -c "ip -6 route add default via 2230::1"   

 echo "IPv4 forwarding on host"
 sysctl -w net.ipv4.ip_forward=1

 echo "IPv6 forwarding on host"
 sysctl -w net.ipv6.conf.all.forwarding=1

 echo "Establishing PAT for IPv4 internet access"
 iptables -t nat -A POSTROUTING -j MASQUERADE

 echo "Establishing PAT for IPv6 internet access"
 ip6tables -t nat -A POSTROUTING -j MASQUERADE


 #Test suite:

 echo "Testing IPv4 connectivity to the default gateway"
 docker exec -it mn.red bash -c "ping -c 2 10.100.10.1"  
 docker exec -it mn.green bash -c "ping -c 2 10.100.20.1"   
 docker exec -it mn.blue bash -c "ping -c 2 10.100.30.1"   

 echo "Testing IPv6 connectivity to the default gateway"
 docker exec -it mn.red bash -c "ping6 -c 2 2210::1"  
 docker exec -it mn.green bash -c "ping6 -c 2 2220::1"   
 docker exec -it mn.blue bash -c "ping6 -c 2 2230::1"   

 echo "Testing IPv4 connectivity between containers"
 docker exec -it mn.red bash -c "ping -c 2 10.100.20.10"  
 docker exec -it mn.red bash -c "ping -c 2 10.100.30.10"  
 docker exec -it mn.green bash -c "ping -c 2 10.100.10.10"   
 docker exec -it mn.green bash -c "ping -c 2 10.100.30.10"   
 docker exec -it mn.blue bash -c "ping -c 2 10.100.10.10"   
 docker exec -it mn.blue bash -c "ping -c 2 10.100.20.10"   

 echo "Testing IPv6 connectivity between containers"
 docker exec -it mn.red bash -c "ping6 -c 2 2220::10"  
 docker exec -it mn.red bash -c "ping6 -c 2 2230::10"  
 docker exec -it mn.green bash -c "ping6 -c 2 2210::10"   
 docker exec -it mn.green bash -c "ping6 -c 2 2230::10"   
 docker exec -it mn.blue bash -c "ping6 -c 2 2210::10"   
 docker exec -it mn.blue bash -c "ping6 -c 2 2220::10"   

elif [ "$1" = 'clean' ]; then
 echo "clean IPv4 HOST config"
 ip add del 10.100.10.1/24 dev veth-red   
 ip add del 10.100.20.1/24 dev veth-green 
 ip add del 10.100.30.1/24 dev veth-blue  

 echo "clean IPv6 HOST config"
 ip -6 address del 2210::1/64 dev veth-red
 ip -6 address del 2220::1/64 dev veth-green
 ip -6 address del 2230::1/64 dev veth-blue

 echo "Clean IPv4 VirtHOST config"
 docker exec -it mn.red bash -c "ip route del default via 10.100.10.1"  
 docker exec -it mn.red bash -c "ip add del 10.100.10.10/24 dev red-eth0"   
 docker exec -it mn.green bash -c "ip route del default via 10.100.20.1"  
 docker exec -it mn.green bash -c "ip add del 10.100.20.10/24 dev green-eth0"   
 docker exec -it mn.blue bash -c "ip route del default via 10.100.30.1"  
 docker exec -it mn.blue bash -c "ip add del 10.100.30.10/24 dev blue-eth0"   

 echo "Clean IPv6 VirtHOST config"
 docker exec -it mn.red bash -c "ip -6 route del default via 2210::1"  
 #docker exec -it mn.red bash -c "ip -6 route del 2210::/64 dev red-eth0"  
 docker exec -it mn.red bash -c "ip -6 add del 2210::10/64 dev red-eth0"   
 
 docker exec -it mn.green bash -c "ip -6 route del default via 2220::1"   
 #docker exec -it mn.green bash -c "ip -6 route 2220::/64 dev green-eth0"   
 docker exec -it mn.green bash -c "ip -6 add del 2220::10/64 dev green-eth0"   
 
 docker exec -it mn.blue bash -c "ip -6 route del default via 2230::1"
 #docker exec -it mn.blue bash -c "ip -6 route 2230::/64 dev blue-eth0"   
 docker exec -it mn.blue bash -c "ip -6 add del 2230::10/64 dev blue-eth0"   

 echo "Disable IPv4 forwarding on host"
 sysctl -w net.ipv4.ip_forward=0

 echo "Disable IPv6 forwarding on host"
 sysctl -w net.ipv6.conf.all.forwarding=0

 echo "Disable IPv4 PAT"
 iptables -t nat -D POSTROUTING -j MASQUERADE

 echo "Disable IPv6 PAT for IPv6"
 ip6tables -t nat -D POSTROUTING -j MASQUERADE


else
  echo "Illegal parameter"
	exit 11
fi
