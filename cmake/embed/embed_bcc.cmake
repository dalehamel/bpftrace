if(NOT EMBED_BCC)
  return()
endif()

set(BCC_VERSION "v0.12.0")
set(BCC_DOWNLOAD_URL "https://github.com/iovisor/bcc/archive/${BCC_VERSION}.tar.gz")
set(BCC_CHECKSUM "SHA256=00a1ee1f389f81e9979f3a640a01c431b3021de0d42278f6508391a2f0b81c9a")

set(BCC_CONFIGURE_FLAGS  -Wno-dev
                         -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
                         -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
                         )

if(${TARGET_TRIPLE} MATCHES android)
  list(APPEND BCC_CONFIGURE_FLAGS -DCMAKE_TOOLCHAIN_FILE=/opt/android-ndk/build/cmake/android.toolchain.cmake)
  list(APPEND BCC_CONFIGURE_FLAGS -DANDROID_ABI=${ANDROID_ABI})
  list(APPEND BCC_CONFIGURE_FLAGS -DANDROID_NATIVE_API_LEVEL=${ANDROID_NATIVE_API_LEVEL})

  if(EMBED_FLEX)
  # FIXME append flex binary path
  # It will need to set a variable for this based on the project dir
  # -DFLEX_EXECUTABLE=$(abspath $(HOST_OUT_DIR)/bin/flex) \
  endif()

  # FIXME is python actually required?
endif()

ExternalProject_Add(embedded_bcc
  URL "${BCC_DOWNLOAD_URL}"
  URL_HASH "${BCC_CHECKSUM}"
  CMAKE_ARGS "${BCC_CONFIGURE_FLAGS}"
  ${BCC_CONFIGURE_COMMAND}
  ${BCC_BUILD_COMMAND}
  ${BCC_INSTALL_COMMAND}
  UPDATE_DISCONNECTED 1
  DOWNLOAD_NO_PROGRESS 1
)

if(EMBED_LIBELF)
  ExternalProject_Add_StepDependencies(embedded_bcc install embedded_libelf)
endif()

if(EMBED_FLEX)
  ExternalProject_Add_StepDependencies(embedded_bcc install embedded_flex)
endif()

