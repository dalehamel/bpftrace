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

bcc_platform_config(BCC_PATCH_COMMAND
                    ${BCC_CONFIGURE_FLAGS}
                    BCC_BUILD_COMMAND
                    BCC_INSTALL_COMMAND)

ExternalProject_Add(embedded_bcc
  URL "${BCC_DOWNLOAD_URL}"
  URL_HASH "${BCC_CHECKSUM}"
  CMAKE_ARGS "${BCC_CONFIGURE_FLAGS}"
  ${BCC_PATCH_COMMAND}
  ${BCC_BUILD_COMMAND}
  ${BCC_INSTALL_COMMAND}
  UPDATE_DISCONNECTED 1
  DOWNLOAD_NO_PROGRESS 1
)

ExternalProject_Get_Property(embedded_bcc INSTALL_DIR)
set(EMBEDDED_BCC_INSTALL_DIR ${INSTALL_DIR})

if(EMBED_LIBELF)
  ExternalProject_Add_StepDependencies(embedded_bcc install embedded_libelf)
endif()

if(EMBED_LLVM)
  ExternalProject_Add_StepDependencies(embedded_bcc install embedded_llvm)
endif()

if(EMBED_CLANG)
  ExternalProject_Add_StepDependencies(embedded_bcc install embedded_clang)
endif()
