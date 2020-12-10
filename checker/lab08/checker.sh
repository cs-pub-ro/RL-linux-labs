#!/bin/bash

function helper_valid_host(){
     if [ "$#" -ne 1 ]; then
    	echo "Illegal number of parameters"
     fi

     case "$1" in "red"|"green"|"blue"|"host")
	   return 0;;
     *)
	   return 1;;
     esac
}

# from $1 to $2 
function helper_scan_for_host(){

     # ERR code:
     # 1 - number of params must be 2
     # 2 - source host not available
     # 3 - dest host not available


     if [ "$#" -ne 2 ]; then
    	echo "Illegal number of parameters"
	return 1
     fi

     if ! helper_valid_host $1 ; then 
	 echo "$1 not found"
	 return 2
     fi

     if ! helper_valid_host $2 ; then 
	 echo "$2 not found"
	 return 3
     fi

     if [ $1 == "host" ]; then
	/bin/bash -c "ssh-keyscan -t ecdsa-sha2-nistp256 -H $2 2> /dev/null | cut -d ' ' -f 2- | sort -u"
     else
     	docker exec -t --user=student mn.$1 /bin/bash -c "ssh-keyscan -t ecdsa-sha2-nistp256 -H $2 2> /dev/null | cut -d ' ' -f 2- | sort -u"
     fi

     return 0
}

function helper_list_known_hosts(){

     # ERR code:
     # 1 - number of params must be 2
     # 2 - source host not available

     if [ "$#" -ne 1 ]; then
    	echo "Illegal number of parameters"
	return 1
     fi

     if  ! helper_valid_host $1 ; then 
	 echo "$1 not found"
	 return 2
     fi

     if [ $1 == "host" ]; then
	/bin/bash -c "cat /home/student/.ssh/known_hosts 2> /dev/null| cut -d ' ' -f 2- | sort -u"
     else
     	docker exec -t --user=student mn.$1 /bin/bash -c "cat /home/student/.ssh/known_hosts 2> /dev/null| cut -d ' ' -f 2- | sort -u"
     fi
 
     return 0
}

function helper_list_authorized_keys(){

     # ERR code:
     # 1 - number of params must be 2
     # 2 - source host not available

     if [ "$#" -ne 2 ]; then
    	echo "Illegal number of parameters"
	return 1
     fi

     if  ! helper_valid_host $1 ; then 
	 echo "$1 not found"
	 return 2
     fi

     #TODO check user

     if [ $1 == "host" ]; then
	/bin/bash -c "cat /home/$2/.ssh/authorized_keys 2> /dev/null | cut -d ' ' -f 2 | sort -u"
     else
     	docker exec -t --user=$2 mn.$1 /bin/bash -c "cat /home/$2/.ssh/authorized_keys 2> /dev/null | cut -d ' ' -f 2 | sort -u"
     fi
 
     return 0
}



function checker_ex1(){

        ref_fingerprint=$(helper_scan_for_host "red" "host")
        helper_list_known_hosts red | grep -q "$ref_fingerprint"
        return $?
}

function checker_ex2(){

	# check if id_rsa and id_rsa pub exists corina blue
     	id_rsa_exists=`docker exec -t --user=corina mn.blue /bin/bash -c "test -f ~/.ssh/id_rsa && test -f ~/.ssh/id_rsa.pub && echo true"`
	if [ -z id_rsa_exists ]; then return 1; fi

	# compare corina@blue id_rsa.pub with authorized_keys from student@host
	# docker adds DOS chars, therefore it requires a dos2unix or sed -e "s/\r//g or tr -dc [':print:]. The latter removes all hidden characters"
        corina_id_rsa_pub=$(docker exec -t --user=corina mn.blue /bin/bash -c "cat ~/.ssh/id_rsa.pub 2> /dev/null | cut -d ' ' -f 2 | tr -dc '[:print:]'")
        helper_list_authorized_keys host student | grep -q "$corina_id_rsa_pub"
        return $?
}

function checker_ex3(){
	
	# docker adds DOS chars, therefore it requires a dos2unix or sed -e "s/\r//g"
	if ! docker exec -t --user=corina mn.blue /bin/bash -c "test -d ~/assignment/"; then return 1; fi
	if ! test -d /home/student/solution; then return 2; fi

	diff \
		<(md5sum /home/student/assignment/* 2> /dev/null|cut -d ' ' -f 1) \
		<(docker exec -t --user=corina mn.blue /bin/bash -c "md5sum ~/assignment/*| cut -d ' ' -f 1"| sed -e "s/\r//g") \
		2>&1> /dev/null
	[ $? -ne 0 ] && return 3

	diff \
		<(md5sum /home/student/solution/* 2> /dev/null|cut -d ' ' -f 1) \
		<(docker exec -t --user=corina mn.blue /bin/bash -c "md5sum ~/solution/*| cut -d ' ' -f 1"| sed -e "s/\r//g") \
		2>&1> /dev/null
	[ $? -ne 0 ] && return 4
	return 0
}

function checker_ex4(){

	# lazy validation
	test \
		-f /home/student/file-100M-nc.dat && test \
		-f /home/student/file-100M-ftp.dat && test \
		-f /home/student/file-100M-scp.dat
	return $?

	#TODO md5 / size 
}

# checker_ex5 - manual

function checker_ex6(){

    # testing only ftp connectivity from blue
    if docker exec -t --user=student mn.blue bash -c "nc -z -w1 green 21"; then
	 return 1
    fi

    return 0
}

function checker_ex7(){

    # testing only ssh connectivity from blue
    if docker exec -t --user=student mn.blue bash -c "nc -z -w1 green 22"; then
	 return 1
    fi

    return 0
}

function checker_ex8(){

    # testing only ssh connectivity from red
    if docker exec -t --user=student mn.red bash -c "nc -z -w1 green 22"; then
	 return 0
    fi

    return 1
}


# checker_ex9 - manual
# checker_ex10 - manual

function checker_ex11(){
    # testing only ssh connectivity from red
    docker exec -t --user=student mn.green bash -c "nc -z -w1 red 22"
    green_to_red=$?
    docker exec -t --user=student mn.red bash -c "nc -z -w1 green 22"
    red_to_green=$?

    if [ $green_to_red -eq 1 ] && [ $red_to_green -eq 0 ]; then return 0; fi

    return 1
}

function checker_ex12(){
	
	# docker adds DOS chars, therefore it requires a dos2unix or sed -e "s/\r//g"
	if ! docker exec -t --user=bogdan mn.blue /bin/bash -c "test -d ~/proiecte/"; then return 1; fi

	diff \
		<(md5sum /home/ana/proiecte/* 2> /dev/null|cut -d ' ' -f 1) \
		<(docker exec -t --user=bogdan mn.blue /bin/bash -c "md5sum ~/proiecte/*| cut -d ' ' -f 1"| sed -e "s/\r//g") \
		2>&1> /dev/null
	[ $? -ne 0 ] && return 2

	# check if id_rsa and id_rsa pub exists bogdan blue
     	id_rsa_exists=`docker exec -t --user=bogdan mn.blue /bin/bash -c "test -f ~/.ssh/id_rsa && test -f ~/.ssh/id_rsa.pub && echo true"`
	if [ -z id_rsa_exists ]; then return 3; fi

	# compare bogdan@blue id_rsa.pub with authorized_keys from ana@host
	# docker adds DOS chars, therefore it requires a dos2unix or sed -e "s/\r//g or tr -dc [':print:]. The latter removes all hidden characters"
        bogdan_id_rsa_pub=$(docker exec -t --user=bogdan mn.blue /bin/bash -c "cat ~/.ssh/id_rsa.pub 2> /dev/null | cut -d ' ' -f 2 | tr -dc '[:print:]'")
        helper_list_authorized_keys host ana | grep -q "$bogdan_id_rsa_pub"
	[ $? -ne 0 ] && return 4 

	return 0
}

function main(){
	#todo investigate err: failed to resize tty, using default size
	declare -a checker_modules=("checker_ex1" "checker_ex2" "checker_ex3" "checker_ex4" \
		"checker_ex6" "checker_ex7" "checker_ex8" "checker_ex11" "checker_ex12")
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

