configure_file(runkcor_eod.sh.in runkcor_eod.sh @ONLY)
configure_file(runkcor_rt.sh.in runkcor_rt.sh @ONLY)

install(PROGRAMS
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_eod.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_rt.sh
          kcor_simulate_data
          kcor_simulate_realtime
        DESTINATION bin)
