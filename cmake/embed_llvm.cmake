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

  set(LLVM_BUILD_TARGETS libLLVMAggressiveInstCombine.a
                         libLLVMAnalysis.a
                         libLLVMAsmParser.a
                         libLLVMAsmPrinter.a
                         libLLVMBinaryFormat.a
                         libLLVMBitReader.a
                         libLLVMBitWriter.a
                         libLLVMBPFAsmParser.a
                         libLLVMBPFAsmPrinter.a
                         libLLVMBPFCodeGen.a
                         libLLVMBPFDesc.a
                         libLLVMBPFDisassembler.a
                         libLLVMBPFInfo.a
                         libLLVMCodeGen.a
                         libLLVMCore.a
                         libLLVMCoroutines.a
                         libLLVMCoverage.a
                         libLLVMDebugInfoCodeView.a
                         libLLVMDebugInfoDWARF.a
                         libLLVMDebugInfoMSF.a
                         libLLVMDebugInfoPDB.a
                         libLLVMDemangle.a
                         libLLVMDlltoolDriver.a
                         libLLVMExecutionEngine.a
                         libLLVMFuzzMutate.a
                         libLLVMGlobalISel.a
                         libLLVMInstCombine.a
                         libLLVMInstrumentation.a
                         libLLVMInterpreter.a
                         libLLVMipo.a
                         libLLVMIRReader.a
                         libLLVMLibDriver.a
                         libLLVMLineEditor.a
                         libLLVMLinker.a
                         libLLVMLTO.a
                         libLLVMMC.a
                         libLLVMMCA.a
                         libLLVMMCDisassembler.a
                         libLLVMMCJIT.a
                         libLLVMMCParser.a
                         libLLVMMIRParser.a
                         libLLVMObjCARCOpts.a
                         libLLVMObject.a
                         libLLVMObjectYAML.a
                         libLLVMOption.a
                         libLLVMOptRemarks.a
                         libLLVMOrcJIT.a
                         libLLVMPasses.a
                         libLLVMProfileData.a
                         libLLVMRuntimeDyld.a
                         libLLVMScalarOpts.a
                         libLLVMSelectionDAG.a
                         libLLVMSymbolize.a
                         libLLVMTableGen.a
                         libLLVMTarget.a
                         libLLVMTextAPI.a
                         libLLVMTransformUtils.a
                         libLLVMVectorize.a
                         libLLVMWindowsManifest.a
                         libLLVMXRay.a
                         libLLVMSupport.a)

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
    list(APPEND LLVM_TARGET_LIBS "<INSTALL_DIR>/lib/${llvm_target}")
  endforeach(llvm_target)

  ExternalProject_Add(embedded_llvm
    URL https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-${LLVM_VERSION}.src.tar.xz
    CONFIGURE_COMMAND PATH=$ENV{PATH} cmake  ${LLVM_CONFIGURE_FLAGS}
    BUILD_BYPRODUCTS ${LLVM_TARGET_LIBS}
    UPDATE_DISCONNECTED 1
  )

  ExternalProject_Get_Property(embedded_llvm INSTALL_DIR)
  set(EMBEDDED_LLVM_INSTALL_DIR ${INSTALL_DIR})
  set(LLVM_EMBEDDED_CMAKE_TARGETS "")

  include_directories(SYSTEM ${EMBEDDED_LLVM_INSTALL_DIR}/include)

  foreach(llvm_target IN LISTS LLVM_BUILD_TARGETS)
    string(REPLACE "lib" "" llvm_target_nolib ${llvm_target})
    string(REPLACE ".a" "" llvm_target_noext ${llvm_target_nolib})
    string(STRIP ${llvm_target_noext} llvm_target_name)

    list(APPEND LLVM_EMBEDDED_CMAKE_TARGETS ${llvm_target_name})
    add_library(${llvm_target_name} STATIC IMPORTED)
    set_property(TARGET ${llvm_target_name} PROPERTY IMPORTED_LOCATION ${EMBEDDED_LLVM_INSTALL_DIR}/lib/${llvm_target})
    add_dependencies(${llvm_target_name} embedded_llvm)
  endforeach(llvm_target)

  set_target_properties(LLVMSupport PROPERTIES
    INTERFACE_LINK_LIBRARIES "-Wl,-Bstatic -lz;-Wl,-Bdynamic -lrt;dl;-Wl,-Bdynamic -lpthread;m;${EMBEDDED_LLVM_INSTALL_DIR}/lib/libLLVMDemangle.a"
  )

endif()