add_subdirectory(calibration)
add_subdirectory(database)
add_subdirectory(realtime)
add_subdirectory(util)

configure_file(kcor_find_code_version.pro.in kcor_find_code_version.pro)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/kcor_find_code_version.pro DESTINATION src)

file(GLOB PRO_FILES "*.pro")
install(FILES ${PRO_FILES} DESTINATION src)
