if(NOT EMBED_CLANG)
  return()
endif()
include(embed_helpers)

get_host_triple(HOST_TRIPLE)
get_target_triple(TARGET_TRIPLE)

if(NOT "${HOST_TRIPLE}" STREQUAL "${TARGET_TRIPLE}")
  set(CROSS_COMPILING_CLANG ON)
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(EMBEDDED_BUILD_TYPE "RelWithDebInfo")
elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
  set(EMBEDDED_BUILD_TYPE "MinSizeRel")
else()
  set(EMBEDDED_BUILD_TYPE ${CMAKE_BUILD_TYPE})
endif()

if(${LLVM_VERSION} VERSION_GREATER_EQUAL "9")
  set(LLVM_FULL_VERSION "9.0.1")
  set(CLANG_DOWNLOAD_URL "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_FULL_VERSION}/clang-${LLVM_FULL_VERSION}.src.tar.xz")
  set(CLANG_URL_CHECKSUM "SHA256=5778512b2e065c204010f88777d44b95250671103e434f9dc7363ab2e3804253")
elseif(${LLVM_VERSION} VERSION_GREATER_EQUAL "8")
  set(LLVM_FULL_VERSION "8.0.1")
  set(CLANG_DOWNLOAD_URL "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_FULL_VERSION}/cfe-${LLVM_FULL_VERSION}.src.tar.xz")
  set(CLANG_URL_CHECKSUM "SHA256=70effd69f7a8ab249f66b0a68aba8b08af52aa2ab710dfb8a0fba102685b1646")
elseif(${LLVM_VERSION} VERSION_GREATER_EQUAL "7")
  set(LLVM_FULL_VERSION "7.1.0")
  set(CLANG_DOWNLOAD_URL "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_FULL_VERSION}/cfe-${LLVM_FULL_VERSION}.src.tar.xz")
  set(CLANG_URL_CHECKSUM "SHA256=e97dc472aae52197a4d5e0185eb8f9e04d7575d2dc2b12194ddc768e0f8a846d")
else()
  message(FATAL_ERROR "No supported LLVM version has been specified with LLVM_VERSION (LLVM_VERSION=${LLVM_VERSION}), aborting")
endif()

set(CLANG_PATCH_COMMAND "/bin/true")
set(LIBCLANG_INSTALL_COMMAND "mkdir -p <INSTALL_DIR>/lib/ && \
                              cp <BINARY_DIR>/lib/libclang.a <INSTALL_DIR>/lib/libclang.a")

set(CLANG_INSTALL_COMMAND "make install && ${LIBCLANG_INSTALL_COMMAND}") # FIXME work with ninja / detect generator?

if(NOT EMBED_LLVM)
  # If not linking and building against embedded LLVM, patches may need to
  # be applied to link with the distribution LLVM. This is handled by a
  # helper function
  prepare_clang_patches(CLANG_PATCH_COMMAND)
endif()

if(EMBED_LIBCLANG_ONLY)
  ProcessorCount(nproc)
  set(CLANG_LIBRARY_TARGETS clang)
  # Include system clang here to deal with the rest of the targets

  set(CLANG_BUILD_COMMAND "make libclang_static -j${nproc}")
  set(CLANG_INSTALL_COMMAND "${LIBCLANG_INSTALL_COMMAND}")
  find_package(Clang REQUIRED)
  include_directories(SYSTEM ${CLANG_INCLUDE_DIRS})
else()
  set(CLANG_LIBRARY_TARGETS
      clang
      clangAST
      clangAnalysis
      clangBasic
      clangDriver
      clangEdit
      clangFormat
      clangFrontend
      clangIndex
      clangLex
      clangParse
      clangRewrite
      clangSema
      clangSerialization
      clangToolingCore
      clangToolingInclusions
      )
endif()

# These configure flags are a blending of the Alpine, debian, and gentoo
# packages configure flags, customized to reduce build targets as much as
# possible
set(CLANG_CONFIGURE_FLAGS  -Wno-dev
                           -DLLVM_TARGETS_TO_BUILD=BPF
                           -DCMAKE_BUILD_TYPE=${EMBEDDED_BUILD_TYPE}
                           -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
                           -DCMAKE_VERBOSE_MAKEFILE=OFF
                           -DCLANG_VENDOR=bpftrace
                           -DCLANG_BUILD_EXAMPLES=OFF
                           -DCLANG_INCLUDE_DOCS=OFF
                           -DCLANG_INCLUDE_TESTS=OFF
                           -DCLANG_PLUGIN_SUPPORT=ON
                           -DLIBCLANG_BUILD_STATIC=ON
                           -DLLVM_ENABLE_EH=ON
                           -DLLVM_ENABLE_RTTI=ON
                           -DCLANG_BUILD_TOOLS=OFF
                           )

# If LLVM is being embedded, inform Clang to use its Cmake file instead of system
if(EMBED_LLVM)
  list(APPEND CLANG_CONFIGURE_FLAGS  -DLLVM_DIR=${EMBEDDED_LLVM_INSTALL_DIR}/lib/cmake/llvm)
endif()

if(${TARGET_TRIPLE} MATCHES android)
  ProcessorCount(nproc)

  # FIXME incompatible with libclang_only (can't do when cross compiling right now)

  list(APPEND CLANG_CONFIGURE_FLAGS -DCMAKE_TOOLCHAIN_FILE=/opt/android-ndk/build/cmake/android.toolchain.cmake)
  list(APPEND CLANG_CONFIGURE_FLAGS -DANDROID_ABI=${ANDROID_ABI})
  list(APPEND CLANG_CONFIGURE_FLAGS -DANDROID_NATIVE_API_LEVEL=${ANDROID_NATIVE_API_LEVEL})
  #list(APPEND CLANG_CONFIGURE_FLAGS -DLLVM_CONFIG_PATH=${LLVM_CONFIG_PATH})
  list(APPEND CLANG_CONFIGURE_FLAGS -DLLVM_TABLEGEN=${LLVM_TBLGEN_PATH})
  list(APPEND CLANG_CONFIGURE_FLAGS -DLLVM_TABLEGEN_EXE=${LLVM_TBLGEN_PATH}) # is this also needed?
  list(APPEND CLANG_CONFIGURE_FLAGS -DCMAKE_CROSSCOMPILING=True)
  #list(APPEND LLVM_CONFIGURE_FLAGS -DBUILD_SHARED_LIBS=ON)
  string(REPLACE ";" " " CLANG_MAKE_TARGETS "${CLANG_LIBRARY_TARGETS}" )
  set(CLANG_BUILD_COMMAND "make -j${nproc} ${CLANG_MAKE_TARGETS}") # nproc?
  message("USING BUILD COMMAND ${BUILD_COMMAND}")
  set(INSTALL_COMMAND "mkdir -p <INSTALL_DIR>/lib/ && find <BINARY_DIR>/lib/ | grep '\\.a$' | xargs -I@ cp @ <INSTALL_DIR>/lib/")
endif()

if(${CROSS_COMPILING_CLANG})
  # FIXME is there a way to reuse the existing sources? do we care?
  ExternalProject_Add(embedded_clang_host
    URL "${CLANG_DOWNLOAD_URL}"
    URL_HASH "${CLANG_URL_CHECKSUM}"
    #CONFIGURE_COMMAND /bin/bash -xc "cmake <SOURCE_DIR>"
    BUILD_COMMAND /bin/bash -c "make -j${nproc} clang-tblgen"
    INSTALL_COMMAND /bin/bash -c "mkdir -p <INSTALL_DIR>/bin && cp <BINARY_DIR>/bin/clang-tblgen <INSTALL_DIR>/bin"
    UPDATE_DISCONNECTED 1
    DOWNLOAD_NO_PROGRESS 1
  ) # FIXME set build byproducts for ninja

  ExternalProject_Get_Property(embedded_clang_host INSTALL_DIR)
  set(CLANG_TBLGEN_PATH "${INSTALL_DIR}/bin/clang-tblgen")

  list(APPEND CLANG_CONFIGURE_FLAGS -DCLANG_TABLEGEN=${CLANG_TBLGEN_PATH})
endif()

set(CLANG_TARGET_LIBS "")
foreach(clang_target IN LISTS CLANG_LIBRARY_TARGETS)
  list(APPEND CLANG_TARGET_LIBS "<INSTALL_DIR>/lib/lib${clang_target}.a")
endforeach(clang_target)

# No way to conditionally pass arguments, so branch based on whether a custom
# build command was defined, as this passes make/ninja, and job count.
if("${CLANG_BUILD_COMMAND}" STREQUAL "")
  # Inherit from parent cmake for Make settings
  ExternalProject_Add(embedded_clang
    URL "${CLANG_DOWNLOAD_URL}"
    URL_HASH "${CLANG_URL_CHECKSUM}"
    CMAKE_ARGS "${CLANG_CONFIGURE_FLAGS}"
    PATCH_COMMAND /bin/bash -c "${CLANG_PATCH_COMMAND}"
    INSTALL_COMMAND /bin/bash -c "${CLANG_INSTALL_COMMAND}"
    BUILD_BYPRODUCTS ${CLANG_TARGET_LIBS}
    UPDATE_DISCONNECTED 1
    DOWNLOAD_NO_PROGRESS 1
  )
else()
 ExternalProject_Add(embedded_clang
    URL "${CLANG_DOWNLOAD_URL}"
    URL_HASH "${CLANG_URL_CHECKSUM}"
    CMAKE_ARGS "${CLANG_CONFIGURE_FLAGS}"
    PATCH_COMMAND /bin/bash -c "${CLANG_PATCH_COMMAND}"
    BUILD_COMMAND /bin/bash -c "${CLANG_BUILD_COMMAND}"
    INSTALL_COMMAND /bin/bash -c "${CLANG_INSTALL_COMMAND}"
    BUILD_BYPRODUCTS ${CLANG_TARGET_LIBS}
    UPDATE_DISCONNECTED 1
    DOWNLOAD_NO_PROGRESS 1
  )
endif()

# If LLVM is also being embedded, build it first
if (EMBED_LLVM)
  ExternalProject_Add_StepDependencies(embedded_clang install embedded_llvm)
endif()

if(${CROSS_COMPILING_CLANG})
  ExternalProject_Add_StepDependencies(embedded_clang install embedded_clang_host)
endif()

# Set up library targets and locations
ExternalProject_Get_Property(embedded_clang INSTALL_DIR)
set(EMBEDDED_CLANG_INSTALL_DIR ${INSTALL_DIR})
set(CLANG_EMBEDDED_CMAKE_TARGETS "")

include_directories(SYSTEM ${EMBEDDED_CLANG_INSTALL_DIR}/include)

foreach(clang_target IN LISTS CLANG_LIBRARY_TARGETS)
  if(EMBED_LIBCLANG_ONLY AND ${clang_target} STREQUAL "clang")
    set(clang_target "embedded-libclang")
    list(APPEND CLANG_EMBEDDED_CMAKE_TARGETS ${clang_target})
    add_library(${clang_target} STATIC IMPORTED)
    set_property(TARGET ${clang_target} PROPERTY IMPORTED_LOCATION ${EMBEDDED_CLANG_INSTALL_DIR}/lib/libclang.a)
    add_dependencies(${clang_target} embedded_clang)
  else()
    message("CLANG TARGET ${clang_target}")
    list(APPEND CLANG_EMBEDDED_CMAKE_TARGETS ${clang_target})
    add_library(${clang_target} STATIC IMPORTED)
    set_property(TARGET ${clang_target} PROPERTY IMPORTED_LOCATION ${EMBEDDED_CLANG_INSTALL_DIR}/lib/lib${clang_target}.a)
    add_dependencies(${clang_target} embedded_clang)
  endif()
endforeach(clang_target)
