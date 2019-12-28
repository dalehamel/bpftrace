if(EMBED_LLVM)
  include(ExternalProject)

  # FIXME implement triple detection - hardcoded to amd64 for now
  # FIXME set cross compiler triple (CBUILD)via config flags
  # SEE https://github.com/google/libcxx/blob/master/cmake/Modules/GetTriple.cmake
  # SEE also for using LLVM as cross compiler
  # https://cmake.org/cmake/help/v3.6/manual/cmake-toolchains.7.html#cross-compiling-using-clang
  set(CHOST "x86_64-generic-linux")
  set(CBUILD "x86_64-generic-linux")
  set(LLVM_TARGET_ARCH "x86_64")
  set(LLVM_VERSION "8.0.1")

  set(LLVM_BUILD_TARGETS LLVMAggressiveInstCombine
                         LLVMAnalysis
                         LLVMAsmParser
                         LLVMAsmPrinter
                         LLVMBinaryFormat
                         LLVMBitReader
                         LLVMBitWriter
                         LLVMBPFAsmParser
                         LLVMBPFAsmPrinter
                         LLVMBPFCodeGen
                         LLVMBPFDesc
                         LLVMBPFDisassembler
                         LLVMBPFInfo
                         LLVMCodeGen
                         LLVMCore
                         LLVMCoroutines
                         LLVMCoverage
                         LLVMDebugInfoCodeView
                         LLVMDebugInfoDWARF
                         LLVMDebugInfoMSF
                         LLVMDebugInfoPDB
                         LLVMDemangle
                         LLVMDlltoolDriver
                         LLVMExecutionEngine
                         LLVMFuzzMutate
                         LLVMGlobalISel
                         LLVMInstCombine
                         LLVMInstrumentation
                         LLVMInterpreter
                         LLVMipo
                         LLVMIRReader
                         LLVMLibDriver
                         LLVMLineEditor
                         LLVMLinker
                         LLVMLTO
                         LLVMMC
                         LLVMMCA
                         LLVMMCDisassembler
                         LLVMMCJIT
                         LLVMMCParser
                         LLVMMIRParser
                         LLVMObjCARCOpts
                         LLVMObject
                         LLVMObjectYAML
                         LLVMOption
                         LLVMOptRemarks
                         LLVMOrcJIT
                         LLVMPasses
                         LLVMProfileData
                         LLVMRuntimeDyld
                         LLVMScalarOpts
                         LLVMSelectionDAG
                         LLVMSymbolize
                         LLVMTableGen
                         LLVMTarget
                         LLVMTextAPI
                         LLVMTransformUtils
                         LLVMVectorize
                         LLVMWindowsManifest
                         LLVMXRay
                         LLVMSupport)

  # See https://llvm.org/docs/CMake.html#llvm-specific-variables
  set(LLVM_CONFIGURE_FLAGS   "-Wno-dev "
                             "-DLLVM_TARGETS_TO_BUILD=BPF "
                             "-DCMAKE_BUILD_TYPE=MinSizeRel "
                             "-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR> "
                             "-DLLVM_BINUTILS_INCDIR=/usr/include "
                             "-DLLVM_BUILD_DOCS=OFF "
                             "-DLLVM_BUILD_EXAMPLES=OFF "
                             "-DLLVM_BUILD_EXTERNAL_COMPILER_RT=ON "
                             "-DLLVM_BUILD_LLVM_DYLIB=ON "
                             "-DLLVM_BUILD_TESTS=OFF "
                             "-DLLVM_DEFAULT_TARGET_TRIPLE=${CBUILD} "
                             "-DLLVM_ENABLE_ASSERTIONS=OFF "
                             "-DLLVM_ENABLE_CXX1Y=ON "
                             "-DLLVM_ENABLE_FFI=OFF " # FIXME
                             "-DLLVM_ENABLE_LIBEDIT=OFF "
                             "-DLLVM_ENABLE_LIBCXX=OFF "
                             "-DLLVM_ENABLE_PIC=ON "
                             "-DLLVM_ENABLE_LIBPFM=OFF "
                             "-DLLVM_ENABLE_EH=ON "
                             "-DLLVM_ENABLE_RTTI=ON "
                             "-DLLVM_ENABLE_SPHINX=OFF "
                             "-DLLVM_ENABLE_TERMINFO=OFF "
                             "-DLLVM_ENABLE_ZLIB=ON "
                             "-DLLVM_HOST_TRIPLE=${CHOST} "
                             "-DLLVM_INCLUDE_EXAMPLES=OFF "
                             "-DLLVM_LINK_LLVM_DYLIB=ON "
                             "-DLLVM_APPEND_VC_REV=OFF "
                             "<SOURCE_DIR>")

  set(LLVM_TARGET_LIBS "")
  foreach(llvm_target IN LISTS LLVM_BUILD_TARGETS)
    list(APPEND LLVM_TARGET_LIBS "<INSTALL_DIR>/lib/lib${llvm_target}.a")
  endforeach(llvm_target)

  ExternalProject_Add(embedded_llvm
    URL https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-${LLVM_VERSION}.src.tar.xz
    CONFIGURE_COMMAND PATH=$ENV{PATH} cmake  ${LLVM_CONFIGURE_FLAGS}
    BUILD_BYPRODUCTS ${LLVM_TARGET_LIBS}
    UPDATE_DISCONNECTED 1
    DOWNLOAD_NO_PROGRESS 1
  )

  ExternalProject_Get_Property(embedded_llvm INSTALL_DIR)
  set(EMBEDDED_LLVM_INSTALL_DIR ${INSTALL_DIR})
  set(LLVM_EMBEDDED_CMAKE_TARGETS "")

  include_directories(SYSTEM ${EMBEDDED_LLVM_INSTALL_DIR}/include)

  foreach(llvm_target IN LISTS LLVM_BUILD_TARGETS)
    list(APPEND LLVM_EMBEDDED_CMAKE_TARGETS ${llvm_target})
    add_library(${llvm_target} STATIC IMPORTED)
    set_property(TARGET ${llvm_target} PROPERTY IMPORTED_LOCATION ${EMBEDDED_LLVM_INSTALL_DIR}/lib/lib${llvm_target}.a)
    add_dependencies(${llvm_target} embedded_llvm)
  endforeach(llvm_target)
endif()
