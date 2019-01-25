#!/bin/bash -e

set -x

apt-get update && apt-get install -y wget gnupg

wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
cat <<EOF | tee -a /etc/apt/sources.list
# from https://apt.llvm.org/:
deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial main
deb-src http://apt.llvm.org/xenial/ llvm-toolchain-xenial main
# 5.0
deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-5.0 main
deb-src http://apt.llvm.org/xenial/ llvm-toolchain-xenial-5.0 main
# 6.0
deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-6.0 main
deb-src http://apt.llvm.org/xenial/ llvm-toolchain-xenial-6.0 main
EOF

apt-get update
apt-get install -y bison cmake flex g++ git libelf-dev zlib1g-dev libfl-dev
apt-get install -y clang-5.0 libclang-5.0-dev libclang-common-5.0-dev libclang1-5.0 libllvm5.0 llvm-5.0 llvm-5.0-dev llvm-5.0-runtime
apt-get install -y libbpfcc-dev

apt-get --reinstall install -y libc6 libc6-dev
