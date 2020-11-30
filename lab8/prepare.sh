#!/bin/bash
# Common lab prepare script

if [[ "$_RL_INTERNAL" != "rlrullz" ]]; then
	echo "ERROR: This script is not runnable!" >&2
	exit
fi

lab_cleanall

echo "Starting ContainerNet..."
lab_runTopology "$LAB_SRC/topology.py"

while ! check_container "mn.red"; do sleep 1; done 
while ! check_container "mn.green"; do sleep 1; done 
while ! check_container "mn.blue"; do sleep 1; done 
sleep 2
for name in red green blue; do
	ip li set dev veth-$name down
	docker exec mn.$name /bin/bash -c "ip link set dev $name-eth0 down"
done

function addressing(){

  index=1;
  for name in red green blue; do
	echo "For container $name third byte is $index"

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
        echo "For container $name third byte is $index"

        #read -r -d '' etc_hosts_var << EOF
        etc_hosts_var=`cat << EOF
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

}


addressing
nameservice
etc_hosts
