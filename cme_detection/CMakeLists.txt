add_subdirectory(ssw)

configure_file(kcor_realtime_cme.sh.in kcor_realtime_cme.sh @ONLY)

file(GLOB PRO_FILES "*.pro")
file(GLOB SH_FILES "*.sh")

install(FILES README.md DESTINATION cme_detection)
install(FILES ${PRO_FILES} DESTINATION cme_detection)
install(PROGRAMS ${SH_FILES}
          ${CMAKE_CURRENT_BINARY_DIR}/kcor_realtime_cme.sh
        DESTINATION cme_detection)
