#!/bin/bash

if [ ! -z "$RL_PS1_FORMAT" ]; then
    echo "export PS1=\"${RL_PS1_FORMAT}\"" >> /root/.bashrc
    echo "export PS1=\"${RL_PS1_FORMAT}\"" >> /home/student/.bashrc
fi

rm -f "${BASH_SOURCE[0]}"

