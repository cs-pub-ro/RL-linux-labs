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

function user_management(){

	@silent echo "Creating user ana on host"
	# create user ana on host
	/usr/sbin/userdel -r ana &>/dev/null || true 
	/usr/sbin/useradd -m -d /home/ana -s /bin/bash -l ana
	echo "ana:student" | chpasswd
	/bin/mkdir -p /home/ana/.ssh
	/bin/chown -R ana:ana /home/ana/.ssh/
	#/bin/chmod 777 /home/ana/.ssh/ # this debugging exercise has been deleted, but it can be utilized for ex 12 demo, for extra debugging

	@silent echo "Creating user bogdan on blue"
	# create user bogdan on blue
	#docker exec mn.blue /bin/bash -c "/usr/sbin/userdel -r bogdan > /dev/null 2>&1"
	docker exec mn.blue /bin/bash -c "/usr/sbin/useradd -m -d /home/bogdan -s /bin/bash -l bogdan"
	docker exec mn.blue /bin/bash -c "echo 'bogdan:student' | chpasswd"
	docker exec mn.blue /bin/bash -c "bin/su - bogdan -c '/bin/mkdir ~/.ssh; /usr/bin/ssh-keygen -q -t rsa -N \"\" -f ~/.ssh/id_rsa'"

	@silent echo "Creating user corina on blue"
	# create user corina on blue
	#docker exec mn.blue /bin/bash -c "/usr/sbin/userdel -r corina > /dev/null 2>&1"
	docker exec mn.blue /bin/bash -c "/usr/sbin/useradd -m -d /home/corina -s /bin/bash -l corina"
	docker exec mn.blue /bin/bash -c "echo 'corina:student' | chpasswd"
}

function create_artefacts(){
	
	# Create large file in student@green'.
	docker exec mn.green /bin/bash -c "/bin/dd if=/dev/urandom of=/home/student/file-100M.dat bs=1M count=100 > /dev/null 2>&1"
	docker exec mn.green /bin/bash -c "/bin/chown student:student ~student/file-100M.dat > /dev/null 2>&1"

	# Create 10M files in student@host
	/bin/dd if=/dev/urandom of=/home/student/host-file-10M.dat bs=1M count=10 > /dev/null 2>&1
	/bin/chown student:student /home/student/host-file-10M.dat
	# Create 10M files in corina@blue
	docker exec mn.blue /bin/bash -c "/bin/dd if=/dev/urandom of=/home/corina/blue-file-10M.dat bs=1M count=10 > /dev/null 2>&1"
	docker exec mn.blue /bin/bash -c "/bin/chown corina:corina ~corina/blue-file-10M.dat"

	# Create folders in student@host.
	/bin/rm -fr /home/student/assignment
	/bin/mkdir /home/student/assignment
	echo "x - 1 = 0" > /home/student/assignment/linear.txt
	echo "x^2 - 3x + 2 = 0" > /home/student/assignment/quadratic.txt
	echo "x^3 - 6x^2 + 11x -6 = 0" > /home/student/assignment/cubic.txt
	/bin/chown -R student:student /home/student/assignment
	# Create folders in corina@blue.
	docker exec mn.blue /bin/bash -c '/bin/rm -fr /home/corina/solution'
	docker exec mn.blue /bin/bash -c '/bin/mkdir /home/corina/solution'
	docker exec mn.blue /bin/bash -c 'echo "x = 1" > /home/corina/solution/linear.txt'
	docker exec mn.blue /bin/bash -c 'echo "x1 = 1, x2 = 2" > /home/corina/solution/quadratic.txt'
	docker exec mn.blue /bin/bash -c 'echo "x1 = 1, x2 = 2, x3 = 3" > /home/corina/solution/cubic.txt'
	docker exec mn.blue /bin/bash -c '/bin/chown -R corina:corina ~corina/solution'

    	# Ana proiecte
        /bin/rm -fr /home/ana/proiecte
        /bin/mkdir /home/ana/proiecte
        echo "ana" > /home/ana/proiecte/ana.txt
        echo "are" > /home/ana/proiecte/are.txt
        echo "mere" > /home/ana/proiecte/mere.txt
        /bin/chown -R ana:ana /home/ana/proiecte


}

function share_ssh_keys(){

  > /tmp/authorized_keys_root
  > /tmp/authorized_keys_student
  for name in red green blue; do

	docker exec -t --user student mn.$name /bin/bash -c "/bin/mkdir ~/.ssh; /usr/bin/ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa"
	docker exec -t mn.$name /bin/bash -c "/bin/mkdir ~/.ssh; /usr/bin/ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa"

	docker exec --user=student -t mn.$name /bin/bash -c "cat ~/.ssh/id_rsa.pub" >> /tmp/authorized_keys_student
	docker exec -t mn.$name /bin/bash -c "cat ~/.ssh/id_rsa.pub" >> /tmp/authorized_keys_root
  done

  for name in red green blue; do
	docker cp /tmp/authorized_keys_root mn.$name:/root/.ssh/authorized_keys
	docker cp /tmp/authorized_keys_student mn.$name:/home/student/.ssh/authorized_keys
	docker exec mn.$name /bin/bash -c '/bin/chown -R student:student /home/student/.ssh/authorized_keys'
  done
  
  rm -f t/tmp/authorized_keys_*

}

#la8 - internet connectivity and artefacts
addressing
nameservice
etc_hosts
#internet_connectivity
user_management
#create_artefacts
share_ssh_keys
