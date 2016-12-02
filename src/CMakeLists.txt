add_subdirectory(calibration)
add_subdirectory(database)
add_subdirectory(realtime)
add_subdirectory(util)

file(GLOB PRO_FILES "*.pro")
install(FILES ${PRO_FILES} DESTINATION src)