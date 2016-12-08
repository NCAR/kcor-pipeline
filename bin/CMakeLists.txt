#file(GLOB SCRIPT_FILES "*")
set(SCRIPT_FILES runkcor_eod.sh)
install(PROGRAMS ${SCRIPT_FILES} DESTINATION bin)
