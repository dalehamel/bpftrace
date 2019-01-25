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

# Alpine currently does not have a package for bcc. Until they do,
# we'll peg the alpine build to bcc v0.8.0
#
# We're building here so docker can cache the build layer
curl -L https://github.com/iovisor/bcc/archive/v0.8.0.tar.gz --output /bcc.tar.gz
tar xvf /bcc.tar.gz
mv bcc-0.8.0 bcc
cd /bcc && mkdir build && cd build && cmake .. && make install -j4 && \
  cp src/cc/libbcc.a /usr/local/lib64/libbcc.a && \
  cp src/cc/libbcc-loader-static.a /usr/local/lib64/libbcc-loader-static.a && \
  cp src/cc/libbpf.a /usr/local/lib64/libbpf.a

mkdir -p /app/build && cd /app/build

cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=/usr/local/bpftrace -DSTATIC_LINKING:BOOL=ON ..
make -j$(nproc)
make install
