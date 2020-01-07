if(NOT EMBED_LIBELF)
  return()
endif()
include(embed_helpers)

set(GNULIB_DOWNLOAD_URL "http://git.savannah.gnu.org/gitweb/?p=gnulib.git&a=snapshot&h=cd46bf0ca5083162f3ac564ebbdeb6371085df45&sf=tgz")
set(GNULIB_CHECKSUM "SHA256=b355951d916eda73f0e7fb9d828623c09185b6624073492d7de88726c6aa6753")

# SEE
# https://developer.android.com/ndk/guides/other_build_systems

# https://developer.android.com/ndk/guides/other_build_systems#autoconf
# FIXME these vary by target arch, move this to a helper function
set(CROSS_EXPORTS "export TOOLCHAIN=/opt/android-ndk/toolchains/llvm/prebuilt/linux-x86_64 && \
                   export AR=$TOOLCHAIN/bin/arm-linux-androideabi-ar && \
                   export AS=$TOOLCHAIN/bin/arm-linux-androideabi-as && \
                   export CC=$TOOLCHAIN/bin/armv7a-linux-androideabi28-clang && \
                   export CXX=$TOOLCHAIN/bin/armv7a-linux-androideabi28-clang++ && \
                   export LD=$TOOLCHAIN/bin/arm-linux-androideabi-ld && \
                   export RANLIB=$TOOLCHAIN/bin/arm-linux-androideabi-ranlib && \
                   export STRIP=$TOOLCHAIN/bin/arm-linux-androideabi-strip"
                   )

set(ARGP_HEADER_HACK "\
#ifndef ARGP_EI \
#  define ARGP_EI inline \
#endif \
 \
// since ece81a73b64483a68f5157420836d84beb3a1680 argp.h as distributed with \
// gnulib requires _GL_INLINE_HEADER_BEGIN macro to be defined. \
#ifndef _GL_INLINE_HEADER_BEGIN \
#  define _GL_INLINE_HEADER_BEGIN \
#  define _GL_INLINE_HEADER_END \
#endif")

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

# FIXME have a check that determines if toolchain is clang, and if so applies patch
# To get it to compile by getting rid of inline function definitions

# TO DO if compiler is clang, patch configure
# Needs:
# - Patch configure to ignore gnu99 requirement
# - Get rid of -Wtrampoline from makefile.in (sed?)
# - Change fallthrough 5 to just fallthrough
# - Define fallthhrough macro somewhere https://infektor.net/posts/2017-01-19-using-cpp17-attributes-today.html#using-the-fallthrough-attribute
#
# CFLAGS fixes:
# include dir for argp
# argp header hack
# -D definition hack
# LDFLAGS fixes:
# library dir for argp
#

set(LIBINTL_H_HACK " \
#ifndef LIBINTL_H \
#define LIBINTL_H \
 \
// libintl.h is included in a lot of sources in efutils, but provided \
// functionalities are not really necessary. Because of that we follow \
// the AOSP example and provide a fake header turning some functions into \
// nops with macros \
 \
#define gettext(x)      (x) \
#define dgettext(x,y)   (y) \
 \
#endif")

# FIXME can this be done with -D ?
set(FALLTHROUGH_FIX " \
#if __has_cpp_attribute(fallthrough) \
#define FALLTHROUGH [[fallthrough]] \
#elif __has_cpp_attribute(clang::fallthrough) \
#define FALLTHROUGH [[clang::fallthrough]] \
#else \
#define FALLTHROUGH \
#endif")

set(ELFUTILS_CROSS_EXPORTS "${CROSS_EXPORTS} && \
                            export LDFLAGS=-L${EMBEDDED_GNULIB_INSTALL_DIR}/lib && \
                            export CFLAGS=-I${EMBEDDED_GNULIB_INSTALL_DIR}/include")
                            # export CFLAGS=${CFLAGS} -Dprogram_invocation_short_name=\\"no-program_invocation_short_name\\"")

set(ELFUTILS_PATCH_COMMAND PATCH_COMMAND /bin/bash -c
                                        "sed -i -e '5010,5056d' <SOURCE_DIR>/configure &&\
                                         sed -i 's/-Wtrampolines//g' <SOURCE_DIR>/lib/Makefile.in &&\
                                         sed -i 's/-Wimplicit-fallthrough=5/-Wimplicit-fallthrough/g' <SOURCE_DIR>/lib/Makefile.in &&\
                                         sed -i 's/-Wtrampolines//g' <SOURCE_DIR>/libelf/Makefile.in &&\
                                         sed -i 's/-Wimplicit-fallthrough=5/-Wimplicit-fallthrough/g' <SOURCE_DIR>/libelf/Makefile.in")

ExternalProject_Add(embedded_libelf
  URL "${ELFUTILS_DOWNLOAD_URL}"
  URL_HASH "${ELFUTILS_CHECKSUM}"
  ${ELFUTILS_PATCH_COMMAND}
  CONFIGURE_COMMAND /bin/bash -xc "${ELFUTILS_CROSS_EXPORTS} && \
                                  cd <BINARY_DIR> && \
                                  <SOURCE_DIR>/configure --host armv7a-linux-androideabi --prefix <INSTALL_DIR>"
  BUILD_COMMAND /bin/bash -c "cd lib && make -j${nproc} && \
                              cd libelf && make -j${nproc}"
  INSTALL_COMMAND /bin/bash -c "cd libelf && make install"
  UPDATE_DISCONNECTED 1
  DOWNLOAD_NO_PROGRESS 1
)

# FIXME only if cross compiling maybe? Or check if library not found?
ExternalProject_Add_StepDependencies(embedded_libelf install embedded_gnulib)
