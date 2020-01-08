if(NOT EMBED_BCC)
  return()
endif()

set(BCC_VERSION "v0.12.0")
set(BCC_DOWNLOAD_URL "https://github.com/iovisor/bcc/releases/download/${BCC_VERSION}/bcc-src-with-submodule.tar.gz")
set(BCC_CHECKSUM "SHA256=a7acf0e7a9d3ca03a91f22590e695655a5f0ccf8e3dc29e454c2e4c5d476d8aa")

set(BCC_CONFIGURE_FLAGS  -Wno-dev
                         -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
                         -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
                         )

get_target_triple(TARGET_TRIPLE)

# Can find clang if it specifies CMAKE_FIND_ROOT_PATH, but don't know how to pass as a list...
if(${TARGET_TRIPLE} MATCHES android)
  list(APPEND BCC_CONFIGURE_FLAGS -DCMAKE_FIND_ROOT_PATH=${EMBEDDED_LIBELF_INSTALL_DIR})
  list(APPEND BCC_CONFIGURE_FLAGS -DLLVM_DIR=${EMBEDDED_LLVM_INSTALL_DIR}/lib/cmake/llvm)
  list(APPEND BCC_CONFIGURE_FLAGS -DCMAKE_TOOLCHAIN_FILE=/opt/android-ndk/build/cmake/android.toolchain.cmake)
  list(APPEND BCC_CONFIGURE_FLAGS -DANDROID_ABI=${ANDROID_ABI})
  list(APPEND BCC_CONFIGURE_FLAGS -DANDROID_NATIVE_API_LEVEL=${ANDROID_NATIVE_API_LEVEL})
  list(APPEND BCC_CONFIGURE_FLAGS -DBISON_EXECUTABLE=bison) # WTF??? Works if I copy, but not if I specify path...
  list(APPEND BCC_CONFIGURE_FLAGS -DFLEX_EXECUTABLE=flex)


  if(EMBED_FLEX)
  # FIXME append flex binary path
  # It will need to set a variable for this based on the project dir
  # -DFLEX_EXECUTABLE=$(abspath $(HOST_OUT_DIR)/bin/flex) \
  endif()

  # FIXME is python actually required?
endif()

message("BCC CONFIG ${BCC_CONFIGURE_FLAGS}")
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

