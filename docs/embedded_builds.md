# Embedding dependencies

To make bpftrace more portable, it has long supported an alpine-based musl
build, which statically compiled bpftrace resulting in no runtime linking
required.

The drawback to this approach is that LLVM libraries, even when statically
compiled, depends on symbols from libdl, and works best and most predictably
when dynamically linked to libc.

To embed everything except for libc, building LLVM and Clang from source is
supported. This allows for linking to arbitrary libc targets dynamically, which
may provide the best of both worlds between a purely static and a purely
dynamically-linked bpftrace executable.

For this reason, there is CMake support in the bpftrace project to build LLVM
and Clang from source, as these are the heaviest dependencies of bpftrace.
Other library dependencies can be obtained by most package managers reliably.

## Embedding Clang


## Embedding LLVM
