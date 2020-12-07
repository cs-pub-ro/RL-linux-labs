#!/bin/bash
# Docker image build script

set -e

export DEBIAN_FRONTEND=noninteractive
apt-get install -y vsftpd

echo "Building the lab8 docker image..."
docker build --network=host -f Dockerfile -t "rlrules/lab8" .

echo "Done"

