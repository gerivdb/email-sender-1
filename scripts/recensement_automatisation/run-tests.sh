#!/bin/sh
# Runner de tests isolés pour recensement_automatisation (v113b)
# Usage : ./run-tests.sh

set -e

IMAGE=recensement_automatisation_test:latest

docker build -t $IMAGE .
docker run --rm $IMAGE
