apk add --update \
  bison \
  build-base \
  clang-dev \
  clang-static \
  cmake \
  elfutils-dev \
  flex-dev \
  git \
  linux-headers \
  llvm5-dev \
  llvm5-static \
  zlib-dev

# Put LLVM directories where CMake expects them to be
ln -s /usr/lib/cmake/llvm5 /usr/lib/cmake/llvm
ln -s /usr/include/llvm5/llvm /usr/include/llvm
ln -s /usr/include/llvm5/llvm-c /usr/include/llvm-c

mkdir -p /app/build && cd /app/build

cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=/usr/local/bpftrace -DSTATIC_LINKING:BOOL=ON ..
make -j$(nproc)
make install
