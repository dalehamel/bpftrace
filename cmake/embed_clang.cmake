include(ExternalProject)

# FIXME implement triple detection - hardcoded to amd64 for now
# FIXME set cross compiler triple (CBUILD)via config flags
# SEE https://github.com/google/libcxx/blob/master/cmake/Modules/GetTriple.cmake
set(CHOST "x86_64-generic-linux")
set(CBUILD "x86_64-generic-linux")
set(LLVM_TARGET_ARCH "x86_64")
set(LLVM_VERSION "8.0.1")

# TO DO convert this to a list of libraries and compute
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
                       libLLVMSupport.a
                       libLLVMSymbolize.a
                       libLLVMTableGen.a
                       libLLVMTarget.a
                       libLLVMTextAPI.a
                       libLLVMTransformUtils.a
                       libLLVMVectorize.a
                       libLLVMWindowsManifest.a
                       libLLVMXRay.a)

set(LLVM_CONFIGURE_FLAGS   "-Wno-dev "
                           "-DLLVM_TARGETS_TO_BUILD=BPF "
                           "-DCMAKE_BUILD_TYPE=MinSizeRel "
                           "-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR> "
                           #"-DFFI_INCLUDE_DIR="$ffi_include_dir" "
                           "-DLLVM_BINUTILS_INCDIR=/usr/include "
                           "-DLLVM_BUILD_DOCS=OFF "
                           "-DLLVM_BUILD_EXAMPLES=OFF "
                           "-DLLVM_BUILD_EXTERNAL_COMPILER_RT=ON "
                           "-DLLVM_BUILD_LLVM_DYLIB=ON "
                           "-DLLVM_BUILD_TESTS=OFF "
                           "-DLLVM_DEFAULT_TARGET_TRIPLE=${CBUILD} "
                           "-DLLVM_ENABLE_ASSERTIONS=OFF "
                           "-DLLVM_ENABLE_CXX1Y=ON "
                           #"-DLLVM_ENABLE_FFI=ON "
                           "-DLLVM_ENABLE_LIBCXX=OFF "
                           "-DLLVM_ENABLE_PIC=ON "
                           "-DLLVM_ENABLE_RTTI=ON "
                           "-DLLVM_ENABLE_SPHINX=OFF "
                           "-DLLVM_ENABLE_TERMINFO=ON "
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

foreach(llvm_target IN LISTS LLVM_BUILD_TARGETS)
  string(REPLACE ".a" "" llvm_target_noext ${llvm_target})
  string(TOUPPER ${llvm_target_noext} llvm_target_upper)
  string(STRIP ${llvm_target_upper} llvm_target_name)

  list(APPEND LLVM_EMBEDDED_CMAKE_TARGETS ${llvm_target_name})
  add_library(${llvm_target_name} STATIC IMPORTED GLOBAL)
  set_property(TARGET ${llvm_target_name} PROPERTY IMPORTED_LOCATION ${EMBEDDED_LLVM_INSTALL_DIR}/lib/${llvm_target})
  add_dependencies(${llvm_target_name} embedded_llvm)
endforeach(llvm_target)

# FIXME  Split these in to separate files, allow using system LLVM
# if EMBED_LLVM isn't set to true
# Must verify versions match
set(CLANG_BUILD_TARGETS libclang.a
                        libclangAnalysis.a
                        libclangARCMigrate.a
                        libclangAST.a
                        libclangASTMatchers.a
                        libclangBasic.a
                        libclangCodeGen.a
                        libclangCrossTU.a
                        libclangDriver.a
                        libclangDynamicASTMatchers.a
                        libclangEdit.a
                        libclangFormat.a
                        libclangFrontend.a
                        libclangFrontendTool.a
                        libclangHandleCXX.a
                        libclangHandleLLVM.a
                        libclangIndex.a
                        libclangLex.a
                        libclangParse.a
                        libclangRewrite.a
                        libclangRewriteFrontend.a
                        libclangSema.a
                        libclangSerialization.a
                        libclangStaticAnalyzerCheckers.a
                        libclangStaticAnalyzerCore.a
                        libclangStaticAnalyzerFrontend.a
                        libclangTooling.a
                        libclangToolingASTDiff.a
                        libclangToolingCore.a
                        libclangToolingInclusions.a
                        libclangToolingRefactor.a)

set(CLANG_TARGET_LIBS "")
foreach(clang_target IN LISTS CLANG_BUILD_TARGETS)
  list(APPEND CLANG_TARGET_LIBS "<INSTALL_DIR>/lib/${clang_target}")
endforeach(clang_target)

set(CLANG_CONFIGURE_FLAGS  "-Wno-dev "
                           "-DCMAKE_PREFIX_PATH=${EMBEDDED_LLVM_INSTALL_DIR}/lib/cmake/llvm "
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
                           "<SOURCE_DIR>")

ExternalProject_Add(embedded_clang
  URL https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/cfe-${LLVM_VERSION}.src.tar.xz
  CONFIGURE_COMMAND PATH=$ENV{PATH} cmake  ${CLANG_CONFIGURE_FLAGS}
  INSTALL_COMMAND make install
  COMMAND cp <BINARY_DIR>/lib/libclang.a <INSTALL_DIR>/lib/libclang.a
  BUILD_BYPRODUCTS ${CLANG_TARGET_LIBS}
  UPDATE_DISCONNECTED 1
)

ExternalProject_Get_Property(embedded_clang INSTALL_DIR)
set(EMBEDDED_CLANG_INSTALL_DIR ${INSTALL_DIR})
set(CLANG_EMBEDDED_CMAKE_TARGETS "")

ExternalProject_Add_StepDependencies(embedded_clang install embedded_llvm)

foreach(clang_target IN LISTS CLANG_BUILD_TARGETS)
  string(REPLACE ".a" "" clang_target_noext ${clang_target})
  string(TOUPPER ${clang_target_noext} clang_target_upper)
  string(STRIP ${clang_target_upper} clang_target_name)

  list(APPEND CLANG_EMBEDDED_CMAKE_TARGETS ${clang_target_name})
  add_library(${clang_target_name} STATIC IMPORTED GLOBAL)
  set_property(TARGET ${clang_target_name} PROPERTY IMPORTED_LOCATION ${EMBEDDED_CLANG_INSTALL_DIR}/lib/${clang_target})
  add_dependencies(${clang_target_name} embedded_clang)
endforeach(clang_target)
