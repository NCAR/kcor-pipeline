get_filename_component(DIRNAME "${CMAKE_CURRENT_SOURCE_DIR}" NAME)
set(DLM_NAME kcor)

add_library("${DLM_NAME}" SHARED "kcor.c")

if (UNIX)
  set_target_properties("${DLM_NAME}"
    PROPERTIES
      SUFFIX ".${IDL_PLATFORM_EXT}.so"
  )
endif ()

set_target_properties("${DLM_NAME}"
  PROPERTIES
    PREFIX ""
)

target_link_libraries("${DLM_NAME}" ${IDL_LIBRARY})

install(TARGETS ${DLM_NAME}
  RUNTIME DESTINATION src/${DIRNAME}
  LIBRARY DESTINATION src/${DIRNAME}
)
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/${DLM_NAME}.dlm" DESTINATION src/${DIRNAME})

file(GLOB PRO_FILES "*.pro")
install(FILES ${PRO_FILES} DESTINATION src/${DIRNAME})
