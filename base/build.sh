#!/bin/bash
# Docker image build script

set -e

echo "Building the base docker image..."
docker build --network=host -f Dockerfile -t "rlrules/base" .

echo "Done"

