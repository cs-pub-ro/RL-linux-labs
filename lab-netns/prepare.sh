#!/bin/bash
# Lab 10 prepare script

if [[ "$_RL_INTERNAL" != "rlrullz" ]]; then
    echo "ERROR: This script is not runnable!" >&2
    exit
fi

function lab_create_artifacts(){
    # clean copy of code skeleton
    rm -rf /home/student/sock-diag
    cp -r ${LAB_SRC}/files/sock-diag/ /home/student
    chown -R student:student /home/student/sock-diag
}

lab_create_artifacts

