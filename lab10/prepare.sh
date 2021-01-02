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

	@silent echo "Creating user ana on red"
	docker exec mn.red /bin/bash -c "/usr/sbin/userdel -r ana > /dev/null 2>&1 || true"
	docker exec mn.red /bin/bash -c "/usr/sbin/useradd -m -d /home/ana -s /bin/bash -l ana"
	docker exec mn.red /bin/bash -c "echo 'ana:student' | chpasswd"

	@silent echo "Creating user bogdan on host"
	/usr/sbin/userdel -r bogdan &>/dev/null || true 
	/usr/sbin/useradd -m -d /home/bogdan -s /bin/bash -l bogdan
	echo "bogdan:student" | chpasswd

	@silent echo "Creating user corina on host"
	/usr/sbin/userdel -r corina &>/dev/null || true 
	/usr/sbin/useradd -m -d /home/corina -s /bin/bash -l corina
	echo "corina:student" | chpasswd
}

function configure_apache(){

	#docker exec mn.red /bin/bash -c "apt update > /dev/null 2>&1"
	#docker exec mn.red /bin/bash -c "apt install -y apache2"
	docker exec mn.red /bin/bash -c "a2enmod ssl > /dev/null 2>&1"
	docker exec mn.red /bin/bash -c "a2ensite default-ssl > /dev/null 2>&1"
	docker exec mn.red /bin/bash -c "service apache2 restart > /dev/null 2>&1"

	
}

function create_artefacts(){

	configure_apache
	
	# http server home page
	docker exec mn.red /bin/bash -c "echo '<h1>Laborator 10 - pe red</h1>' > /var/www/html/index.html"
	# http? artefact
	docker exec mn.red /bin/bash -c "/bin/dd if=/dev/urandom of=/var/www/html/file.dat bs=1K count=1 > /dev/null 2>&1"

	# ftp files hierarchy
	# TODO: to bring these specs to the current century 
	docker exec mn.red /bin/bash -c "mkdir -p /var/www/html/folder/mobile/Google/Nexus4/"
	docker exec mn.red /bin/bash -c "echo '1.512 GHz quad-core Krait' > /var/www/html/folder/mobile/Google/Nexus4/info.txt"
	docker exec mn.red /bin/bash -c "mkdir -p /var/www/html/folder/mobile/Google/Nexus7/"
	docker exec mn.red /bin/bash -c "echo 'ARM Cortex-A9 Nvidia Tegra 3 T30L 1.2 GHz quad-core (1.3 GHz single-core mode) 1MB L2 cache' > /var/www/html/folder/mobile/Google/Nexus7/info.txt"
	docker exec mn.red /bin/bash -c "mkdir -p /var/www/html/folder/mobile/Apple/iPhone5S/"
	docker exec mn.red /bin/bash -c "echo '1.3 GHz dual-core Apple-designed ARMv8-A 64-bit Apple A7 with M7 motion coprocessor' > /var/www/html/folder/mobile/Apple/iPhone5S/info.txt"
	docker exec mn.red /bin/bash -c "mkdir -p /var/www/html/folder/mobile/Apple/iPadAir/"
	docker exec mn.red /bin/bash -c "echo '1.4 GHz dual-core Apple Cyclone' > /var/www/html/folder/mobile/Apple/iPadAir/info.txt"
	docker exec mn.red /bin/bash -c "mkdir -p /var/www/html/folder/embedded/Qualcomm/Scorpion/"
	docker exec mn.red /bin/bash -c "echo 'Single or dual-core configuration; 2.1 DMIPS/MHz' > /var/www/html/folder/embedded/Qualcomm/Scorpion/info.txt"
	docker exec mn.red /bin/bash -c "mkdir -p /var/www/html/folder/embedded/Qualcomm/Krait/"
	docker exec mn.red /bin/bash -c "echo 'Dual or quad-core configurations; 3.3 DMIPS/Mhz' > /var/www/html/folder/embedded/Qualcomm/Krait/info.txt"
	docker exec mn.red /bin/bash -c "mkdir -p /var/www/html/folder/embedded/TI/OMAP3/"
	docker exec mn.red /bin/bash -c "echo 'i1.2 GHz ARM Cortex-A8' > /var/www/html/folder/embedded/TI/OMAP3/info.txt"
	docker exec mn.red /bin/bash -c "mkdir -p /var/www/html/folder/embedded/TI/OMAP4/"
	docker exec mn.red /bin/bash -c "echo '1.3-1.5 GHz dual-core ARM Cortex-A9' > /var/www/html/folder/embedded/TI/OMAP4/info.txt"


	# content for URL with special chars
	docker exec mn.red /bin/bash -c 'cat > /var/www/html/login.php <<-END
	<html>
	<body>

	Welcome <?php echo \$_GET["name"]; ?><br>
	Your email address is: <?php echo \$_GET["email"]; ?>
	</body>
	</html>
	END'

	# content for FTP download
	docker exec mn.red /bin/bash -c "mkdir -p /srv/ftp/download"
	docker exec mn.red /bin/bash -c "/bin/dd if=/dev/urandom of=/srv/ftp/download/file-10M.dat bs=1M count=10 > /dev/null 2>&1"

	docker exec mn.red /bin/bash -c "/bin/dd if=/dev/urandom of=/home/ana/ana-ftp-file-5M.dat bs=1M count=5 > /dev/null 2>&1"
	docker exec mn.red /bin/bash -c "/bin/chown ana:ana /home/ana/ana-ftp-file-5M.dat"

	# content for FTP upload
	/bin/dd if=/dev/urandom of=/home/bogdan/bogdan-ftp-file-3M.dat bs=1M count=3 > /dev/null 2>&1
	/bin/chown bogdan:bogdan /home/bogdan/bogdan-ftp-file-3M.dat

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

addressing
nameservice
etc_hosts
internet_connectivity
user_management
create_artefacts
share_ssh_keys
