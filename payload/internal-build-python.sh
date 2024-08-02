#!/bin/bash

#
# Installs a python version using pyenv. Does NOT mount any user code
#

TOP=$(dirname $0)

# TODO: make this configuratble
VERSION=3.12.4

($TOP/pyenv/bin/pyenv local $VERSION &>/dev/null)

# if that version isn't installed
if [ $? -ne 0 ]; then 
  $TOP/pyenv/bin/pyenv install -s 3.12.4
fi
