#!/bin/bash
# Common lab prepare script

if [[ "$_RL_INTERNAL" != "rlrullz" ]]; then
	echo "ERROR: This script is not runnable!" >&2
	exit
fi

lab_cleanall

echo "Starting ContainerNet..."
lab_runTopology "$LAB_SRC/topology.py"

sleep 5
for name in red green blue; do
	ip li set dev veth-$name down
	docker exec mn.$name /bin/bash -c "ip link set dev $name-eth0 down"
done

function ex6() {
	ip a a 7.7.7.1 dev veth-red
	docker exec mn.red /bin/bash -c "ip a a 7.7.7.2/24 dev red-eth0 && ip link set dev red-eth0 up"
	ip li set dev veth-red up
}

function ex7() {
	ip a a 15.15.15.1 dev veth-blue
	docker exec mn.blue /bin/bash -c "ip a a 15.15.15.2/24 dev blue-eth0"
	ip li set dev veth-blue up
}

if [[ "$EX" == "ex6" ]]; then
	ex6

elif [[ "$EX" == "ex7" ]]; then
	ex7
fi

