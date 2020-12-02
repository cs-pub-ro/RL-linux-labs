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

     if [ "$#" -ne 1 ]; then
    	echo "Illegal number of parameters"
	return 1
     fi

     if  ! helper_valid_host $1 ; then 
	 echo "$1 not found"
	 return 2
     fi

     if [ $1 == "host" ]; then
	/bin/bash -c "cat /home/student/.ssh/authorized_keys 2> /dev/null | cut -d ' ' -f 2 | sort -u"
     else
     	docker exec -t --user=student mn.$1 /bin/bash -c "cat /home/student/.ssh/authorized_keys 2> /dev/null | cut -d ' ' -f 2 | sort -u"
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
        corina_id_rsa_pub=$(docker exec -t --user=corina mn.blue /bin/bash -c "cat ~/.ssh/id_rsa.pub 2> /dev/null | cut -d ' ' -f 2 | tr -dc '[:print:]'")
        helper_list_authorized_keys host | grep -q "$corina_id_rsa_pub"
        return $?
}



function main(){
	declare -a checker_modules=("checker_ex1" "checker_ex2")
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

