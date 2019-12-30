#!/bin/bash

set -e

STATIC_LINKING=${STATIC_LINKING:-OFF}
STATIC_LIBC=${STATIC_LIBC:-OFF}
LLVM_VERSION=${LLVM_VERSION:-8} # default llvm to latest version
EMBED_LLVM=${EMBED_LLVM:-OFF}
EMBED_CLANG=${EMBED_CLANG:-OFF}
DEPS_ONLY=${DEPS_ONLY:-OFF}
RUN_TESTS=${RUN_TESTS:-1}
CI_TIMEOUT=${CI_TIMEOUT:-0}

# If running on Travis, we may need several builds incrementally building up
# the cache in order to cold-start the build cache within the 50 minute travis
# job timeout. The gist is to kill the job safely and safe the cache and run
# again until the build cache is fully warmed
with_timeout()
{
  if [[ $CI_TIMEOUT -gt 0 ]];then
    set +e
    [[ -z $CI_TIME_REMAINING ]] && CI_TIME_REMAINING=$CI_TIMEOUT
    start_time="$(date -u +%s)"
    timeout $CI_TIME_REMAINING $@
    rc=$?
    end_time="$(date -u +%s)"
    elapsed="$(($end_time-$start_time))"
    CI_TIME_REMAINING=$((CI_TIME_REMAINING-elapsed))
    echo "$CI_TIME_REMAINING remains for other jobs"

    if [[ $rc -eq 124 ]];then
      echo "Exiting early on timeout to upload cache and retry..."
      echo "This is expected on a cold cache / new LLVM release."
      echo "Retry the build until it passes, so long as it progresses."
      echo "see docs/embedded_builds.md for more info"
      exit 0
    elif [[ $rc -ne 0 ]];then
      exit $rc # preserve set -e behavior on non-timeout
    fi
    set -e # resume set -e
  else
    $@
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
[[ $EMBED_LLVM  == "ON" ]] && with_timeout make embedded_llvm "$@"
[[ $EMBED_CLANG == "ON" ]] && with_timeout make embedded_clang "$@"
[[ $DEPS_ONLY == "ON" ]] && exit 0
make "$@"

if [ $RUN_TESTS = 1 ]; then
  if [ "$RUN_ALL_TESTS" = "1" ]; then
    ctest -V
  else
    ./tests/bpftrace_test $TEST_ARGS;
  fi
fi
