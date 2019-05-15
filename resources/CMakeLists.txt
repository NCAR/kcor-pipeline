add_subdirectory(html)

file(GLOB LUT_FILES "*.lut")
install(FILES ${LUT_FILES} DESTINATION resources)

file(GLOB SAV_FILES "*.sav")
install(FILES ${SAV_FILES} DESTINATION resources)
