#!/bin/bash -e

set -x

apt-get update
apt-get install -y \
    bison \
    cmake \
    flex \
    g++ \
    git \
    libclang-5.0-dev \
    libelf-dev \
    llvm-5.0-dev \
    zlib1g-dev \
    libbpfcc-dev

apt-get --reinstall install -y libc6 libc6-dev
