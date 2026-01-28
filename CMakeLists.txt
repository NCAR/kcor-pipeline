# required version of CMake
cmake_minimum_required(VERSION 3.12)
cmake_policy(SET CMP0017 NEW)
if (POLICY CMP0042)
  cmake_policy(SET CMP0042 NEW)
endif ()

project(kcor-pipeline)
set(VERSION_MAJOR "2")
set(VERSION_MINOR "2")
set(VERSION_PATCH "15")
set(VERSION "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}")

set(CMAKE_MODULE_PATH
  ${CMAKE_SOURCE_DIR}/cmake/Modules
  ${CMAKE_ROOT}/Modules
  ${CMAKE_MODULE_PATH}
)

set(GIT_VERSION "${VERSION}")

find_package(Git)
if (GIT_FOUND)
  execute_process(
    COMMAND ${GIT_EXECUTABLE} log -1 --pretty=format:%h
    OUTPUT_VARIABLE GIT_REVISION
  )

  # append a * to the revision if there are modified files
  execute_process(
    COMMAND ${GIT_EXECUTABLE} diff-index --quiet HEAD --
    RESULT_VARIABLE GIT_CHANGES
  )
  if (${GIT_CHANGES})
    set(GIT_REVISION "${GIT_REVISION}*")
  endif ()

  execute_process(
    COMMAND ${GIT_EXECUTABLE} rev-parse --abbrev-ref HEAD
    OUTPUT_STRIP_TRAILING_WHITESPACE
    OUTPUT_VARIABLE GIT_BRANCH
  )
  execute_process(
    COMMAND ${GIT_EXECUTABLE} log -1 --pretty=format:%ad --date=short
    OUTPUT_STRIP_TRAILING_WHITESPACE
    OUTPUT_VARIABLE GIT_SHORTDATE
  )

  # append a * to version if it is not the exact tagged version
  execute_process(
    COMMAND ${GIT_EXECUTABLE} describe
    OUTPUT_STRIP_TRAILING_WHITESPACE
    OUTPUT_VARIABLE GIT_DESCRIBE
  )
  string(COMPARE NOTEQUAL "${GIT_DESCRIBE}" "v${GIT_VERSION}" GIT_COMMITS)
  if (${GIT_COMMITS})
    set(GIT_VERSION "${GIT_VERSION}-dev")
  endif ()
else ()
  set(GIT_REVISION "")
  set(GIT_BRANCH "")
  set(GIT_SHORTDATE "")
endif ()

message(STATUS "git branch   = ${GIT_BRANCH}")
message(STATUS "git version  = ${GIT_VERSION}")
message(STATUS "git revision = ${GIT_REVISION}")

include(${CMAKE_SOURCE_DIR}/cmake/GetDate.cmake)
LONG_TODAY(kcor_pipeline_BUILD_DATE)
message(STATUS "Build date = ${kcor_pipeline_BUILD_DATE}")

find_package(IDL REQUIRED)
find_package(IDLdoc)
find_package(mgunit)

# always need IDL's include files
include_directories(${IDL_INCLUDE_DIR})

add_subdirectory(bin)
add_subdirectory(cme_detection)
add_subdirectory(config)
add_subdirectory(gen)
add_subdirectory(hv)
add_subdirectory(lib)
add_subdirectory(resources)
add_subdirectory(scripts)
add_subdirectory(src)
add_subdirectory(ssw)


if (WIN32 OR CYGWIN)
  set(SEP_CHAR ";")
else ()
  set(SEP_CHAR ":")
endif ()

if (IDLdoc_FOUND)
  add_custom_target(doc
    COMMAND ${IDL_EXECUTABLE} -IDL_STARTUP "\"\"" -IDL_PATH "${CMAKE_CURRENT_SOURCE_DIR}/lib${SEP_CHAR}${CMAKE_CURRENT_SOURCE_DIR}${SEP_CHAR}+${CMAKE_CURRENT_SOURCE_DIR}/src${SEP_CHAR}+${IDLdoc_DIR}${SEP_CHAR}\"<IDL_DEFAULT>\"" -e kcor_make_docs -args ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT build developer API documentation
  )
endif ()

set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "api-docs")

# setup installer

if (WIN32)
  set(CPACK_GENERATOR ZIP)
else ()
  set(CPACK_GENERATOR TGZ)
endif ()

string(TOLOWER "${CMAKE_SYSTEM_NAME}" KCOR_PIPELINE_SYSTEM_NAME)
set(KCOR_PIPELINE_PACKAGE_VERSION "${VERSION}.${GIT_REVISION}")
set(CPACK_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}-${KCOR_PIPELINE_PACKAGE_VERSION}-${KCOR_PIPELINE_SYSTEM_NAME}")

include(CPack)


configure_file(INSTALLATION.in INSTALLATION @ONLY)
install(FILES
          README.md
          ${CMAKE_CURRENT_BINARY_DIR}/INSTALLATION
        DESTINATION .)

if (IDLdoc_FOUND)
  install(DIRECTORY ${CMAKE_BINARY_DIR}/api-docs DESTINATION . OPTIONAL)
endif ()

if (mgunit_FOUND)
  install(DIRECTORY unit DESTINATION .)
endif ()

add_custom_target(dist
  COMMAND ${CMAKE_MAKE_PROGRAM} package
  COMMENT "custom target to create distribution")

if (IDLdoc_FOUND)
  add_dependencies(dist doc)
endif ()

message(STATUS "Install location = ${CMAKE_INSTALL_PREFIX}")
message(STATUS "Install version = ${VERSION}")

set(DEFAULT_CONFIG_PATH "${CMAKE_INSTALL_PREFIX}/config" CACHE PATH "default path to configuration files")
set(CONFIG_DIR "${DEFAULT_CONFIG_PATH}" CACHE PATH "path to configuration files")
message(STATUS "configuration directory = ${CONFIG_DIR}")
