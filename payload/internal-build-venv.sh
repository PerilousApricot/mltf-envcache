#!/bin/bash

#
# Builds a virtual environment. Intended to be run from a totally clean shell
#

TOP=$(dirname $0)

$TOP/pyenv/bin/pyenv install -s 3.12.4