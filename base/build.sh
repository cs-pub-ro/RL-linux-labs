#!/bin/bash
# Docker image build script

set -e

DOCKER_ARGS=(--network=host)
[[ "$DEBUG" == "1" ]] || DOCKER_ARGS+=(-q)

echo "Building the base docker image..."
docker build "${DOCKER_ARGS[@]}" -f Dockerfile -t "rlrules/base" .

echo "Done"

