if(NOT EMBED_LIBELF)
  return()
endif()
include(embed_helpers)

set(GNULIB_DOWNLOAD_URL "http://git.savannah.gnu.org/gitweb/?p=gnulib.git&a=snapshot&h=cd46bf0ca5083162f3ac564ebbdeb6371085df45&sf=tgz")
set(GNULIB_CHECKSUM "SHA256=b355951d916eda73f0e7fb9d828623c09185b6624073492d7de88726c6aa6753")

# SEE
# https://developer.android.com/ndk/guides/other_build_systems

# https://developer.android.com/ndk/guides/other_build_systems#autoconf
# FIXME these vary by target arch
set(CROSS_EXPORTS "export TOOLCHAIN=/opt/android-ndk/toolchains/llvm/prebuilt/linux-x86_64 && \
                   export AR=$TOOLCHAIN/bin/arm-linux-androideabi-ar && \
                   export AS=$TOOLCHAIN/bin/arm-linux-androideabi-as && \
                   export CC=$TOOLCHAIN/bin/armv7a-linux-androideabi28-clang && \
                   export CXX=$TOOLCHAIN/bin/armv7a-linux-androideabi28-clang++ && \
                   export LD=$TOOLCHAIN/bin/arm-linux-androideabi-ld && \
                   export RANLIB=$TOOLCHAIN/bin/arm-linux-androideabi-ranlib && \
                   export STRIP=$TOOLCHAIN/bin/arm-linux-androideabi-strip"
                   )

#--sysroot=/opt/android-ndk/platforms/android-28/arch-arm
string(REPLACE ";" " " cross_flags "${CONFIGURE_CROSS_FLAGS}")
message("cross flags ${cross_flags}")
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
 # https://github.com/michalgr/bpftrace/blob/build_scripts_for_android/argp/headers/argp-wrapper.h # FIXME also need to install this, maybe as a patch to argp.h?
  UPDATE_DISCONNECTED 1
  DOWNLOAD_NO_PROGRESS 1
)

set(ELFUTILS_VERSION 0.176)
set(ELFUTILS_DOWNLOAD_URL "http://sourceware.org/pub/elfutils/${ELFUTILS_VERSION}/elfutils-${ELFUTILS_VERSION}.tar.bz2")
set(ELFUTILS_CHECKSUM "SHA256=eb5747c371b0af0f71e86215a5ebb88728533c3a104a43d4231963f308cd1023")

# FIXME have a check that determines if toolchain is clang, and if so applies patch
# To get it to compile by getting rid of inline function definitions

#set(ELFUTILS_PATCH_COMMAND PATCH_COMMAND)
# TO DO if compiler is clang, make an updated patch based on:
# https://chromium.googlesource.com/chromium/src.git/+/62.0.3178.1/third_party/elfutils/clang.patch

ExternalProject_Add(embedded_libelf
  URL "${ELFUTILS_DOWNLOAD_URL}"
  URL_HASH "${ELFUTILS_CHECKSUM}"
  ${ELFUTILS_PATCH_COMMAND}
  CONFIGURE_COMMAND /bin/bash -xc "<SOURCE_DIR>/elfutils-${ELFUTILS_VERSION}/configure" # extra flags needed, prefix and cross
  BUILD_COMMAND /bin/bash -c "cd lib && make -j${nproc} && \
                              cd libelf && make -j${nproc}"
  INSTALL_COMMAND /bin/bash -c "cd libelf && make install"
  UPDATE_DISCONNECTED 1
  DOWNLOAD_NO_PROGRESS 1
)

# FIXME only if cross compiling maybe? Or check if library not found?
ExternalProject_Add_StepDependencies(embedded_libelf install embedded_gnulib)
