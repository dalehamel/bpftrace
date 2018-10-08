#!/bin/bash

mkdir -p /usr/local/bpftrace
mkdir -p /app/build
cd /app/build
cmake -DCMAKE_BUILD_TYPE=DEBUG -DCMAKE_INSTALL_PREFIX=/usr/local/bpftrace ..
make -j9
make install

cp -r /usr/local/bpftrace /artifacts
