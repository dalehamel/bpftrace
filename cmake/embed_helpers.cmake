# Detect the distribution bpftrace is being built on
function(detect_os)
  file(STRINGS "/etc/os-release" HOST_OS_INFO)

  foreach(os_info IN LISTS HOST_OS_INFO)
    if(os_info MATCHES "^ID=")
      string(REPLACE "ID=" "" HOST_OS_ID ${os_info})
      set(HOST_OS_ID ${HOST_OS_ID} PARENT_SCOPE)
    elseif(os_info MATCHES "^ID_LIKE=")
      string(REPLACE "ID_LIKE=" "" HOST_OS_ID_LIKE ${os_info})
      set(HOST_OS_ID_LIKE ${HOST_OS_ID_LIKE} PARENT_SCOPE)
    endif()
  endforeach(os_info)
endfunction(detect_os)

function(get_host_triple out)
  # Get the architecture.
  set(arch ${CMAKE_HOST_SYSTEM_PROCESSOR})
  # Get os and vendor
  if (${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Linux")
    set(vendor "generic")
    set(os "linux")
  else()
    message(AUTHOR_WARNING "The host system ${CMAKE_HOST_SYSTEM_NAME} isn't supported")
  endif()
  set(triple "${arch}-${vendor}-${os}")
  set(${out} ${triple} PARENT_SCOPE)
  message(STATUS "Detected host triple: ${triple}")
endfunction()

function(get_target_triple out)
  # Get the architecture.
  set(arch ${CMAKE_SYSTEM_PROCESSOR})
  # Get os and vendor
  if (${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
    set(vendor "generic")
    set(os "linux")
  elseif(${CMAKE_SYSTEM_NAME} STREQUAL "Android")
    set(vendor "android")
    set(os "linux")
  else()
    message(AUTHOR_WARNING "The target system ${CMAKE_SYSTEM_NAME} isn't supported")
  endif()
  set(triple "${arch}-${vendor}-${os}")
  set(${out} ${triple} PARENT_SCOPE)
  message(STATUS "Detected target triple: ${triple}")
endfunction()

function(prepare_patch_series patchSeries patchPath)
  message("Writing patch series to ${patchPath}/series ...")
  file(WRITE "${patchPath}/series" "")
  foreach(patch_info IN ITEMS ${patchSeries})
    file(APPEND "${patchPath}/series" "${patch_info}\n")
  endforeach(patch_info)
endfunction(prepare_patch_series patchSeries patchPath)

function(fetch_patches patchName patchPath patchURL patchChecksum)
  if(NOT EXISTS "${patchPath}/${patchName}")
    message("Downloading ${DEBIAN_PATCH_URL}")
    file(MAKE_DIRECTORY ${patchPath})
    file(DOWNLOAD "${DEBIAN_PATCH_URL}" "${patchPath}/${patchName}"
         EXPECTED_HASH SHA256=${patchChecksum})

    # Can add to this if ladder to support additional patch formats, tar
    # probably catches quit a lot...
    if(patchName MATCHES .*tar.*)
      execute_process(COMMAND tar -xpf ${patchPath}/${patchName} --strip-components=3 -C ${patchPath})
    else()
      message("Patch ${patchName} doesn't appear to a tar achive, assuming it is a plaintext patch")
    endif()
  endif()
endfunction(fetch_patches patchName patchPatch patchURL patchChecksum)

function(prepare_clang_patches patch_command)
  message("Building embedded Clang against host LLVM, checking compatibiilty...")
  detect_os()
  message("HOST ID ${HOST_OS_ID}")

  set(CLANG_PATCH_COMMAND "/bin/true")
  if(HOST_OS_ID STREQUAL "debian" OR HOST_OS_ID STREQUAL "ubuntu" OR HOST_OS_ID_LIKE STREQUAL "debian")
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
