if(EMBED_LLVM)
  include(ExternalProject)
  include(embed_helpers)
  include(ProcessorCount)

  # TO DO
  # Set up cross-compilation
  # https://cmake.org/cmake/help/v3.6/manual/cmake-toolchains.7.html#cross-compiling-using-clang
  ProcessorCount(nproc)
  get_host_triple(CHOST)
  get_target_triple(CBUILD)

  set(EMBED_CLANG OFF CACHE BOOL "Build Clang static libs as an ExternalProject and link to these instead of system libs.")
  set(EMBED_LIBCLANG_ONLY OFF CACHE BOOL "Build only libclang.a, and link to system libraries statically")

  if(NOT EMBED_CLANG)
    message(AUTHOR_WARNING "Building embedded LLVM that won't be used by any target, EMBED_CLANG is not set.")
  endif()

  if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    # Same as debian, see
    # https://salsa.debian.org/pkg-llvm-team/llvm-toolchain/blob/8/debian/rules
    set(EMBEDDED_BUILD_TYPE "RelWithDebInfo")
  elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
    set(EMBEDDED_BUILD_TYPE "MinSizeRel")
  else()
    set(EMBEDDED_BUILD_TYPE ${CMAKE_BUILD_TYPE})
  endif()

  if(${LLVM_VERSION} VERSION_EQUAL "9" OR ${LLVM_VERSION} VERSION_GREATER "9" )
    set(LLVM_FULL_VERSION "9.0.1")
    set(LLVM_DOWNLOAD_URL "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_FULL_VERSION}/llvm-${LLVM_FULL_VERSION}.src.tar.xz")
    set(LLVM_URL_CHECKSUM "SHA256=00a1ee1f389f81e9979f3a640a01c431b3021de0d42278f6508391a2f0b81c9a")
  elseif(${LLVM_VERSION} VERSION_EQUAL "8" OR ${LLVM_VERSION} VERSION_GREATER "8" )
    set(LLVM_FULL_VERSION "8.0.1")
    set(LLVM_DOWNLOAD_URL "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_FULL_VERSION}/llvm-${LLVM_FULL_VERSION}.src.tar.xz")
    set(LLVM_URL_CHECKSUM "SHA256=44787a6d02f7140f145e2250d56c9f849334e11f9ae379827510ed72f12b75e7")
  elseif(${LLVM_VERSION} VERSION_EQUAL "7" OR ${LLVM_VERSION} VERSION_GREATER "7" )
    set(LLVM_FULL_VERSION "7.1.0")
    set(LLVM_DOWNLOAD_URL "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_FULL_VERSION}/llvm-${LLVM_FULL_VERSION}.src.tar.xz")
    set(LLVM_URL_CHECKSUM "SHA256=1bcc9b285074ded87b88faaedddb88e6b5d6c331dfcfb57d7f3393dd622b3764")
  else()
    message(FATAL_ERROR "No supported LLVM version has been specified with LLVM_VERSION (LLVM_VERSION=${LLVM_VERSION}), aborting")
  endif()

  # Default to building almost all targets, + BPF specific ones
  # This builds almost everything, some may be unecessary but want to avoid linker hell.
  # Need to exclude LLVMHello on android, but it seems like just a dummy lib
  set(LLVM_LIBRARY_TARGETS LLVMDemangle
                           LLVMTableGen
                           LLVMCore
                           LLVMFuzzMutate
                           LLVMIRReader
                           LLVMCodeGen
                           LLVMSelectionDAG
                           LLVMAsmPrinter
                           LLVMMIRParser
                           LLVMGlobalISel
                           LLVMBinaryFormat
                           LLVMBitReader
                           LLVMBitWriter
                           LLVMTransformUtils
                           LLVMInstrumentation
                           LLVMAggressiveInstCombine
                           LLVMInstCombine
                           LLVMScalarOpts
                           LLVMipo
                           LLVMVectorize
                           LLVMObjCARCOpts
                           LLVMCoroutines
                           LLVMLinker
                           LLVMAnalysis
                           LLVMLTO
                           LLVMMC
                           LLVMMCParser
                           LLVMMCDisassembler
                           LLVMMCA
                           LLVMObject
                           LLVMObjectYAML
                           LLVMOption
                           LLVMOptRemarks
                           LLVMDebugInfoDWARF
                           LLVMDebugInfoMSF
                           LLVMDebugInfoCodeView
                           LLVMDebugInfoPDB
                           LLVMSymbolize
                           LLVMExecutionEngine
                           LLVMInterpreter
                           LLVMMCJIT
                           LLVMOrcJIT
                           LLVMRuntimeDyld
                           LLVMTarget
                           LLVMBPFCodeGen
                           LLVMBPFAsmParser
                           LLVMBPFDisassembler
                           LLVMBPFAsmPrinter
                           LLVMBPFDesc
                           LLVMBPFInfo
                           LLVMAsmParser
                           LLVMLineEditor
                           LLVMProfileData
                           LLVMCoverage
                           LLVMPasses
                           LLVMTextAPI
                           LLVMDlltoolDriver
                           LLVMLibDriver
                           LLVMXRay
                           LLVMTestingSupport
                           LLVMWindowsManifest
                           LLVMSupport)

  # These build flags are based off of Alpine, Debian and Gentoo packages
  # optimized for compatibility and reducing build targets
  set(LLVM_CONFIGURE_FLAGS   -Wno-dev
                             -DLLVM_TARGETS_TO_BUILD=BPF
                             -DCMAKE_BUILD_TYPE=${EMBEDDED_BUILD_TYPE}
                             -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
                             -DLLVM_BINUTILS_INCDIR=/usr/include
                             -DLLVM_BUILD_DOCS=OFF
                             -DLLVM_BUILD_EXAMPLES=OFF
                             -DLLVM_INCLUDE_EXAMPLES=OFF
                             -DLLVM_BUILD_EXTERNAL_COMPILER_RT=ON
                             -DLLVM_BUILD_LLVM_DYLIB=ON
                             -DLLVM_LINK_LLVM_DYLIB=OFF
                             -DLLVM_BUILD_TESTS=OFF
                             -DLLVM_INCLUDE_TESTS=OFF
                             -DLLVM_BUILD_TOOLS=OFF
                             -DLLVM_INCLUDE_TOOLS=OFF
                             -DLLVM_INCLUDE_BENCHMARKS=OFF
                             -DLLVM_DEFAULT_TARGET_TRIPLE=${CBUILD}
                             -DLLVM_ENABLE_ASSERTIONS=OFF
                             -DLLVM_ENABLE_CXX1Y=ON
                             -DLLVM_ENABLE_FFI=OFF
                             -DLLVM_ENABLE_LIBEDIT=OFF
                             -DLLVM_ENABLE_LIBCXX=OFF
                             -DLLVM_ENABLE_PIC=ON
                             -DLLVM_ENABLE_LIBPFM=OFF
                             -DLLVM_ENABLE_EH=ON
                             -DLLVM_ENABLE_RTTI=ON
                             -DLLVM_ENABLE_SPHINX=OFF
                             -DLLVM_ENABLE_TERMINFO=OFF
                             -DLLVM_ENABLE_ZLIB=ON
                             -DLLVM_HOST_TRIPLE=${CHOST}
                             -DLLVM_APPEND_VC_REV=OFF
                             )

  if(${TARGET_TRIPLE} MATCHES android)
    # FIXME hardcoded
    #find_program(LLVM_CONFIG_PATH llvm-config-8) # FIXME add version suffix
    #find_program(LLVM_TBLGEN_PATH llvm-tblgen-8)

    message("API LEVEL ${ANDROID_NATIVE_API_LEVEL}")
    list(APPEND LLVM_CONFIGURE_FLAGS -DCMAKE_TOOLCHAIN_FILE=/opt/android-ndk/build/cmake/android.toolchain.cmake)
    list(APPEND LLVM_CONFIGURE_FLAGS -DANDROID_ABI=${ANDROID_ABI})
    list(APPEND LLVM_CONFIGURE_FLAGS -DANDROID_NATIVE_API_LEVEL=${ANDROID_NATIVE_API_LEVEL})
    # list(APPEND LLVM_CONFIGURE_FLAGS -DLLVM_CONFIG_PATH=${LLVM_CONFIG_PATH}) # not needed for LLVm
    #list(APPEND LLVM_CONFIGURE_FLAGS -DLLVM_TABLEGEN=${LLVM_TBLGEN_PATH})
    #list(APPEND LLVM_CONFIGURE_FLAGS -DBUILD_SHARED_LIBS=ON)
    #-DCLANG_TABLEGEN=$(abspath $(HOST_OUT_DIR)/bin/clang-tblgen) \
    string(REPLACE ";" " " LLVM_MAKE_TARGETS "${LLVM_LIBRARY_TARGETS}" )
    set(BUILD_COMMAND "make -j${nproc} ${LLVM_MAKE_TARGETS} ") # nproc?
    message("USING BUILD COMMAND ${BUILD_COMMAND}")
    set(INSTALL_COMMAND "mkdir -p <INSTALL_DIR>/lib/ <INSTALL_DIR>/bin/ && find <BINARY_DIR>/lib/ | grep '\\.a$' | xargs -I@ cp @ <INSTALL_DIR>/lib/ && make install-cmake-exports && make install-llvm-headers && cp <BINARY_DIR>/NATIVE/bin/llvm-tblgen <INSTALL_DIR>/bin/ ")
  endif()

  if(${TARGET_TRIPLE} MATCHES android) # FIXME do NOT EQUAL host triple instead
    ExternalProject_Add(embedded_llvm_host
      URL "${LLVM_DOWNLOAD_URL}"
      URL_HASH "${LLVM_URL_CHECKSUM}"
      CONFIGURE_COMMAND /bin/bash -xc "cmake <SOURCE_DIR>"
      BUILD_COMMAND /bin/bash -c "make -j ${nproc} llvm-config llvm-tblgen"
      INSTALL_COMMAND /bin/bash -c "mkdir -p <INSTALL_DIR>/bin && cp <BINARY_DIR>/bin/llvm-tblgen <INSTALL_DIR>/bin && cp <BINARY_DIR>/bin/llvm-config <INSTALL_DIR>/bin"
      UPDATE_DISCONNECTED 1
      DOWNLOAD_NO_PROGRESS 1
    )

    ExternalProject_Get_Property(embedded_llvm_host INSTALL_DIR)
    set(LLVM_TBLGEN_PATH "${INSTALL_DIR}/bin/llvm-tblgen")
    set(LLVM_CONFIG_PATH "${INSTALL_DIR}/bin/llvm-config")
  endif()


  set(LLVM_TARGET_LIBS "")
  foreach(llvm_target IN LISTS LLVM_LIBRARY_TARGETS)
    list(APPEND LLVM_TARGET_LIBS "<INSTALL_DIR>/lib/lib${llvm_target}.a")
  endforeach(llvm_target)

  string(REPLACE ";" " " LLVM_CONFIG_FLAGS "${LLVM_CONFIGURE_FLAGS}" )
  set(LLVM_CONFIG_FLAGS "${LLVM_CONFIG_FLAGS}")
  message("LLVM CONF ${LLVM_CONFIG_FLAGS}")
  ExternalProject_Add(embedded_llvm
    URL "${LLVM_DOWNLOAD_URL}"
    URL_HASH "${LLVM_URL_CHECKSUM}"
    CONFIGURE_COMMAND /bin/bash -xc "cmake ${LLVM_CONFIG_FLAGS} <SOURCE_DIR>"
    BUILD_COMMAND /bin/bash -c "${BUILD_COMMAND}"
    BUILD_BYPRODUCTS ${LLVM_TARGET_LIBS}
    INSTALL_COMMAND /bin/bash -c "${INSTALL_COMMAND}" # Also install NATIVE tblgen
    UPDATE_DISCONNECTED 1
    DOWNLOAD_NO_PROGRESS 1
  )

  if(${TARGET_TRIPLE} MATCHES android) # FIXME do NOT EQUAL host triple instead
    ExternalProject_Add_StepDependencies(embedded_llvm install embedded_llvm_host)
  endif()

  ExternalProject_Get_Property(embedded_llvm INSTALL_DIR)
  set(EMBEDDED_LLVM_INSTALL_DIR ${INSTALL_DIR})
  set(LLVM_EMBEDDED_CMAKE_TARGETS "")

  include_directories(SYSTEM ${EMBEDDED_LLVM_INSTALL_DIR}/include)

  foreach(llvm_target IN LISTS LLVM_LIBRARY_TARGETS)
    list(APPEND LLVM_EMBEDDED_CMAKE_TARGETS ${llvm_target})
    add_library(${llvm_target} STATIC IMPORTED)
    set_property(TARGET ${llvm_target} PROPERTY IMPORTED_LOCATION ${EMBEDDED_LLVM_INSTALL_DIR}/lib/lib${llvm_target}.a)
    add_dependencies(${llvm_target} embedded_llvm)
  endforeach(llvm_target)
endif()
