# This file is for platform-specific configurations for embedded libraries.
# In general, these functions should set any necessary overrides for external
# projects need in order to build successfully for a target platform

function(libelf_platform_config patch_cmd configure_cmd build_cmd install_cmd)
  ProcessorCount(nproc)

  set(libelf_config_cmd CONFIGURE_COMMAND /bin/bash -xc
      "cd <BINARY_DIR> && \
       <SOURCE_DIR>/configure --prefix <INSTALL_DIR>/usr"
     )
  set(libelf_build_cmd BUILD_COMMAND /bin/bash -c
      "cd <BINARY_DIR>/lib && make -j${nproc} && \
       cd <BINARY_DIR>/libelf && make -j${nproc}"
     )
  set(libelf_install_cmd INSTALL_COMMAND /bin/bash -c "cd libelf && make install")

  get_target_triple(TARGET_TRIPLE)
  if(${TARGET_TRIPLE} MATCHES android)
    # Credit to @michalgr for this header
    set(LIBINTL_H_HACK "\n\
#ifndef LIBINTL_H \n\
#define LIBINTL_H \n\
 \
// libintl.h is included in a lot of sources in efutils, but provided \n\
// functionalities are not really necessary. Because of that we follow \n\
// the AOSP example and provide a fake header turning some functions into \n\
// nops with macros \n\
 \n\
#define gettext(x)      (x) \n\
#define dgettext(x,y)   (y) \n\
 \n\
#endif")
    file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/embedded_libelf-prefix/build_include/libintl.h "${LIBINTL_H_HACK}")

    get_toolchain_exports(CROSS_EXPORTS)
    set(ELFUTILS_CROSS_EXPORTS
        "${CROSS_EXPORTS} && \
        export LDFLAGS=-L${EMBEDDED_GNULIB_INSTALL_DIR}/lib && \
        export CFLAGS=-I${EMBEDDED_GNULIB_INSTALL_DIR}/include && \
        export CFLAGS=\"$CFLAGS -I<INSTALL_DIR>/build_include\" && \
        export CFLAGS=\"$CFLAGS -Dprogram_invocation_short_name=\\\\\\\"no-program_invocation_short_name\\\\\\\"\""
                                                                                # smh this much escaping
       )

    get_android_cross_tuple(ANDROID_CROSS_TRIPLE)
    set(libelf_config_cmd CONFIGURE_COMMAND /bin/bash -xc
       "${ELFUTILS_CROSS_EXPORTS} && \
        cd <BINARY_DIR> && \
        <SOURCE_DIR>/configure --host ${ANDROID_CROSS_TRIPLE} --prefix <INSTALL_DIR>/usr"
       )

    prepare_libelf_patches(LIBELF_ANDROID_PATCH_COMMAND)
    set(libelf_patch_cmd PATCH_COMMAND /bin/bash -c "${LIBELF_ANDROID_PATCH_COMMAND}")
  endif()

  set(${patch_cmd} "${libelf_patch_cmd}" PARENT_SCOPE)
  set(${configure_cmd} "${libelf_config_cmd}" PARENT_SCOPE)
  set(${build_cmd} "${libelf_build_cmd}" PARENT_SCOPE)
  set(${install_cmd} "${libelf_install_cmd}" PARENT_SCOPE)

endfunction(libelf_platform_config patch_cmd configure_cmd build_cmd install_cmd)

function(gnulib_platform_config patch_cmd configure_cmd build_cmd install_cmd)
  ProcessorCount(nproc)

  set(gnulib_config_cmd CONFIGURE_COMMAND /bin/bash -xc
      "<SOURCE_DIR>/gnulib-tool --create-testdir --lib='libargp' \
                                --dir=<SOURCE_DIR>/argp_sources argp && \
       <SOURCE_DIR>/argp_sources/configure --prefix <INSTALL_DIR>"
      ) # extra flags to configure needed


  # Doesn't support ninja so hardcode make
  set(gnulib_build_cmd BUILD_COMMAND /bin/bash -c "make -j${nproc}")

  set(gnulib_install_cmd INSTALL_COMMAND /bin/bash -c
      "mkdir -p <INSTALL_DIR>/lib <INSTALL_DIR>/include && \
      cp <BINARY_DIR>/gllib/libargp.a <INSTALL_DIR>/lib && \
      cp <SOURCE_DIR>/argp_sources/gllib/argp.h <INSTALL_DIR>/include"
     )

  get_target_triple(TARGET_TRIPLE)
  if(${TARGET_TRIPLE} MATCHES android)
    # Credit to @michalgr for this stub header
    set(ARGP_HEADER_WRAPPER "\
#ifndef ARGP_WRAPPER_H\n\
#define ARGP_WRAPPER_H\n\
#ifndef ARGP_EI\n\
#  define ARGP_EI inline\n\
#endif\n\
// since ece81a73b64483a68f5157420836d84beb3a1680 argp.h as distributed with\n\
// gnulib requires _GL_INLINE_HEADER_BEGIN macro to be defined.\n\
#ifndef _GL_INLINE_HEADER_BEGIN\n\
#  define _GL_INLINE_HEADER_BEGIN\n\
#  define _GL_INLINE_HEADER_END\n\
#endif\n\
#include \"argp_real.h\"\n\
#endif")

    file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/embedded_gnulib-prefix/include/argp.h "${ARGP_HEADER_WRAPPER}")

    get_toolchain_exports(CROSS_EXPORTS)
    # Patch for argp header here
    set(gnulib_config_cmd CONFIGURE_COMMAND /bin/bash -xc
        "<SOURCE_DIR>/gnulib-tool --create-testdir --lib='libargp' \
                                  --dir=<SOURCE_DIR>/argp_sources argp && \
        ${CROSS_EXPORTS} && \
        <SOURCE_DIR>/argp_sources/configure --host armv7a-linux-androideabi \
                                            --prefix <INSTALL_DIR>" # FIXME hardcoded abi
       ) # extra flags to configure needed

    set(gnulib_install_cmd INSTALL_COMMAND /bin/bash -c
        "mkdir -p <INSTALL_DIR>/lib <INSTALL_DIR>/include && \
        cp <BINARY_DIR>/gllib/libargp.a <INSTALL_DIR>/lib && \
        cp <SOURCE_DIR>/argp_sources/gllib/argp.h <INSTALL_DIR>/include/argp_real.h"
       )

  endif()


  set(${patch_cmd} "${gnulib_patch_cmd}" PARENT_SCOPE)
  set(${configure_cmd} "${gnulib_config_cmd}" PARENT_SCOPE)
  set(${build_cmd} "${gnulib_build_cmd}" PARENT_SCOPE)
  set(${install_cmd} "${gnulib_install_cmd}" PARENT_SCOPE)

endfunction(gnulib_platform_config patch_cmd configure_cmd build_cmd install_cmd)

function(bcc_platform_config patch_cmd configure_flags build_cmd install_cmd)
  ProcessorCount(nproc)

  get_target_triple(TARGET_TRIPLE)
  if(${TARGET_TRIPLE} MATCHES android)
    ProcessorCount(nproc)
    list(APPEND configure_flags -DCMAKE_FIND_ROOT_PATH=${EMBEDDED_LIBELF_INSTALL_DIR}) # FIXME hardcoded assumptions about these being embedded
    list(APPEND configure_flags -DLLVM_DIR=${EMBEDDED_LLVM_INSTALL_DIR}/lib/cmake/llvm)
    list(APPEND configure_flags -DCLANG_DIR=${EMBEDDED_CLANG_INSTALL_DIR})
    list(APPEND configure_flags -DEXTRA_INCLUDE_PATHS=${CMAKE_CURRENT_BINARY_DIR}/embedded_bcc-prefix/build_include/)
    list(APPEND configure_flags -DCMAKE_TOOLCHAIN_FILE=/opt/android-ndk/build/cmake/android.toolchain.cmake)
    list(APPEND configure_flags -DANDROID_ABI=${ANDROID_ABI})
    list(APPEND configure_flags -DANDROID_NATIVE_API_LEVEL=${ANDROID_NATIVE_API_LEVEL})
    list(APPEND configure_flags -DPYTHON_CMD=python3.6)

    prepare_bcc_patches(bcc_android_patch_command)

    if(bcc_android_patch_command)
      set(bcc_patch_cmd PATCH_COMMAND /bin/bash -c "${bcc_android_patch_command}")
    endif()

    # Don't bother building anything but what we are explicitly using
    set(bcc_build_cmd BUILD_COMMAND /bin/bash -c "${CMAKE_MAKE_PROGRAM} -j${nproc} bcc-static bcc-loader-static bpf-static")

    # Based on reading the cmake file to get the headers to install, would be nice if
    # it had a header-install target :)
    set(bcc_install_cmd INSTALL_COMMAND /bin/bash -c " \
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
        cp <SOURCE_DIR>/src/cc/libbpf/include/uapi/linux/*.h <INSTALL_DIR>/include/bcc/compat/linux"
      )

    set(PLATFORM_WORDSIZE 32) # FIXME dynamically detect based on ABI

    # Credit to @michalgr for this stub header
    set(BITS_H_HACK "\n\
#pragma once \n \
#ifndef __WORDSIZE \n \
#define __WORDSIZE ${PLATFORM_WORDSIZE} \n \
#endif\n")
    file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/embedded_bcc-prefix/build_include/bits/reg.h "${LIBINTL_H_HACK}")
    file(COPY /usr/include/FlexLexer.h DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/embedded_bcc-prefix/build_include)
  endif()

  set(${patch_cmd} "${bcc_patch_cmd}" PARENT_SCOPE)
  set(BCC_CONFIGURE_FLAGS "${configure_flags}" PARENT_SCOPE) # FIXME leaky, should the var name be passed separately?
  set(${build_cmd} "${bcc_build_cmd}" PARENT_SCOPE)
  set(${install_cmd} "${bcc_install_cmd}" PARENT_SCOPE)

endfunction(bcc_platform_config patch_cmd configure_cmd build_cmd install_cmd)

function(llvm_platform_config patch_cmd configure_flags build_cmd install_cmd)

  get_target_triple(TARGET_TRIPLE)
  if(${TARGET_TRIPLE} MATCHES android)
    ProcessorCount(nproc)
    list(APPEND configure_flags -DCMAKE_TOOLCHAIN_FILE=/opt/android-ndk/build/cmake/android.toolchain.cmake)
    list(APPEND configure_flags -DANDROID_ABI=${ANDROID_ABI})
    list(APPEND configure_flags -DANDROID_NATIVE_API_LEVEL=${ANDROID_NATIVE_API_LEVEL})

    # LLVMHello doesn't work, but is part of the all target.
    # To get around this, each target is instead built individually, omitting LLVMHello
    # A side effet of this is progress is reported per target
    # FIXME is there a way to trick Make into omitting just LLVMHello? -W maybe?
    string(REPLACE ";" " " LLVM_MAKE_TARGETS "${LLVM_LIBRARY_TARGETS}" )
    set(llvm_build_cmd BUILD_COMMAND /bin/bash -c
                            "${CMAKE_MAKE_PROGRAM} -j${nproc} ${LLVM_MAKE_TARGETS} ")

    set(llvm_install_cmd INSTALL_COMMAND /bin/bash -c
        "mkdir -p <INSTALL_DIR>/lib/ <INSTALL_DIR>/bin/ && \
         find <BINARY_DIR>/lib/ | grep '\\.a$' | \
         xargs -I@ cp @ <INSTALL_DIR>/lib/ && \
         ${CMAKE_MAKE_PROGRAM} install-cmake-exports && \
         ${CMAKE_MAKE_PROGRAM} install-llvm-headers && \
         cp <BINARY_DIR>/NATIVE/bin/llvm-tblgen <INSTALL_DIR>/bin/ "
       )
  endif()

  set(LLVM_CONFIGURE_FLAGS "${configure_flags}" PARENT_SCOPE) # FIXME leaky, should the var name be passed separately?
  set(${build_cmd} "${llvm_build_cmd}" PARENT_SCOPE)
  set(${install_cmd} "${llvm_install_cmd}" PARENT_SCOPE)
endfunction(llvm_platform_config patch_cmd configure_flags build_cmd install_cmd)

function(clang_platform_config patch_cmd configure_flags build_cmd install_cmd)

  get_target_triple(TARGET_TRIPLE)
  if(${TARGET_TRIPLE} MATCHES android)
    ProcessorCount(nproc)

    if(EMBED_LIBCLANG_ONLY)
      message(FATAL_ERROR "Cannot set EMBED_LIBCLANG_ONLY on Android, no system libs to link.")
    endif()

    list(APPEND configure_flags -DCMAKE_TOOLCHAIN_FILE=/opt/android-ndk/build/cmake/android.toolchain.cmake)
    list(APPEND configure_flags -DANDROID_ABI=${ANDROID_ABI})
    list(APPEND configure_flags -DANDROID_NATIVE_API_LEVEL=${ANDROID_NATIVE_API_LEVEL})
    list(APPEND configure_flags -DCMAKE_CROSSCOMPILING=True)

    string(REPLACE ";" " " CLANG_MAKE_TARGETS "${CLANG_LIBRARY_TARGETS}" )
    set(clang_build_cmd BUILD_COMMAND /bin/bash -c
        "${CMAKE_MAKE_PROGRAM} -j${nproc} ${CLANG_MAKE_TARGETS}"
       )
  endif()

  set(CLANG_CONFIGURE_FLAGS "${configure_flags}" PARENT_SCOPE) # FIXME leaky, should the var name be passed separately?
  set(${build_cmd} "${clang_build_cmd}" PARENT_SCOPE)
endfunction(clang_platform_config patch_cmd configure_flags build_cmd install_cmd)
