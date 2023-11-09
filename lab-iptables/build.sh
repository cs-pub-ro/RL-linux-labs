#!/bin/bash
# Docker image build script

set -e

echo "Building the lab-iptables docker image..."
docker build -q --network=host -f Dockerfile -t "rlrules/lab-iptables" .

echo "Done"

