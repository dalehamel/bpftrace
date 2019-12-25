if(EMBED_CLANG)

  set(CHOST "x86_64-generic-linux") # FIXME expose these properly
  set(CBUILD "x86_64-generic-linux")
  set(LLVM_TARGET_ARCH "x86_64")
  set(LLVM_VERSION "8.0.1")

  include(ExternalProject)
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
  )

  if (EMBED_LLVM)
    ExternalProject_Add_StepDependencies(embedded_clang install embedded_llvm)
  endif()

  ExternalProject_Get_Property(embedded_clang INSTALL_DIR)
  set(EMBEDDED_CLANG_INSTALL_DIR ${INSTALL_DIR})
  set(CLANG_EMBEDDED_CMAKE_TARGETS "")

  foreach(clang_target IN LISTS CLANG_BUILD_TARGETS)
    string(REPLACE ".a" "" clang_target_noext ${clang_target})
    string(TOUPPER ${clang_target_noext} clang_target_upper)
    string(STRIP ${clang_target_upper} clang_target_name)

    list(APPEND CLANG_EMBEDDED_CMAKE_TARGETS ${clang_target_name})
    add_library(${clang_target_name} STATIC IMPORTED GLOBAL)
    set_property(TARGET ${clang_target_name} PROPERTY IMPORTED_LOCATION ${EMBEDDED_CLANG_INSTALL_DIR}/lib/${clang_target})
    add_dependencies(${clang_target_name} embedded_clang)
  endforeach(clang_target)
endif()
