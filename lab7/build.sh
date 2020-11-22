#!/bin/bash
# Docker image build script

set -e

echo "Building the lab7 docker image..."
docker build --network=host -f Dockerfile -t "rlrules/lab7" .

echo "Done"

