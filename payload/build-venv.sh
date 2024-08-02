#!/bin/bash

mkdir -p build-raw build-nerdctl

# Usage: ./build-venv.sh <pyenv version> <yaml>

if [ ! -d pyenv ]; then
  git clone https://github.com/pyenv/pyenv.git
fi

# TODO configure installation path
# TODO configure build image (e.g. choose C7 or R9)

# TODO Make this configurable
HOST_SOURCE=$(pwd)
CLIENT_SOURCE=/mltf-build

HOST_REPO=$(pwd)/repo
CLIENT_REPO=/mltf-root
CLIENT_REPO_RO=/mltf-root-ro

CONTAINER_IMAGE=buildtest
PLATFORM=amd64

# TODO switch on containerization: e.g. support singularity
if [ 1 -eq 1 ]; then

    # Make sure we have the build image
    # TODO pass this in as argument
    ./build-container.sh

    # First install python... this is installed to the real path (no client
    # code)
    # TODO long-term platform should be configurable (e.g. to run on GH nodes)
    nerdctl container run --rm -it \
      --platform ${PLATFORM} \
      -v ${HOST_SOURCE}:${CLIENT_SOURCE}:ro \
      -v ${HOST_REPO}:${CLIENT_REPO}:rw \
      -e PYENV_ROOT=${CLIENT_REPO}/pyenv ${CONTAINER_IMAGE} bash --noprofile --norc ${CLIENT_SOURCE}/internal-build-python.sh "$@"
    # ... then install the environment itself, we don't give rw access to the
    # repo by default, we copy the files over later.

    # Make a temp dir...
    SCRATCH=$(mktemp -t tmp.XXXXXXXXXX)
    # ... and then delete it when the job exits
    trap "rm -rf \"$SCRATCH\"" EXIT

    nerdctl container run --rm -it \
      --platform ${PLATFORM} \
      -v ${HOST_SOURCE}:${CLIENT_SOURCE}:ro \
      -v ${SCRATCH}:${CLIENT_REPO}:rw \
      -v ${HOST_REPO}:${CLIENT_REPO_RO}:ro \
      -e PYENV_ROOT=${CLIENT_REPO}/pyenv ${CONTAINER_IMAGE} bash --noprofile --norc ${CLIENT_SOURCE}/internal-build-venv.sh "$@"

    # FIXME: Only copy one subdir corresponding to the single thing we had, so
    # users can't sneakily overwrite other installs
    cp -a $SCRATCH/* $HOST_REPO
    rm -rf $SCRATCH
else
    env -i -- HOME=$(pwd)/buildhome bash --noprofile --norc internal-build-venv.sh "$@"
fi
