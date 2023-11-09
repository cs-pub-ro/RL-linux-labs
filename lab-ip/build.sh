#!/bin/bash
# Docker image build script

set -e

echo "Building the lab-ip docker image..."
docker build -q --network=host -f Dockerfile -t "rlrules/lab-ip" .

echo "Done"

