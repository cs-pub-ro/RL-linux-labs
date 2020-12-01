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
	/bin/bash -c "cat /home/student/.ssh/known_hosts | cut -d ' ' -f 2- | sort -u"
     else
     	docker exec -t --user=student mn.$1 /bin/bash -c "cat /home/student/.ssh/known_hosts | cut -d ' ' -f 2- | sort -u"
     fi
 
     return 0
}

function checker_ex1(){

        ref_fingerprint=$(helper_scan_for_host "red" "host")
        helper_list_known_hosts red | grep -q "$ref_fingerprint"
        return $?
}


echo  -n "EX01 ####################################################### ";
if checker_ex1; then
        echo True;
else
        echo False;
fi

