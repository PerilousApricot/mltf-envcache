#!/bin/bash

#
# Usage: ./build-container.sh <input container> <output container>
#
# Takes a given container and adds things like development libraries, etc
#

PLATFORM=amd64

# Use Docker to build the image
docker build --platform $PLATFORM -t buildimage ./payload/docks