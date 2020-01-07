if(NOT EMBED_ANALYSIS)
  return()
endif()

# To cross compile, we'll need native bison and flex binaries to generate the
# object file for bpftrace's parser. This means BISON and FLEX must be built
# from source if they aren't available in the build root already. Rather than
# depend on the cross toolchain to do this, ensure they can be built for the
# target platform by "embedding them", and hinting this target to find_package

set(BISON_DOWNLOAD_URL "https://ftp.gnu.org/gnu/bison/bison-3.1.tar.gz")
set(BISON_CHECKSUM "SHA256=00a1ee1f389f81e9979f3a640a01c431b3021de0d42278f6508391a2f0b81c9a")

set(BISON_CONFIGURE_COMMAND CONFIGURE_COMMAND /bin/bash -xc "<SOURCE_DIR>/gnulib-tool --create-testdir --lib='libargp' --dir=argp_sources argp && cd <BINARY_DIR> &&  <SOURCE_DIR>/argp_sources/configure")
set(BISON_BUILD_COMMAND BUILD_COMMAND /bin/bash -c "make -j${nproc}")
set(BISON_INSTALL_COMMAND INSTALL_COMMAND /bin/bash -c "mkdir -p <INSTALL_DIR>/lib && mkdir -p <INSTALL_DIR>/include && cp <BINARY_DIR>/gllib/libargp.a <INSTALL_DIR>/lib && cp <SOURCE_DIR>/gllib/argp.h <INSTALL_DIR>/include && cp <SOURCE_DIR>/gllib/argp.h <INSTALL_DIR>/include")

ExternalProject_Add(embedded_bison
  URL "${BISON_DOWNLOAD_URL}"
  URL_HASH "${BISON_CHECKSUM}"
  ${BISON_CONFIGURE_COMMAND}
  ${BISON_BUILD_COMMAND}
  ${BISON_INSTALL_COMMAND}
  UPDATE_DISCONNECTED 1
  DOWNLOAD_NO_PROGRESS 1
)

# SET HINT PATH by geting external project var, like done for clang

set(FLEX_DOWNLOAD_URL "https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz")
set(FLEX_CHECKSUM "SHA256=00a1ee1f389f81e9979f3a640a01c431b3021de0d42278f6508391a2f0b81c9a")

set(FLEX_CONFIGURE_COMMAND CONFIGURE_COMMAND /bin/bash -xc "<SOURCE_DIR>/gnulib-tool --create-testdir --lib='libargp' --dir=argp_sources argp && cd <BINARY_DIR> &&  <SOURCE_DIR>/argp_sources/configure")
set(FLEX_BUILD_COMMAND BUILD_COMMAND /bin/bash -c "make -j${nproc}")
set(FLEX_INSTALL_COMMAND INSTALL_COMMAND /bin/bash -c "mkdir -p <INSTALL_DIR>/lib && mkdir -p <INSTALL_DIR>/include && cp <BINARY_DIR>/gllib/libargp.a <INSTALL_DIR>/lib && cp <SOURCE_DIR>/gllib/argp.h <INSTALL_DIR>/include && cp <SOURCE_DIR>/gllib/argp.h <INSTALL_DIR>/include")

ExternalProject_Add(embedded_flex
  URL "${FLEX_DOWNLOAD_URL}"
  URL_HASH "${FLEX_CHECKSUM}"
  ${FLEX_CONFIGURE_COMMAND}
  ${FLEX_BUILD_COMMAND}
  ${FLEX_INSTALL_COMMAND}
  UPDATE_DISCONNECTED 1
  DOWNLOAD_NO_PROGRESS 1
)

# SET HINT PATH by geting external project var, like done for clang
