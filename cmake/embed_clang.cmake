if(EMBED_CLANG)
  include(ExternalProject)

  set(CHOST "x86_64-generic-linux") # FIXME expose these properly as flags, document
  set(CBUILD "x86_64-generic-linux")
  set(LLVM_TARGET_ARCH "x86_64")
  set(LLVM_VERSION "8.0.1")

  if(NOT EMBED_LLVM)
    # TODO dalehamel
    # Could save time by linking to host LLVM, but this turns out to be trickier
    # than expected. Requires downloading and applying distro-specific patches,
    # and even still there can be linker errors. For now enforce that embedding
    # clang requires embedding LLVM
    message(FATAL_ERROR "Embedding clang is currently only supported with embedded LLVM")
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

  set(CLANG_CONFIGURE_FLAGS  "-Wno-dev "
                             "-DLLVM_TARGETS_TO_BUILD=BPF "
                             "-DCMAKE_BUILD_TYPE=MinSizeRel "
                             "-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR> "
                             "-DCMAKE_VERBOSE_MAKEFILE=OFF "
                             "-DCLANG_VENDOR=bpftrace "
                             "-DCLANG_BUILD_EXAMPLES=OFF "
                             "-DCLANG_INCLUDE_DOCS=OFF "
                             "-DCLANG_INCLUDE_TESTS=OFF "
                             "-DCLANG_PLUGIN_SUPPORT=ON "
                             "-DLIBCLANG_BUILD_STATIC=ON "
                             "-DLLVM_ENABLE_EH=ON "
                             "-DLLVM_ENABLE_RTTI=ON "
                             "-DCLANG_BUILD_TOOLS=OFF "
                             "<SOURCE_DIR>")

  if(EMBED_LLVM)
    list(INSERT CLANG_CONFIGURE_FLAGS 0 "-DCMAKE_PREFIX_PATH=${EMBEDDED_LLVM_INSTALL_DIR}/lib/cmake/llvm ")
  endif()

  ExternalProject_Add(embedded_clang
    URL https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/cfe-${LLVM_VERSION}.src.tar.xz
    CONFIGURE_COMMAND PATH=$ENV{PATH} cmake  ${CLANG_CONFIGURE_FLAGS} # FIXME just specify as cmake opts?
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
