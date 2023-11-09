#!/bin/bash
# Docker image build script

set -e

echo "Building the lab-mitm docker image..."
docker build -q --network=host -f Dockerfile -t "rlrules/lab-mitm" .

echo "Done"

