add_subdirectory(mysql)

configure_file(mg_dist_tools.dlm.in mg_dist_tools.dlm)
configure_file(mg_cmdline_tools.dlm.in mg_cmdline_tools.dlm)
add_library(mg_dist_tools SHARED mg_dist_tools.c)
add_library(mg_cmdline_tools SHARED mg_cmdline_tools.c)

if (UNIX)
  set_target_properties(mg_dist_tools
    PROPERTIES
      SUFFIX ".${IDL_PLATFORM_EXT}.so"
  )
  set_target_properties(mg_cmdline_tools
    PROPERTIES
      SUFFIX ".${IDL_PLATFORM_EXT}.so"
  )
endif ()

set_target_properties(mg_dist_tools
  PROPERTIES
    PREFIX ""
)
set_target_properties(mg_cmdline_tools
  PROPERTIES
    PREFIX ""
)

target_link_libraries(mg_dist_tools ${IDL_LIBRARY})
target_link_libraries(mg_cmdline_tools ${IDL_LIBRARY})

install(TARGETS mg_dist_tools mg_cmdline_tools
  RUNTIME DESTINATION lib
  LIBRARY DESTINATION lib
)
install(FILES
          "${CMAKE_CURRENT_BINARY_DIR}/mg_dist_tools.dlm"
          "${CMAKE_CURRENT_BINARY_DIR}/mg_cmdline_tools.dlm"
        DESTINATION lib)

file(GLOB PRO_FILES "*.pro")
install(FILES ${PRO_FILES} DESTINATION lib)
install(FILES htmlcolors.dat DESTINATION lib)
