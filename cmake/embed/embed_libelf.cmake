if(NOT EMBED_LIBELF)
  return()
endif()
include(embed_helpers)

set(GNULIB_DOWNLOAD_URL "http://git.savannah.gnu.org/gitweb/?p=gnulib.git&a=snapshot&h=cd46bf0ca5083162f3ac564ebbdeb6371085df45&sf=tgz")
set(GNULIB_CHECKSUM "SHA256=b355951d916eda73f0e7fb9d828623c09185b6624073492d7de88726c6aa6753")

# FIXME still need to shim this in
set(ARGP_HEADER_HACK "\
#ifndef ARGP_EI\n\
#  define ARGP_EI inline\n\
#endif\n\
 \
// since ece81a73b64483a68f5157420836d84beb3a1680 argp.h as distributed with \
// gnulib requires _GL_INLINE_HEADER_BEGIN macro to be defined. \
#ifndef _GL_INLINE_HEADER_BEGIN\n\
#  define _GL_INLINE_HEADER_BEGIN\n\
#  define _GL_INLINE_HEADER_END\n\
#endif\n")

# Patch for argp header here
# Actually this isn't necessary if we do michal's approach and just install the header under a different name, and include this file?

ExternalProject_Add(embedded_gnulib
  URL "${GNULIB_DOWNLOAD_URL}"
  URL_HASH "${GNULIB_CHECKSUM}"
  CONFIGURE_COMMAND /bin/bash -xc "<SOURCE_DIR>/gnulib-tool --create-testdir --lib='libargp' --dir=<SOURCE_DIR>/argp_sources argp && \
                                   ${CROSS_EXPORTS} && \
                                   <SOURCE_DIR>/argp_sources/configure --host armv7a-linux-androideabi --prefix <INSTALL_DIR>" # extra flags to configure needed

  BUILD_COMMAND /bin/bash -c "make -j${nproc}"
  INSTALL_COMMAND /bin/bash -c "mkdir -p <INSTALL_DIR>/lib <INSTALL_DIR>/include && \
                                cp <BINARY_DIR>/gllib/libargp.a <INSTALL_DIR>/lib && \
                                cp <SOURCE_DIR>/argp_sources/gllib/argp.h <INSTALL_DIR>/include"
  UPDATE_DISCONNECTED 1
  DOWNLOAD_NO_PROGRESS 1
)

ExternalProject_Get_Property(embedded_gnulib INSTALL_DIR)
set(EMBEDDED_GNULIB_INSTALL_DIR ${INSTALL_DIR})

set(ELFUTILS_VERSION 0.176)
set(ELFUTILS_DOWNLOAD_URL "http://sourceware.org/pub/elfutils/${ELFUTILS_VERSION}/elfutils-${ELFUTILS_VERSION}.tar.bz2")
set(ELFUTILS_CHECKSUM "SHA256=eb5747c371b0af0f71e86215a5ebb88728533c3a104a43d4231963f308cd1023")


libelf_platform_config(LIBELF_PATCH_COMMAND
                       LIBELF_CONFIGURE_COMMAND
                       LIBELF_BUILD_COMMAND
                       LIBELF_INSTALL_COMMAND)

ExternalProject_Add(embedded_libelf
  URL "${ELFUTILS_DOWNLOAD_URL}"
  URL_HASH "${ELFUTILS_CHECKSUM}"
  ${LIBELF_PATCH_COMMAND}
  ${LIBELF_CONFIGURE_COMMAND}
  ${LIBELF_BUILD_COMMAND}
  ${LIBELF_INSTALL_COMMAND}
  UPDATE_DISCONNECTED 1
  DOWNLOAD_NO_PROGRESS 1
)

# FIXME only if cross compiling maybe? Or check if library not found?
ExternalProject_Add_StepDependencies(embedded_libelf install embedded_gnulib)

ExternalProject_Get_Property(embedded_libelf INSTALL_DIR)
set(EMBEDDED_LIBELF_INSTALL_DIR ${INSTALL_DIR})
