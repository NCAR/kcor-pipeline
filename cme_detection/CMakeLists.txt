add_subdirectory(ssw)

file(GLOB PRO_FILES "*.pro")
file(GLOB SH_FILES "*.sh")

install(FILES README.md DESTINATION cme_detection)
install(FILES ${PRO_FILES} DESTINATION cme_detection)
install(PROGRAMS ${SH_FILES} DESTINATION cme_detection)
