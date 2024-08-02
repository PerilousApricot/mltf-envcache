#!/bin/bash


#
# Usage: ./build-container.sh <input container> <output container>
# 
# Takes a given container and adds things like development libraries, etc
#

# FIXME accept inputs, confiure Dockerfile dynamically

nerdctl build docks -t buildimage
