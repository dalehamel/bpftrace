# This file is for handling the logic of downloading and applying any necessary
# patches to external projects, using helper functions and the `quilt` utility
# Each package that needs to be patched should define their own patch function
# that can handle the logic necessary to correctly patch the project.

# Patch function for clang to be able to link to system LLVM
function(prepare_clang_patches patch_command)
  message("Building embedded Clang against host LLVM, checking compatibiilty...")
  detect_host_os(HOST_OS_ID)
  detect_host_os_family(HOST_OS_FAMILY)

  set(CLANG_PATCH_COMMAND "/bin/true")
  if(HOST_OS_ID STREQUAL "debian" OR HOST_OS_ID STREQUAL "ubuntu" OR HOST_OS_FAMILY STREQUAL "debian")
    message("Building on a debian-like system, will apply minimal debian patches to clang sources in order to build.")
    set(PATCH_NAME "debian-patches.tar.gz")
    set(PATCH_PATH "${CMAKE_CURRENT_BINARY_DIR}/debian-llvm/")
    set(DEBIAN_PATCH_SERIES "")
    list(APPEND DEBIAN_PATCH_SERIES "kfreebsd/clang_lib_Basic_Targets.diff -p2")

    if(${LLVM_VERSION} VERSION_EQUAL "8" OR ${LLVM_VERSION} VERSION_GREATER "8" )
      set(DEBIAN_PATCH_URL_BASE "https://salsa.debian.org/pkg-llvm-team/llvm-toolchain/-/archive/debian/")
      set(DEBIAN_PATCH_URL_PATH "8_8.0.1-1/llvm-toolchain-debian-8_8.0.1-1.tar.gz?path=debian%2Fpatches")
      set(DEBIAN_PATCH_URL "${DEBIAN_PATCH_URL_BASE}/${DEBIAN_PATCH_URL_PATH}")
      set(DEBIAN_PATCH_CHECKSUM 2b845a5de3cc2d49924b632d3e7a2fca53c55151e586528750ace2cb2aae23db)
    else()
      message(FATAL_ERROR "No supported LLVM version has been specified with LLVM_VERSION (LLVM_VERSION=${LLVM_VERSION}), aborting")
    endif()

    list(LENGTH DEBIAN_PATCH_SERIES NUM_PATCHES)
    message("${NUM_PATCHES} patches will be applied for Clang ${LLVM_VERSION} on ${HOST_OS_ID}/${HOST_OS_ID_LIKE}")
    fetch_patches(${PATCH_NAME} ${PATCH_PATH} ${DEBIAN_PATCH_URL} ${DEBIAN_PATCH_CHECKSUM})
    prepare_patch_series("${DEBIAN_PATCH_SERIES}" ${PATCH_PATH})

    # These targets are from LLVMExports.cmake, so may vary by distribution.
    # in order to avoid fighting with what the LLVM package wants the linker to
    # do, it is easiest to just override the target link properties

    # These libraries are missing from the linker line command line
    # in the upstream package
    # Adding extra libraries here shouldn't affect the result, as they will be
    # ignored by the linker if not needed

    # It matters a lot what linker is being used. GNU toolchain accepts the
    # -Wl,--start-group option for avoiding circular dependencies in static
    # libs. Otherwise, with lld or other linkers, and it seems the default
    # behavior of lld (see) https://reviews.llvm.org/D43786 is to do this
    # anyays.
    #
    # For other linker, the order of static libraries is very significant, an
    # must be precomputed to find the correct non-circular permutation...
    set_target_properties(LLVMSupport PROPERTIES
      INTERFACE_LINK_LIBRARIES "LLVMCoroutines;LLVMCoverage;LLVMDebugInfoDWARF;LLVMDebugInfoPDB;LLVMDemangle;LLVMDlltoolDriver;LLVMFuzzMutate;LLVMInterpreter;LLVMLibDriver;LLVMLineEditor;LLVMLTO;LLVMMCA;LLVMMIRParser;LLVMObjCARCOpts;LLVMObjectYAML;LLVMOption;LLVMOptRemarks;LLVMPasses;LLVMPerfJITEvents;LLVMSymbolize;LLVMTableGen;LLVMTextAPI;LLVMWindowsManifest;LLVMXRay;-Wl,-Bstatic -ltinfo;"
    )

    # Need to omit lpthread here or it will try and link statically, and fail
    set_target_properties(LLVMCodeGen PROPERTIES
      INTERFACE_LINK_LIBRARIES "LLVMAnalysis;LLVMBitReader;LLVMBitWriter;LLVMCore;LLVMMC;LLVMProfileData;LLVMScalarOpts;LLVMSupport;LLVMTarget;LLVMTransformUtils"
    )

    set(CLANG_PATCH_COMMAND "(QUILT_PATCHES=${PATCH_PATH} quilt push -a || [[ $? -eq 2 ]])")
  endif()
  set(${patch_command} "${CLANG_PATCH_COMMAND}" PARENT_SCOPE)
endfunction(prepare_clang_patches patch_command)

function(prepare_bcc_patches patch_command)
  get_target_triple(TARGET_TRIPLE)

  # FIXME maybe check BCC version and bail / warn if not 0.12.0?
  if(${TARGET_TRIPLE} MATCHES android)
    set(BCC_ANDROID_PATCH_URL "https://gist.github.com/dalehamel/da2f73357cd8cc4e60a1218e562a472b/archive/0accba3a1f10956c1323d7c5742e663a4a7c8370.tar.gz")
    set(BCC_ANDROID_PATCH_CHECKSUM b711a316ec8209e1a677e43570bbcfadec4ed3953e27ceeb23c501c41bfc86ea)

    set(PATCH_NAME "bcc-patches.tar.gz")
    set(PATCH_PATH "${CMAKE_CURRENT_BINARY_DIR}/bcc-android/")

    set(BCC_ANDROID_PATCH_SERIES "")
    list(APPEND BCC_ANDROID_PATCH_SERIES "")

    message("${NUM_PATCHES} patches will be applied for BCC to build correctly for Android.")
    fetch_patches(${PATCH_NAME} ${PATCH_PATH} ${BCC_ANDROID_PATCH_URL} ${BCC_ANDROID_PATCH_CHECKSUM})
    prepare_patch_series("${BCC_ANDROID_PATCH_SERIES}" ${PATCH_PATH})
    set(BCC_ANDROID_PATCH_COMMAND "(QUILT_PATCHES=${PATCH_PATH} quilt push -a || [[ $? -eq 2 ]])")
  endif()
  set(${patch_command} "${BCC_ANDROID_PATCH_COMMAND}" PARENT_SCOPE)
endfunction(prepare_bcc_patches patch_command)

function(prepare_libelf_patches patch_command)
  get_target_triple(TARGET_TRIPLE)

  # FIXME this should actually check if toolchain is LLVM, not android. Nothing
  # here is android specific, android toolchain just happens to use LLVM
  if(${TARGET_TRIPLE} MATCHES android)
    set(LIBELF_LLVM_PATCH_URL "https://gist.github.com/dalehamel/8fc4d9d25295e86d4347229270f29b48/archive/603ac72b18e242a7f4bd31be39419db3a4bd9a83.tar.gz")
    set(LIBELF_LLVM_PATCH_CHECKSUM c671bdd98e194f3fd6abd2f668406754851aeb1fe3d32b1269ad06906e33911e)

    set(PATCH_NAME "libelf-llvm-patches.tar.gz")
    set(PATCH_PATH "${CMAKE_CURRENT_BINARY_DIR}/libelf-llvm/")

    set(LIBELF_LLVM_PATCH_SERIES "")
    list(APPEND LIBELF_LLVM_PATCH_SERIES "")

    message("${NUM_PATCHES} patches will be applied for libelf to be built by LLVM toolchain.")
    fetch_patches(${PATCH_NAME} ${PATCH_PATH} ${LIBELF_LLVM_PATCH_URL} ${LIBELF_LLVM_PATCH_CHECKSUM})
    prepare_patch_series("${LIBELF_LLVM_PATCH_SERIES}" ${PATCH_PATH})
    set(LIBELF_LLVM_PATCH_COMMAND "(QUILT_PATCHES=${PATCH_PATH} quilt push -a || [[ $? -eq 2 ]])")
  endif()
  set(${patch_command} "${LIBELF_LLVM_PATCH_COMMAND}" PARENT_SCOPE)
endfunction(prepare_libelf_patches patch_command)
