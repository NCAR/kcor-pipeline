add_subdirectory(mysql)

file(GLOB PRO_FILES "*.pro")
install(FILES ${PRO_FILES} DESTINATION lib)
install(FILES htmlcolors.dat DESTINATION lib)
