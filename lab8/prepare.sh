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
	docker exec mn.$name sudo /bin/bash -c "ip link set dev $name-eth0 down"
done

function addressing(){

  index=1;
  for name in red green blue; do
	echo "For container $name third byte is $index"

	# removing any residual IP v4 config
	docker exec mn.$name sudo /bin/bash -c "ip address flush dev $name-eth0"
	/bin/bash -c "ip address flush veth-$name"

	# activating network interfaces 
	docker exec mn.$name sudo /bin/bash -c "ip link set dev $name-eth0 up"
	/bin/bash -c "ip link set dev veth-$name up"

	# establishig connectivity
	docker exec mn.$name sudo /bin/bash -c "ip address add 192.168.$index.2/24 dev $name-eth0"
	docker exec mn.$name sudo /bin/bash -c "ip route add default via 192.168.$index.1"
	/bin/bash -c "ip address add 192.168.$index.1/24 dev veth-$name"

	((index=index+1))
  done
}

function nameservice(){

  for name in red green blue; do
	docker exec mn.$name sudo /bin/bash -c "echo nameserver 8.8.8.8 >  /etc/resolv.conf"
  done
}

function etc_hosts(){

  index=1;
  for name in red green blue; do
        echo "For container $name third byte is $index"

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

	docker exec mn.$name sudo /bin/bash -c "echo \"$etc_hosts_var\" > /etc/hosts"

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

function user_management(){

	echo "Creating user ana on host"
	# create user ana on host
	/usr/sbin/userdel -r ana || true  
	/usr/sbin/useradd -m -d /home/ana -s /bin/bash -l ana
	echo "ana:student" | chpasswd
	/bin/mkdir -p /home/ana/.ssh
	/bin/chown -R ana:ana /home/ana/.ssh/
	/bin/chmod 777 /home/ana/.ssh/

	echo "Creating user bogdan on blue"
	# create user bogdan on blue
	#docker exec mn.blue sudo /bin/bash -c "/usr/sbin/userdel -r bogdan > /dev/null 2>&1"
	docker exec mn.blue sudo /bin/bash -c "/usr/sbin/useradd -m -d /home/bogdan -s /bin/bash -l bogdan"
	docker exec mn.blue sudo /bin/bash -c "echo 'bogdan:student' | chpasswd"
	docker exec mn.blue sudo /bin/bash -c "bin/su - bogdan -c '/bin/mkdir ~/.ssh; /usr/bin/ssh-keygen -q -t rsa -N \"\" -f ~/.ssh/id_rsa'"

	echo "Creating user corina on blue"
	# create user corina on blue
	#docker exec mn.blue sudo /bin/bash -c "/usr/sbin/userdel -r corina > /dev/null 2>&1"
	docker exec mn.blue sudo /bin/bash -c "/usr/sbin/useradd -m -d /home/corina -s /bin/bash -l corina"
	docker exec mn.blue sudo /bin/bash -c "echo 'corina:student' | chpasswd"
}


addressing
nameservice
etc_hosts
internet_connectivity
user_management
