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

function main(){
	#todo investigate err: failed to resize tty, using default size
	declare -a checker_modules=("checker_ex1" "checker_ex4" "checker_ex5"\
		"checker_ex6")
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

