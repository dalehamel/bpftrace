#!/bin/bash

set -e

STATIC_LINKING=${STATIC_LINKING:-OFF}
EMBED_LIBC=${EMBED_LIBC:-OFF}
EMBED_LLVM=${EMBED_LLVM:-OFF}
EMBED_CLANG=${EMBED_CLANG:-OFF}
RUN_TESTS=${RUN_TESTS:-1}

# Build bpftrace
mkdir -p "$1"
cd "$1"
cmake -DCMAKE_BUILD_TYPE="$2" -DSTATIC_LINKING:BOOL=$STATIC_LINKING \
      -DEMBED_LLVM:BOOL=$EMBED_LLVM -DEMBED_CLANG:BOOL=$EMBED_CLANG \
      -DEMBED_LIBC:BOOL=$EMBED_LIBC ../
shift 2

[[ $EMBED_LLVM  = "ON" ]] && make embedded_llvm
[[ $EMBED_CLANG = "ON" ]] && make embedded_clang
make "$@"

if [ $RUN_TESTS = 1 ]; then
  if [ "$RUN_ALL_TESTS" = "1" ]; then
    ctest -V
  else
    ./tests/bpftrace_test $TEST_ARGS;
  fi
fi
