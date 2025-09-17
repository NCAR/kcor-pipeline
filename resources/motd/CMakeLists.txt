file(GLOB TXT_FILES "motd-*.txt")

install(FILES ${TXT_FILES}
        DESTINATION resources/motd)
