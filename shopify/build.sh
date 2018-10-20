#!/bin/bash -e

set -x

mkdir -p /usr/local/bpftrace
mkdir -p /app/build
cd /app/build


if [ "$1" == "static" ];then
 export STATIC_LINKING=ON
fi

cmake -DCMAKE_BUILD_TYPE=DEBUG -DCMAKE_INSTALL_PREFIX=/usr/local/bpftrace ..
make -j9
make install

find /usr/local/

tar -cpvzf /artifacts/bpftrace.tar /usr/local/bpftrace
