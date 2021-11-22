#!/bin/bash
# Common lab prepare script

if [[ "$_RL_INTERNAL" != "rlrullz" ]]; then
	echo "ERROR: This script is not runnable!" >&2
	exit
fi

lab_cleanall

lab_runTopology "$LAB_SRC/topology.py"

index=1
for name in red green blue; do
	lab_gen_etc_hosts "$name" \
		'192.168.1.2 red' '192.168.2.2 green' \
		'192.168.3.2 blue' "192.168.$index.1 host" \
		| docker exec -i mn.$name /bin/bash -c "cp /dev/stdin /etc/hosts"
	ip li set dev veth-$name down
	docker exec mn.$name /bin/bash -c "ip link set dev $name-eth0 down"
	((index=index+1))
done

lab_gen_etc_hosts host \
	'192.168.1.2 red' '192.168.2.2 green' \
	'192.168.3.2 blue' > /etc/hosts

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

