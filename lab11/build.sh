#!/bin/bash
# Docker image build script

set -e

echo "Building the lab11 docker image..."
docker build --network=host -f Dockerfile -t "rlrules/lab11" .

echo "Done"

