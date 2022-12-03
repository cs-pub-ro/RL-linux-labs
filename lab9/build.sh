#!/bin/bash
# Docker image build script

set -e

echo "Building the lab9 docker image..."
docker build -q --network=host -f Dockerfile -t "rlrules/lab9" .

echo "Done"

