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


message("Building embedded clang against host LLVM, checking compatibiilty...")
detect_os()

message("HOST ID ${HOST_OS_ID}")
# FIXME SHasums

# FIXME make this a function
# accept an array of quilt patch strings, a URL and SHA for the patch archive, and the directory to apply thepatches to
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
