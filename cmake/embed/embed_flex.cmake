if(NOT EMBED_FLEX) # replace with cross-compiling check?
  return()
endif()

# https://android.googlesource.com/platform/external/flex/ has other versions
# Michal suggested 98018e3f58d79e082216d406866942841d4bdf8a, can try that

set(FLEX_DOWNLOAD_URL "https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz")
set(FLEX_CHECKSUM "SHA256=00a1ee1f389f81e9979f3a640a01c431b3021de0d42278f6508391a2f0b81c9a")

set(FLEX_CONFIGURE_COMMAND CONFIGURE_COMMAND /bin/bash -xc
                                             "autoreconf -i -f && ./configure --prefix=<INSTALL_DIR>")
set(FLEX_BUILD_COMMAND BUILD_COMMAND /bin/bash -c "make -j${nproc}") # doesn't support Ninja
set(FLEX_INSTALL_COMMAND INSTALL_COMMAND /bin/bash -c "make -j${nproc} install") # doesn't support Ninja

#set(FLEX_INSTALL_COMMAND INSTALL_COMMAND /bin/bash -c "mkdir -p <INSTALL_DIR>/lib && mkdir -p <INSTALL_DIR>/include && cp <BINARY_DIR>/gllib/libargp.a <INSTALL_DIR>/lib && cp <SOURCE_DIR>/gllib/argp.h <INSTALL_DIR>/include && cp <SOURCE_DIR>/gllib/argp.h <INSTALL_DIR>/include")

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
