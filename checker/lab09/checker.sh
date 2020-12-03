#!/bin/bash


function checker_ex1(){
	
	docker exec -t --user=root mn.red /bin/bash -c "ping -c 2 -W 2 8.8.8.8 2>&1 > /dev/null"
	return $?
}

# ex 2 manual
# ex 3 manual
function checker_ex4(){

	
	sudo iptables -L -nv -t nat | grep -i MASQUERADE | tr -s ' ' | cut -d ' ' -f 7 | grep -i '*' 2>&1 > /dev/null
	in_nat=$?
	sudo iptables -L -nv -t nat | grep -i MASQUERADE | tr -s ' ' | cut -d ' ' -f 8 | grep -i 'eth0' 2>&1 > /dev/null
	out_nat=$?

	[ $in_nat == 0 ] && [ $out_nat == 0 ]
	return $?
}

function checker_ex5(){
	
	# docker output has DOS hidden chars
	remote_hostname=`docker exec -t --user=student mn.green /bin/bash \
		-c "ssh -p 10022 -o StrictHostKeyChecking=no host -C 'hostname' 2> /dev/null"| tr -dc '[:print:]'`
	if [ "$remote_hostname" == "red" ]; then return 0; fi
	return 1
	
}
function checker_ex6(){
	
	# docker output has DOS hidden chars
	remote_hostname=`docker exec -t --user=student mn.red /bin/bash \
		-c "ssh -p 20022 -o StrictHostKeyChecking=no host -C 'hostname' 2> /dev/null"| tr -dc '[:print:]'`
	if [ ! "$remote_hostname" == "green" ]; then return 1; fi

	remote_hostname=`docker exec -t --user=student mn.red /bin/bash \
		-c "ssh -p 30022 -o StrictHostKeyChecking=no host -C 'hostname' 2> /dev/null"| tr -dc '[:print:]'`
	if [ ! "$remote_hostname" == "blue" ]; then return 1; fi

	# in order to work, we have to avoid adding -i eth0 as it is currently described in teacher's log
	return 0
}

# ex 7 manual
function helper_get_telnet_remote_host(){

	if [ ! "$#" -ge "2" ]; then
    		echo "Illegal number of parameters"
		return -1
     	fi

     	if  [ ! "$1" == "red" ] && [ ! "$1" == "green" ] && [ ! "$1" == "blue" ] && [ ! "$1" == "host" ]; then
		return -2
	fi

     	if  [ ! "$2" == "red" ] && [ ! "$2" == "green" ] && [ ! "$2" == "blue" ] && [ ! "$2" == "host" ]; then
		return -2
	fi

	
	#TODO check if $2 exists and it is a number
	if [ -z $3 ]; then rmt_port=23; else rmt_port=$3; fi

	remote_host=''
	if [ "$1" != "host" ]; then
	  remote_host=`docker exec -t --user=student mn.$1 /bin/bash \
		-c "{
	             sleep 2
		     echo 'student' 
		     sleep 1
		     echo 'student' 
		     sleep 1
		     echo '/bin/hostname'
		     sleep 1
		     echo 'exit'
		     } | timeout 10 telnet $2 $rmt_port 2> /dev/null | grep -i "/bin/hostname" -A 1 \
			     | tail -n 1 | tr -dc '[:print:]'"`
	
        else
		   remote_host=`{
                     sleep 2
                     echo "student"
                     sleep 1
                     echo "student"
                     sleep 1
                     echo "/bin/hostname"
                     sleep 1
                     echo "exit"
                     } | timeout 10 telnet $2 $rmt_port 2> /dev/null | grep -i "/bin/hostname" -A 1 \
                             | tail -n 1` 

	fi
	echo $remote_host
}

function checker_ex8(){
	# dummy approach

	# red to green via host
	#helper_get_telnet_remote_host red host 20023
	# red to blue via host
	#helper_get_telnet_remote_host red host 30023
	# green to red via host
	rmt_host=$(helper_get_telnet_remote_host green host 10023)
	if [ ! -z $rmt_host ] && [ $rmt_host == "red" ]; then return 0; fi
	return 1;


}

function checker_ex9(){

	grep -v '^#' /etc/sysctl.conf | grep -qi "ip_forward" 
	if [ $? -ne 0 ]; then return 1; fi

	[ ! -f /etc/iptables-rules ] && return 2

	grep -i "iface eth0" -A 1 /etc/network/interfaces | grep -qi "iptables-restore"
	if [ $? -ne 0 ]; then return 3; fi

	return 0

}

# ex10 manual

function main(){
	#todo investigate err: failed to resize tty, using default size
	declare -a checker_modules=("checker_ex1" "checker_ex4" "checker_ex5"\
		"checker_ex6" "checker_ex8" "checker_ex9")
	for val in ${checker_modules[@]}; do
		echo  -n "$val ####################################################### ";
		if $val; then
        		echo True;
		else
        		echo False;
		fi
	done

}
main

