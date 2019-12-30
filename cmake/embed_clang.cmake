if(EMBED_CLANG)
  include(ExternalProject)

  if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    # https://salsa.debian.org/pkg-llvm-team/llvm-toolchain/blob/8/debian/rules
    set(EMBEDDED_BUILD_TYPE "RelWithDebInfo")
  elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
    set(EMBEDDED_BUILD_TYPE "MinSizeRel")
  else()
    set(EMBEDDED_BUILD_TYPE ${CMAKE_BUILD_TYPE})
  endif()

  if(NOT EMBED_LLVM)
    # see docs/embeded_builds for why
    message(FATAL_ERROR "Embedding clang is currently only supported with embedded LLVM")
  endif()

  if(${LLVM_VERSION} VERSION_EQUAL "8")
    set(LLVM_FULL_VERSION "8.0.1")
    set(CLANG_DOWNLOAD_URL "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_FULL_VERSION}/cfe-${LLVM_FULL_VERSION}.src.tar.xz")
    set(CLANG_URL_CHECKSUM "SHA256=70effd69f7a8ab249f66b0a68aba8b08af52aa2ab710dfb8a0fba102685b1646")
  else()
    message(FATAL_ERROR "No supported LLVM version has been specified with LLVM_VERSION, aborting")
  endif()

  set(CLANG_BUILD_TARGETS clang
                          clangAST
                          clangAnalysis
                          clangBasic
                          clangDriver
                          clangEdit
                          clangFormat
                          clangFrontend
                          clangIndex
                          clangLex
                          clangParse
                          clangRewrite
                          clangSema
                          clangSerialization
                          clangToolingCore
                          clangToolingInclusions
                          )

  set(CLANG_TARGET_LIBS "")
  foreach(clang_target IN LISTS CLANG_BUILD_TARGETS)
    list(APPEND CLANG_TARGET_LIBS "<INSTALL_DIR>/lib/lib${clang_target}.a")
  endforeach(clang_target)

  set(CLANG_CONFIGURE_FLAGS  -Wno-dev
                             -DLLVM_TARGETS_TO_BUILD=BPF
                             -DCMAKE_BUILD_TYPE=${EMBEDDED_BUILD_TYPE}
                             -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
                             -DCMAKE_VERBOSE_MAKEFILE=OFF
                             -DCLANG_VENDOR=bpftrace
                             -DCLANG_BUILD_EXAMPLES=OFF
                             -DCLANG_INCLUDE_DOCS=OFF
                             -DCLANG_INCLUDE_TESTS=OFF
                             -DCLANG_PLUGIN_SUPPORT=ON
                             -DLIBCLANG_BUILD_STATIC=ON
                             -DLLVM_ENABLE_EH=ON
                             -DLLVM_ENABLE_RTTI=ON
                             -DCLANG_BUILD_TOOLS=OFF
                             )

  if(EMBED_LLVM)
    list(APPEND CLANG_CONFIGURE_FLAGS  -DCMAKE_PREFIX_PATH=${EMBEDDED_LLVM_INSTALL_DIR}/lib/cmake/llvm)
  endif()

  ExternalProject_Add(embedded_clang
    URL "${CLANG_DOWNLOAD_URL}"
    URL_HASH "${CLANG_URL_CHECKSUM}"
    CMAKE_ARGS "${CLANG_CONFIGURE_FLAGS}"
    INSTALL_COMMAND make install
    COMMAND cp <BINARY_DIR>/lib/libclang.a <INSTALL_DIR>/lib/libclang.a
    BUILD_BYPRODUCTS ${CLANG_TARGET_LIBS}
    UPDATE_DISCONNECTED 1
    DOWNLOAD_NO_PROGRESS 1
  )

  if (EMBED_LLVM)
    ExternalProject_Add_StepDependencies(embedded_clang install embedded_llvm)
  endif()

  ExternalProject_Get_Property(embedded_clang INSTALL_DIR)
  set(EMBEDDED_CLANG_INSTALL_DIR ${INSTALL_DIR})
  set(CLANG_EMBEDDED_CMAKE_TARGETS "")

  include_directories(SYSTEM ${EMBEDDED_CLANG_INSTALL_DIR}/include)

  foreach(clang_target IN LISTS CLANG_BUILD_TARGETS)
    list(APPEND CLANG_EMBEDDED_CMAKE_TARGETS ${clang_target})
    add_library(${clang_target} STATIC IMPORTED)
    set_property(TARGET ${clang_target} PROPERTY IMPORTED_LOCATION ${EMBEDDED_CLANG_INSTALL_DIR}/lib/lib${clang_target}.a)
    add_dependencies(${clang_target} embedded_clang)
  endforeach(clang_target)
endif()
