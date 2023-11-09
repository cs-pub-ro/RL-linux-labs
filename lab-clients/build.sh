#!/bin/bash
# Docker image build script

set -e

echo "Building the lab-clients docker image..."
docker build -q --network=host -f Dockerfile -t "rlrules/lab-clients" .

echo "Done"

