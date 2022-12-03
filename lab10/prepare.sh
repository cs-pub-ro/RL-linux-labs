#!/bin/bash
# Lab 10 prepare script

if [[ "$_RL_INTERNAL" != "rlrullz" ]]; then
	echo "ERROR: This script is not runnable!" >&2
	exit
fi

# all configurable containers
declare -a RL_CFG_CONTAINERS=(red green blue)
# bash array with container/interface IPs
declare -A RL_CFG_IPS=(
	['host/veth-red']="192.168.1.1/24"
	['host/veth-green']="192.168.2.1/24"
	['host/veth-blue']="192.168.3.1/24"
	['red/red-eth0']="192.168.1.2/24"
	['green/green-eth0']="192.168.2.2/24"
	['blue/blue-eth0']="192.168.3.2/24"
)
RL_CFG_DNS="8.8.8.8"


function lab_create_users(){
	@silent echo "Creating user ana on red"
	rl_ctexec --shell red "/usr/sbin/userdel -r ana > /dev/null 2>&1 || true"
	rl_ctexec --shell red "/usr/sbin/useradd -m -d /home/ana -s /bin/bash -l ana"
	rl_ctexec --shell red "echo 'ana:student' | chpasswd"

	@silent echo "Creating user bogdan on host"
	userdel -r bogdan &>/dev/null || true 
	useradd -m -d /home/bogdan -s /bin/bash -l bogdan
	echo "bogdan:student" | chpasswd

	@silent echo "Creating user corina on host"
	userdel -r corina &>/dev/null || true 
	useradd -m -d /home/corina -s /bin/bash -l corina
	echo "corina:student" | chpasswd
}

function lab_configure_apache(){
	rl_ctexec --shell red "a2enmod ssl > /dev/null 2>&1"
	rl_ctexec --shell red "a2ensite default-ssl > /dev/null 2>&1"
	rl_ctexec --shell red "systemctl restart apache2 > /dev/null 2>&1"

	export DEBIAN_FRONTEND=noninteractive
	apt-get update && apt-get install -y libapache2-mod-php
	systemctl restart apache2
}

function lab_create_artifacts(){
	# ftp files hierarchy
	rl_ctexec --shell red - <<-ENDBASHSCRIPT
	# http server home page
	echo '<h1>Laborator 10 - pe red</h1>' > /var/www/html/index.html
	# http artifact
	/bin/dd if=/dev/urandom of=/var/www/html/file.dat bs=1K count=1 > /dev/null 2>&1

	# TODO: bring these specs to the current century 
	mkdir -p /var/www/html/folder/mobile/Google/Nexus4/
	echo '1.512 GHz quad-core Krait' > /var/www/html/folder/mobile/Google/Nexus4/info.txt
	mkdir -p /var/www/html/folder/mobile/Google/Nexus7/
	echo 'ARM Cortex-A9 Nvidia Tegra 3 T30L 1.2 GHz quad-core (1.3 GHz single-core mode) 1MB L2 cache' > /var/www/html/folder/mobile/Google/Nexus7/info.txt
	mkdir -p /var/www/html/folder/mobile/Apple/iPhone5S/
	echo '1.3 GHz dual-core Apple-designed ARMv8-A 64-bit Apple A7 with M7 motion coprocessor' > /var/www/html/folder/mobile/Apple/iPhone5S/info.txt
	mkdir -p /var/www/html/folder/mobile/Apple/iPadAir/
	echo '1.4 GHz dual-core Apple Cyclone' > /var/www/html/folder/mobile/Apple/iPadAir/info.txt
	mkdir -p /var/www/html/folder/embedded/Qualcomm/Scorpion/
	echo 'Single or dual-core configuration; 2.1 DMIPS/MHz' > /var/www/html/folder/embedded/Qualcomm/Scorpion/info.txt
	mkdir -p /var/www/html/folder/embedded/Qualcomm/Krait/
	echo 'Dual or quad-core configurations; 3.3 DMIPS/Mhz' > /var/www/html/folder/embedded/Qualcomm/Krait/info.txt
	mkdir -p /var/www/html/folder/embedded/TI/OMAP3/
	echo 'i1.2 GHz ARM Cortex-A8' > /var/www/html/folder/embedded/TI/OMAP3/info.txt
	mkdir -p /var/www/html/folder/embedded/TI/OMAP4/
	echo '1.3-1.5 GHz dual-core ARM Cortex-A9' > /var/www/html/folder/embedded/TI/OMAP4/info.txt

	# FTP download content
	mkdir -p /srv/ftp/download
	dd if=/dev/urandom of=/srv/ftp/download/file-10M.dat bs=1M count=10 > /dev/null 2>&1
	dd if=/dev/urandom of=/home/ana/ana-ftp-file-5M.dat bs=1M count=5 > /dev/null 2>&1
	chown ana:ana /home/ana/ana-ftp-file-5M.dat
	ENDBASHSCRIPT

	# content for URL with special chars
	cat >/var/www/html/login.php <<-END
	<html>
	<body>
	Welcome <?php echo \$_GET["name"]; ?><br>
	Your email address is: <?php echo \$_GET["email"]; ?>
	</body>
	</html>
	END

	# content for FTP upload
	dd if=/dev/urandom of=/home/bogdan/bogdan-ftp-data-3M.dat bs=1M count=3 > /dev/null 2>&1
	chown bogdan:bogdan /home/bogdan/bogdan-ftp-data-3M.dat
}


# Resets to the initial lab configuration state
function lab_setup_reset() {
	rl_stop_topology
	rl_docker_setup_nobridge
	rl_cfg_cleanall
	rl_start_topology "$LAB_SRC/topology.py"

	rl_cfg_flush_ip
	rl_cfg_set_ipv4
	rl_cfg_set_ifstate up
	rl_cfg_set_hosts
	rl_cfg_internet_connectivity
	rl_ssh_provision_keys --users student,host
}

if [[ -z "$EX" || "$EX" == "ex1" ]]; then
	lab_setup_reset
	lab_create_users
	lab_configure_apache
	lab_create_artifacts

else
	echo "ERROR: invalid lab argument: '$EX'" >&2
	exit 1
fi

