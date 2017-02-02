configure_file(runkcor_eod.sh.in runkcor_eod.sh @ONLY)
install(PROGRAMS
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_eod.sh
          kcor_rt_simulator
          kcor_run_rt
        DESTINATION bin)
