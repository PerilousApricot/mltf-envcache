#!/bin/bash

mkdir -p build-raw build-docker

# Usage: ./build-venv.sh <pyenv version>

# Step 1: Clone pyenv if it doesn't exist
if [ ! -d pyenv ]; then
  git clone https://github.com/pyenv/pyenv.git
fi

# Paths for source and repo directories
HOST_SOURCE=$(pwd)
CLIENT_SOURCE=/mltf-build

HOST_REPO=$(pwd)/repo
CLIENT_REPO=/mltf-root
CLIENT_REPO_RO=/mltf-root-ro

CONTAINER_IMAGE=buildimage
PLATFORM=amd64

# Step 2: Build the Docker image
./payload/build-container.sh

# Step 3: Install Python using pyenv inside Docker container
docker run --rm -it \
  --platform ${PLATFORM} \
  -v ${HOST_SOURCE}:${CLIENT_SOURCE}:rw \
  -v ${HOST_SOURCE}/pyenv:${CLIENT_SOURCE}/payload/pyenv:rw \
  -v ${HOST_REPO}:${CLIENT_REPO}:rw \
  -e PYENV_ROOT=${CLIENT_REPO}/pyenv ${CONTAINER_IMAGE} \
  bash --noprofile --norc ${CLIENT_SOURCE}/payload/internal-build-python.sh "$@"

# Step 4: Create a temporary directory for virtual environment building
SCRATCH=$(mktemp -d)
trap "rm -rf $SCRATCH" EXIT

# Step 5: Hash the requirements.txt file (if exists)
if [ -f requirements.txt ]; then
  REQ_HASH=$(sha256sum requirements.txt | awk '{ print $1 }')
  echo "Requirements hash: $REQ_HASH"
else
  echo "Error: requirements.txt not found!"
  exit 1
fi

# Step 6: Build the virtual environment inside Docker
docker run --rm -it \
  --platform ${PLATFORM} \
  -v ${HOST_SOURCE}:${CLIENT_SOURCE}:rw \
  -v ${HOST_SOURCE}/pyenv:${CLIENT_SOURCE}/payload/pyenv:rw \
  -v ${SCRATCH}:${CLIENT_REPO}:rw \
  -v ${HOST_REPO}:${CLIENT_REPO_RO}:ro \
  -e PYENV_ROOT=${CLIENT_REPO}/pyenv ${CONTAINER_IMAGE} \
  bash --noprofile --norc ${CLIENT_SOURCE}/payload/internal-build-venv.sh "$@"

# Step 7: Inside the Docker container, install the packages based on requirements.txt
docker run --rm -it \
  --platform ${PLATFORM} \
  -v ${HOST_SOURCE}:${CLIENT_SOURCE}:rw \
  -v ${HOST_SOURCE}/pyenv:${CLIENT_SOURCE}/payload/pyenv:rw \
  -v ${SCRATCH}:${CLIENT_REPO}:rw \
  -v ${HOST_REPO}:${CLIENT_REPO_RO}:ro \
  -e PYENV_ROOT=${CLIENT_REPO}/pyenv ${CONTAINER_IMAGE} \
  bash -c "
    source ${CLIENT_REPO}/bin/activate &&
    pip install --upgrade pip &&
    pip install --dry-run -r ${CLIENT_SOURCE}/requirements.txt --report ${CLIENT_REPO}/install_report.json &&
    pip install -r ${CLIENT_SOURCE}/requirements.txt
  "

# Step 8: Copy the virtual environment back to the host
cp -a $SCRATCH/* $HOST_REPO

echo "Virtual environment built and requirements installed. Check $HOST_REPO for the environment and install report."