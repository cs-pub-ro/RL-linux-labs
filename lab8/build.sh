#!/bin/bash
# Docker image build script

set -e

echo "Building the lab8 docker image..."
docker build --network=host -f Dockerfile -t "rlrules/lab8" .

echo "Done"

