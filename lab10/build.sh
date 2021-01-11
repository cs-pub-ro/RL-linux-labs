#!/bin/bash
# Docker image build script

set -e

echo "Building the lab10 docker image..."
docker build --network=host -f Dockerfile -t "rlrules/lab10" .

echo "Done"

