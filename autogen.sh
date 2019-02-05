#!/bin/sh
cat >Makefile.inc <<EOF
USE_TEMP_GOPATH = 1
export GOPATH = /usr/share/gocode
EOF
