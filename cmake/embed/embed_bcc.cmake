if(NOT EMBED_BCC)
  return()
endif()

set(BCC_VERSION "v0.12.0")
set(BCC_DOWNLOAD_URL "https://github.com/iovisor/bcc/releases/download/${BCC_VERSION}/bcc-src-with-submodule.tar.gz")
set(BCC_CHECKSUM "SHA256=a7acf0e7a9d3ca03a91f22590e695655a5f0ccf8e3dc29e454c2e4c5d476d8aa")

set(BCC_CONFIGURE_FLAGS  -Wno-dev
                         -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
                         -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
                         )

get_target_triple(TARGET_TRIPLE)

# Can find clang if it specifies CMAKE_FIND_ROOT_PATH, but don't know how to pass as a list...
if(${TARGET_TRIPLE} MATCHES android)
  ProcessorCount(nproc)
  list(APPEND BCC_CONFIGURE_FLAGS -DCMAKE_FIND_ROOT_PATH=${EMBEDDED_LIBELF_INSTALL_DIR})
  list(APPEND BCC_CONFIGURE_FLAGS -DLLVM_DIR=${EMBEDDED_LLVM_INSTALL_DIR}/lib/cmake/llvm)
  list(APPEND BCC_CONFIGURE_FLAGS -DCMAKE_TOOLCHAIN_FILE=/opt/android-ndk/build/cmake/android.toolchain.cmake)
  list(APPEND BCC_CONFIGURE_FLAGS -DANDROID_ABI=${ANDROID_ABI})
  list(APPEND BCC_CONFIGURE_FLAGS -DANDROID_NATIVE_API_LEVEL=${ANDROID_NATIVE_API_LEVEL})
  list(APPEND BCC_CONFIGURE_FLAGS -DPYTHON_CMD=python3.6)

  # FIXME SUPER HACKY way of patching CMakelist to find embedded Clang
  # Also need to patch types.h for bionic, as poll_t is otherwise undefined
  # Also need to defined __user and __force, like in https://github.com/aosp-mirror/platform_bionic/blob/92c6f7ee9014f434fbcce89ab894c745e36732d2/libc/kernel/android/uapi/linux/compiler.h
  # This is all super hacky, should turn into an actual patch series set later
  set(BCC_PATCH_COMMAND PATCH_COMMAND /bin/bash -xc " \
            sed -i '48iset(CMAKE_FIND_ROOT_PATH ${EMBEDDED_CLANG_INSTALL_DIR})' <SOURCE_DIR>/CMakeLists.txt && \
            sed -i '49iinclude_directories(${EMBEDDED_CLANG_INSTALL_DIR}/include)' <SOURCE_DIR>/CMakeLists.txt && \
            sed -i '50iinclude_directories(${CMAKE_CURRENT_BINARY_DIR}/embedded_bcc-prefix/build_include/)' <SOURCE_DIR>/CMakeLists.txt && \
            sed -i 's/-Wall/-Wall -D__user= -D__force=/g' <SOURCE_DIR>/CMakeLists.txt ")
            # FIXME this doesn't work because of cmake + semicolon, need to find a way to escape it?
            # sed -i '26i typedef unsigned __bitwise __poll_t;' <SOURCE_DIR>/src/cc/libbpf/include/linux/types.h ")

  set(BCC_BUILD_COMMAND BUILD_COMMAND /bin/bash -c "make -j${nproc} bcc-static bcc-loader-static bpf-static")

  # Based on reading the cmake file to get the headers to install, would be nice if
  # it had a header-install target :)
  set(BCC_INSTALL_COMMAND INSTALL_COMMAND /bin/bash -c " \
           mkdir -p <INSTALL_DIR>/lib <INSTALL_DIR>/include/bcc && \
           mkdir -p <INSTALL_DIR>/include/bcc/compat/linux  && \
           cp <BINARY_DIR>/src/cc/libbcc.a <INSTALL_DIR>/lib && \
           cp <BINARY_DIR>/src/cc/libbcc_bpf.a <INSTALL_DIR>/lib/libbpf.a && \
           cp <BINARY_DIR>/src/cc/libbcc-loader-static.a <INSTALL_DIR>/lib && \
           cp <SOURCE_DIR>/src/cc/libbpf.h <INSTALL_DIR>/include/bcc && \
           cp <SOURCE_DIR>/src/cc/perf_reader.h <INSTALL_DIR>/include/bcc && \
           cp <SOURCE_DIR>/src/cc/file_desc.h <INSTALL_DIR>/include/bcc && \
           cp <SOURCE_DIR>/src/cc/table_desc.h <INSTALL_DIR>/include/bcc && \
           cp <SOURCE_DIR>/src/cc/table_storage.h <INSTALL_DIR>/include/bcc && \
           cp <SOURCE_DIR>/src/cc/bcc_common.h <INSTALL_DIR>/include/bcc && \
           cp <SOURCE_DIR>/src/cc/bpf_module.h <INSTALL_DIR>/include/bcc && \
           cp <SOURCE_DIR>/src/cc/bcc_exception.h <INSTALL_DIR>/include/bcc && \
           cp <SOURCE_DIR>/src/cc/bcc_syms.h <INSTALL_DIR>/include/bcc && \
           cp <SOURCE_DIR>/src/cc/bcc_proc.h <INSTALL_DIR>/include/bcc && \
           cp <SOURCE_DIR>/src/cc/bcc_elf.h <INSTALL_DIR>/include/bcc && \
           cp <SOURCE_DIR>/src/cc/bcc_usdt.h <INSTALL_DIR>/include/bcc && \
           cp <SOURCE_DIR>/src/cc/libbpf/include/uapi/linux/*.h <INSTALL_DIR>/include/bcc/compat/linux")

  if(EMBED_FLEX)
  # FIXME append flex binary path
  # It will need to set a variable for this based on the project dir
  # -DFLEX_EXECUTABLE=$(abspath $(HOST_OUT_DIR)/bin/flex) \
  endif()

endif()

# FIXME need to determine this dynamically
set(BITS_H_HACK "\n\
#pragma once
#ifndef __WORDSIZE
#define __WORDSIZE 32
#endif
#endif")
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/embedded_bcc-prefix/build_include/bits/reg.h "${LIBINTL_H_HACK}")
file(COPY /usr/include/FlexLexer.h DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/embedded_bcc-prefix/build_include)

message("BCC CONFIG ${BCC_CONFIGURE_FLAGS}")
ExternalProject_Add(embedded_bcc
  URL "${BCC_DOWNLOAD_URL}"
  URL_HASH "${BCC_CHECKSUM}"
  CMAKE_ARGS "${BCC_CONFIGURE_FLAGS}"
  ${BCC_PATCH_COMMAND}
  ${BCC_CONFIGURE_COMMAND}
  ${BCC_BUILD_COMMAND}
  ${BCC_INSTALL_COMMAND}
  UPDATE_DISCONNECTED 1
  DOWNLOAD_NO_PROGRESS 1
)

ExternalProject_Get_Property(embedded_bcc INSTALL_DIR)
set(EMBEDDED_BCC_INSTALL_DIR ${INSTALL_DIR})

if(EMBED_LIBELF)
  ExternalProject_Add_StepDependencies(embedded_bcc install embedded_libelf)
endif()
