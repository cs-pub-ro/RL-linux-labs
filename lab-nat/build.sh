#!/bin/bash
# Docker image build script

set -e

echo "Building the lab-nat docker image..."
docker build -q --network=host -f Dockerfile -t "rlrules/lab-nat" .

echo "Done"

