#!/bin/bash
# Common lab prepare script

if [[ "$_RL_INTERNAL" != "rlrullz" ]]; then
	echo "ERROR: This script is not runnable!" >&2
	exit
fi

lab_cleanall

lab_runTopology "$LAB_SRC/topology.py"

for name in red green blue; do
	ip li set dev veth-$name down
	docker exec mn.$name /bin/bash -c "ip link set dev $name-eth0 down"
done

function addressing(){
  index=1;
  for name in red green blue; do
	@silent echo "For container $name third byte is $index"

	# removing any residual IP v4 config
	docker exec mn.$name /bin/bash -c "ip address flush dev $name-eth0"
	/bin/bash -c "ip address flush veth-$name"

	# activating network interfaces 
	docker exec mn.$name /bin/bash -c "ip link set dev $name-eth0 up"
	/bin/bash -c "ip link set dev veth-$name up"

	# establishig connectivity
	docker exec mn.$name /bin/bash -c "ip address add 192.168.$index.2/24 dev $name-eth0"
	docker exec mn.$name /bin/bash -c "ip route add default via 192.168.$index.1"
	/bin/bash -c "ip address add 192.168.$index.1/24 dev veth-$name"

	((index=index+1))
  done
}

function nameservice(){

  for name in red green blue; do
	docker exec mn.$name /bin/bash -c "echo nameserver 8.8.8.8 >  /etc/resolv.conf"
  done
}

function etc_hosts(){

  index=1;
  for name in red green blue; do
        #read -r -d '' etc_hosts_var << EOF
        etc_hosts_var=`cat <<-EOF
	127.0.0.1   localhost
	192.168.1.2 red
	192.168.2.2 green
	192.168.3.2 blue
	192.168.$index.1 host

	# The following lines are desirable for IPv6 capable hosts
	::1     ip6-localhost ip6-loopback
	fe00::0 ip6-localnet
	ff00::0 ip6-mcastprefix
	ff02::1 ip6-allnodes
	ff02::2 ip6-allrouters
	EOF`

	docker exec mn.$name /bin/bash -c "echo \"$etc_hosts_var\" > /etc/hosts"

        ((index=index+1))
  done

	cat > /etc/hosts <<-EOF 
	127.0.0.1   localhost
	192.168.1.2 red
	192.168.2.2 green
	192.168.3.2 blue
	127.0.0.1   host

	# The following lines are desirable for IPv6 capable hosts
	::1     ip6-localhost ip6-loopback
	fe00::0 ip6-localnet
	ff00::0 ip6-mcastprefix
	ff02::1 ip6-allnodes
	ff02::2 ip6-allrouters
	EOF
}

function internet_connectivity(){
	/sbin/sysctl -q -w net.ipv4.ip_forward=1
	/sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
}

function tools_management(){

	apt update && apt install -y elinks whois nmap

	docker exec mn.red /bin/bash -c "apt update && apt install -y apache2"
	docker exec mn.red /bin/bash -c "service apache2 start"

	docker exec mn.green /bin/bash -c "apt update && apt install -y python3 python3-pip"
	docker exec mn.green /bin/bash -c "pip3 install slowloris"
	
}

function ex12(){
	
}

if [[ "$EX" == "ex12" ]]; then
	ex12

fi

addressing
nameservice
etc_hosts
internet_connectivity
