configure_file(runkcor_eod.sh.in runkcor_eod.sh @ONLY)
configure_file(runkcor_rt.sh.in runkcor_rt.sh @ONLY)
configure_file(runkcor_calibrate.sh.in runkcor_calibrate.sh @ONLY)

configure_file(runkcor_process.sh.in runkcor_process.sh @ONLY)
configure_file(runkcor_process_range.sh.in runkcor_process_range.sh @ONLY)
configure_file(runkcor_process_list.sh.in runkcor_process_list.sh @ONLY)

configure_file(runkcor_reprocess.sh.in runkcor_reprocess.sh @ONLY)
configure_file(runkcor_reprocess_range.sh.in runkcor_reprocess_range.sh @ONLY)
configure_file(runkcor_reprocess_list.sh.in runkcor_reprocess_list.sh @ONLY)

configure_file(runkcor_env.sh.in runkcor_env.sh @ONLY)

install(PROGRAMS
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_eod.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_rt.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_calibrate.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_process.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_process_range.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_process_list.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_reprocess.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_reprocess_range.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_reprocess_list.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_env.sh
	  kcor
	  kcor_log
          kcor_simulate
          kcor_simulate_data
          kcor_simulate_processing
        DESTINATION bin)
