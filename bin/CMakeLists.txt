configure_file(runkcor_eod.sh.in runkcor_eod.sh @ONLY)
configure_file(runkcor_rt.sh.in runkcor_rt.sh @ONLY)
configure_file(runkcor_calibrate.sh.in runkcor_calibrate.sh @ONLY)
configure_file(kcor.in kcor @ONLY)

configure_file(runkcor_process.sh.in runkcor_process.sh @ONLY)
configure_file(runkcor_process_range.sh.in runkcor_process_range.sh @ONLY)
configure_file(runkcor_process_list.sh.in runkcor_process_list.sh @ONLY)

configure_file(runkcor_env.sh.in runkcor_env.sh @ONLY)

configure_file(runkcor_cme_batch.sh.in runkcor_cme_batch.sh @ONLY)

install(PROGRAMS
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_eod.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_rt.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_calibrate.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_process.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_process_range.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_process_list.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_env.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_cme_batch.sh
	  kcor
	  kcor_log
          kcor_simulate
          kcor_simulate_data
          kcor_simulate_processing
        DESTINATION bin)
