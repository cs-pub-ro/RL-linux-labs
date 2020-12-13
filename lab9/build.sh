#!/bin/bash
# Docker image build script

set -e

echo "Building the lab9 docker image..."
docker build --network=host -f Dockerfile -t "rlrules/lab9" .

echo "Done"

