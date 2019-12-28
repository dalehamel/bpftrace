if(EMBED_CLANG)
  include(ExternalProject)
  include(ProcessorCount)


  # Note that 
  # https://salsa.debian.org/pkg-llvm-team/llvm-toolchain/blob/snapshot/debian/patches/kfreebsd/include_llvm_ADT_Triple.h.diff

  set(CHOST "x86_64-generic-linux") # FIXME expose these properly as flags, document
  set(CBUILD "x86_64-generic-linux")
  set(LLVM_TARGET_ARCH "x86_64")
  set(LLVM_VERSION "8.0.1")


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

  # If building against an embedded LLVM, use its cmake confi
  if(EMBED_LLVM)
    list(INSERT CLANG_CONFIGURE_FLAGS 0 "-DCMAKE_PREFIX_PATH=${EMBEDDED_LLVM_INSTALL_DIR}/lib/cmake/llvm ")
  endif()

  # FIXME if EMBED_LLVM isn't set to true

  # FIXME move to another cmake file?
  # Must verify versions match, try and use system lib
  if(NOT EMBED_LLVM)
    message("Building embedded clang against host LLVM, checking compatibiilty...")
    include(os-detect)
    detect_os()
    message("HOST ID ${HOST_OS_ID}")
    # FIXME SHasums
    if(HOST_OS_ID STREQUAL "debian" OR HOST_OS_ID STREQUAL "ubuntu" OR HOST_OS_ID_LIKE STREQUAL "debian")
      message("Building on a debian-like system, will apply minimal debian patches to clang sources in order to build.")

      if(NOT EXISTS "./debian-patches.tar.gz")
        set(DEBIAN_PATCH_URL_BASE "https://salsa.debian.org/pkg-llvm-team/llvm-toolchain/-/archive/debian/")
        set(DEBIAN_PATCH_URL_PATH "8_8.0.1-1/llvm-toolchain-debian-8_8.0.1-1.tar.gz?path=debian%2Fpatches")
        SET(DEBIAN_PATCH_URL "${DEBIAN_PATCH_URL_BASE}/${DEBIAN_PATCH_URL_PATH}")
        message("Downloading ${DEBIAN_PATCH_URL}")
        file(DOWNLOAD "${DEBIAN_PATCH_URL}" "./debian-patches.tar.gz" )
        execute_process(COMMAND tar -xpf debian-patches.tar.gz --strip-components=1)
        message("Writing patch series...")
        file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/debian/patches/series" "kfreebsd/clang_lib_Basic_Targets.diff -p2\n")
      endif()

     # set(CLANG_PATCH_COMMAND "clang_patch(){ patch --forward -d <SOURCE_DIR> -p2 < <INSTALL_DIR>/../debian/patches/kfreebsd/clang_lib_Basic_Targets.diff\\; }\\;"
     #                         "clang_patch")
                              #"patch --forward -d <SOURCE_DIR> -p2 < <INSTALL_DIR>/../debian/patches/kfreebsd/clang_lib_Basic_Targets.diff")
    endif()
  endif()

  ProcessorCount(nproc)
  message("CMD: ${CLANG_PATCH_COMMAND}")
  message("TARGETS: ${CLANG_MAKE_TARGETS}")
  # FIXME check SHAs
  ExternalProject_Add(embedded_clang
    URL https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/cfe-${LLVM_VERSION}.src.tar.xz
    CONFIGURE_COMMAND PATH=$ENV{PATH} cmake  ${CLANG_CONFIGURE_FLAGS} # FIXME just specify as cmake opts?
    #PATCH_COMMAND /bin/bash -c "\"${CLANG_PATCH_COMMAND}\""
    PATCH_COMMAND QUILT_PATCHES=<INSTALL_DIR>/../debian/patches/ quilt push -a
    BUILD_COMMAND make -j${nproc}
#"${CLANG_MAKE_TARGETS}" -j${nproc}
    INSTALL_COMMAND make install -j${nproc}
    COMMAND cp <BINARY_DIR>/lib/libclang.a <INSTALL_DIR>/lib/libclang.a
    BUILD_BYPRODUCTS ${CLANG_TARGET_LIBS}
    UPDATE_DISCONNECTED 1
    DOWNLOAD_NO_PROGRESS 1
  )

  # If building against embedded LLVM, make it a dependencie
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
