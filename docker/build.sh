#!/bin/bash

set -e
set -x

STATIC_LINKING=${STATIC_LINKING:-OFF}
STATIC_LIBC=${STATIC_LIBC:-OFF}
EMBED_LLVM=${EMBED_LLVM:-OFF}
EMBED_CLANG=${EMBED_CLANG:-OFF}
LLVM_VERSION=${LLVM_VERSION:-8} # default llvm to latest version
RUN_TESTS=${RUN_TESTS:-1}

# If running on Travis, we may need several builds incrementally building up
# the cache in order to cold-start the build cache within the 50 minute travis
# job timeout. The gist is to kill the job safely
with_timeout()
{

  # FIXME detect and only do this on travis, else just call original
  timeout 2400 $@
  rc=$?

  # TODO dalehamel
  # The drawback of this is that it inappropriately sets the overall build
  # to passing, perhaps another job can check if the cache was cold and fail
  # if a retry occurs, to keep CI verity?
  if [[ $rc == 124 ]];then
    echo "Exiting early on timeout to upload cache and retry..."
    exit 0
  fi
}

# Build bpftrace
mkdir -p "$1"
cd "$1"
cmake -DCMAKE_BUILD_TYPE="$2" -DSTATIC_LINKING:BOOL=$STATIC_LINKING \
      -DEMBED_LLVM:BOOL=$EMBED_LLVM -DEMBED_CLANG:BOOL=$EMBED_CLANG \
      -DLLVM_VERSION=$LLVM_VERSION -DSTATIC_LIBC:BOOL=$STATIC_LIBC ../
shift 2

# It is necessary to build embedded llvm and clang targets first,
# so that their headers can be referenced
[[ $EMBED_LLVM  = "ON" ]] && with_timeout make embedded_llvm "$@"
[[ $EMBED_CLANG = "ON" ]] && with_timeout make embedded_clang "$@"
make "$@"

if [ $RUN_TESTS = 1 ]; then
  if [ "$RUN_ALL_TESTS" = "1" ]; then
    ctest -V
  else
    ./tests/bpftrace_test $TEST_ARGS;
  fi
fi
