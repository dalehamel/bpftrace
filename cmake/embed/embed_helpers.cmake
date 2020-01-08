include(ExternalProject)
include(ProcessorCount)
include(embed_patches)
include(embed_platforms)

# Detect the distribution bpftrace is being built on
function(detect_host_os os_id)
  file(STRINGS "/etc/os-release" HOST_OS_INFO)
  foreach(os_info IN LISTS HOST_OS_INFO)
    if(os_info MATCHES "^ID=")
      string(REPLACE "ID=" "" HOST_OS_ID ${os_info})
      set(${os_id} ${HOST_OS_ID} PARENT_SCOPE)
      break()
    endif()
  endforeach(os_info)
endfunction(detect_host_os os_id)

function(detect_host_os_family family_id)
  file(STRINGS "/etc/os-release" HOST_OS_INFO)
  foreach(os_info IN LISTS HOST_OS_INFO)
    if(os_info MATCHES "^ID_LIKE=")
      string(REPLACE "ID_LIKE=" "" HOST_OS_ID_LIKE ${os_info})
      set(${family_id} ${HOST_OS_ID_LIKE} PARENT_SCOPE)
      break()
    endif()
  endforeach(os_info)
endfunction(detect_host_os_family family_id)

# TODO dalehamel
# DRY up get_host_triple and get_target_triple by accepting a triple_type arg
# For simplicity sake, kept separate for now.
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

# If an external dependency doesn't use cmake, it cannot use the toolchain file
# To substitute for this, the toolchain is exported via standard env vars
function(get_toolchain_exports out)

# FIXME have a switch detecting if android
 # https://developer.android.com/ndk/guides/other_build_systems#autoconf
# FIXME make this a switch based on x86_64, aarch64, and arm7-a

  # FIXME use env var for toolchain home
  set(CROSS_EXPORTS "export TOOLCHAIN=/opt/android-ndk/toolchains/llvm/prebuilt/linux-x86_64 && \
                     export AR=$TOOLCHAIN/bin/arm-linux-androideabi-ar && \
                     export AS=$TOOLCHAIN/bin/arm-linux-androideabi-as && \
                     export CC=$TOOLCHAIN/bin/armv7a-linux-androideabi28-clang && \
                     export CXX=$TOOLCHAIN/bin/armv7a-linux-androideabi28-clang++ && \
                     export LD=$TOOLCHAIN/bin/arm-linux-androideabi-ld && \
                     export RANLIB=$TOOLCHAIN/bin/arm-linux-androideabi-ranlib && \
                     export STRIP=$TOOLCHAIN/bin/arm-linux-androideabi-strip"
                   )

  set(${out} "${CROSS_EXPORT}" PARENT_SCOPE)
endfunction(get_toolchain_exports out)

function(get_android_cross_tuple out)

#armeabi-v7a armv7a-linux-androideabi
#arm64-v8a aarch64-linux-android
#x86 i686-linux-android
#x86-64  x86_64-linux-android
endfunction(get_android_cross_tuple out)

function(fix_llvm_linkflags targetProperty propertyValue)
  set_target_properties(${target_property} PROPERTIES
      INTERFACE_LINK_LIBRARIES "${propertyValue}"
    )
endfunction(fix_llvm_linkflags targetProperty propertyValue)

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
