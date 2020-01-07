if(NOT EMBED_LIBELF)
  return()
endif()
include(embed_helpers)

set(GNULIB_DOWNLOAD_URL "http://git.savannah.gnu.org/gitweb/?p=gnulib.git;a=snapshot;h=cd46bf0ca5083162f3ac564ebbdeb6371085df45;sf=tgz")
set(GNULIB_CHECKSUM "SHA256=00a1ee1f389f81e9979f3a640a01c431b3021de0d42278f6508391a2f0b81c9a")

ExternalProject_Add(embedded_gnulib
  URL "${GNULIB_DOWNLOAD_URL}"
  URL_HASH "${GNULIB_CHECKSUM}"
  CONFIGURE_COMMAND /bin/bash -xc "<SOURCE_DIR>/gnulib-tool --create-testdir --lib='libargp' --dir=argp_sources argp && cd <BINARY_DIR> &&  <SOURCE_DIR>/argp_sources/configure"
  BUILD_COMMAND /bin/bash -c "make -j${nproc}"
  INSTALL_COMMAND /bin/bash -c "mkdir -p <INSTALL_DIR>/lib && mkdir -p <INSTALL_DIR>/include && cp <BINARY_DIR>/gllib/libargp.a <INSTALL_DIR>/lib && cp <SOURCE_DIR>/gllib/argp.h <INSTALL_DIR>/include && cp <SOURCE_DIR>/gllib/argp.h <INSTALL_DIR>/include"
 # https://github.com/michalgr/bpftrace/blob/build_scripts_for_android/argp/headers/argp-wrapper.h # FIXME also need to install this, maybe as a patch to argp.h?
  UPDATE_DISCONNECTED 1
  DOWNLOAD_NO_PROGRESS 1
)

set(ELFUTILS_VERSION 0.176)
set(ELFUTILS_DOWNLOAD_URL "http://sourceware.org/pub/elfutils/${ELFUTILS_VERSION}/elfutils-${ELFUTILS_VERSION}.tar.bz2")
set(ELFUTILS_CHECKSUM "SHA256=00a1ee1f389f81e9979f3a640a01c431b3021de0d42278f6508391a2f0b81c9a")

# FIXME have a check that determines if toolchain is clang, and if so applies patch
# To get it to compile by getting rid of inline function definitions

ExternalProject_Add(embedded_libelf
  URL "${ELFUTILS_DOWNLOAD_URL}"
  URL_HASH "${ELFUTILS_CHECKSUM}"
  CONFIGURE_COMMAND /bin/bash -xc "<SOURCE_DIR>/elfutils-${ELFUTILS_VERSION}/configure"
  BUILD_COMMAND /bin/bash -c "make -j${nproc}"
  INSTALL_COMMAND /bin/bash -c "mkdir -p <INSTALL_DIR>/lib && mkdir -p <INSTALL_DIR>/include && cp <BINARY_DIR>/gllib/libargp.a <INSTALL_DIR>/lib && cp <SOURCE_DIR>/gllib/argp.h <INSTALL_DIR>/include && cp <SOURCE_DIR>/gllib/argp.h <INSTALL_DIR>/include"
 # https://github.com/michalgr/bpftrace/blob/build_scripts_for_android/argp/headers/argp-wrapper.h # FIXME also need to install this, maybe as a patch to argp.h?
  UPDATE_DISCONNECTED 1
  DOWNLOAD_NO_PROGRESS 1
)

ExternalProject_Add_StepDependencies(embedded_libelf install embedded_gnulib)
