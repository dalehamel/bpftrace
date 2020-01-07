if(NOT EMBED_BINUTILS)
  return()
endif()

# The only time binutils should ever need to be embedded is when cross-compiling
# Have a check that asserts this
# It doesn't look like these dependencies are actually required, so need to verify
# this, may only be needed for btf? Build it anyways, but lower priority to figure out

set(BINUTILS_VERSION "2.27") # This is what the android toolchain uses for r21 pre
set(BINUTILS_DOWNLOAD_URL "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz")
set(BINUTILS_CHECKSUM "SHA256=00a1ee1f389f81e9979f3a640a01c431b3021de0d42278f6508391a2f0b81c9a")

set(BFD_CONFIGURE_COMMAND CONFIGURE_COMMAND /bin/bash -xc "<SOURCE_DIR>/gnulib-tool --create-testdir --lib='libargp' --dir=argp_sources argp && cd <BINARY_DIR> &&  <SOURCE_DIR>/argp_sources/configure")
set(BFD_BUILD_COMMAND BUILD_COMMAND /bin/bash -c "make -j${nproc}")
set(BFD_INSTALL_COMMAND INSTALL_COMMAND /bin/bash -c "mkdir -p <INSTALL_DIR>/lib && mkdir -p <INSTALL_DIR>/include && cp <BINARY_DIR>/gllib/libargp.a <INSTALL_DIR>/lib && cp <SOURCE_DIR>/gllib/argp.h <INSTALL_DIR>/include && cp <SOURCE_DIR>/gllib/argp.h <INSTALL_DIR>/include")

ExternalProject_Add(embedded_binutils_bfd
  URL "${BINUTILS_DOWNLOAD_URL}"
  URL_HASH "${BINUTILS_CHECKSUM}"
  ${BFD_CONFIGURE_COMMAND}
  ${BFD_BUILD_COMMAND}
  ${BFD_INSTALL_COMMAND}
  UPDATE_DISCONNECTED 1
  DOWNLOAD_NO_PROGRESS 1
)

set(OPCODES_CONFIGURE_COMMAND CONFIGURE_COMMAND /bin/bash -c "")
set(OPCODES_BUILD_COMMAND BUILD_COMMAND /bin/bash -c "make -j${nproc}")
set(OPCODES_INSTALL_COMMAND INSTALL_COMMAND /bin/bash -c "mkdir -p <INSTALL_DIR>/lib && mkdir -p <INSTALL_DIR>/include && cp <BINARY_DIR>/gllib/libargp.a <INSTALL_DIR>/lib && cp <SOURCE_DIR>/gllib/argp.h <INSTALL_DIR>/include && cp <SOURCE_DIR>/gllib/argp.h <INSTALL_DIR>/include")
ExternalProject_Add(embedded_binutils_opcodes
  URL "${BINUTILS_DOWNLOAD_URL}"
  URL_HASH "${BINUTILS_CHECKSUM}"
  ${OPCODES_CONFIGURE_COMMAND}
  ${OPCODES_BUILD_COMMAND}
  ${OPCODES_INSTALL_COMMAND}
  UPDATE_DISCONNECTED 1
  DOWNLOAD_NO_PROGRESS 1
)
