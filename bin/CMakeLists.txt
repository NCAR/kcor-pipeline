configure_file(kcor_include.sh.in kcor_include.sh @ONLY)

configure_file(runkcor_rt.sh.in runkcor_rt.sh @ONLY)
configure_file(runkcor_rt_range.sh.in runkcor_rt_range.sh @ONLY)

configure_file(runkcor_calibrate.sh.in runkcor_calibrate.sh @ONLY)
configure_file(runkcor_calibrate_list.sh.in runkcor_calibrate_list.sh @ONLY)
configure_file(runkcor_calibrate_range.sh.in runkcor_calibrate_range.sh @ONLY)

configure_file(runkcor_eod.sh.in runkcor_eod.sh @ONLY)
configure_file(runkcor_eod_range.sh.in runkcor_eod_range.sh @ONLY)

configure_file(runkcor_process.sh.in runkcor_process.sh @ONLY)
configure_file(runkcor_process_range.sh.in runkcor_process_range.sh @ONLY)

configure_file(runkcor_archive_l0.sh.in runkcor_archive_l0.sh @ONLY)
configure_file(runkcor_archive_l0_range.sh.in runkcor_archive_l0_range.sh @ONLY)

configure_file(runkcor_archive_l1.sh.in runkcor_archive_l1.sh @ONLY)
configure_file(runkcor_archive_l1_range.sh.in runkcor_archive_l1_range.sh @ONLY)

configure_file(runkcor_clean.sh.in runkcor_clean.sh @ONLY)
configure_file(runkcor_clean_range.sh.in runkcor_clean_range.sh @ONLY)

configure_file(kcor.in kcor @ONLY)
configure_file(kcordb.in kcordb @ONLY)
configure_file(kcorcat.in kcorcat @ONLY)

configure_file(kcor_simulate.in kcor_simulate @ONLY)
configure_file(kcor_simulate_data.in kcor_simulate_data @ONLY)
configure_file(kcor_simulate_processing.in kcor_simulate_processing @ONLY)

configure_file(kcor_verify_dates.sh.in kcor_verify_dates.sh @ONLY)

configure_file(runkcor_env.sh.in runkcor_env.sh @ONLY)

configure_file(runkcor_cme_batch.sh.in runkcor_cme_batch.sh @ONLY)

install(PROGRAMS
          ${CMAKE_CURRENT_BINARY_DIR}/kcor_include.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_rt.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_rt_range.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_calibrate.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_calibrate_range.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_calibrate_list.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_eod.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_eod_range.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_process.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_process_range.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_archive_l0.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_archive_l0_range.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_archive_l1.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_archive_l1_range.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_clean.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_clean_range.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_env.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_cme_batch.sh
	  ${CMAKE_CURRENT_BINARY_DIR}/kcor
	  ${CMAKE_CURRENT_BINARY_DIR}/kcordb
	  ${CMAKE_CURRENT_BINARY_DIR}/kcorcat
	  ${CMAKE_CURRENT_BINARY_DIR}/kcor_verify_dates.sh
	  kcor_verify.sh
	  ${CMAKE_CURRENT_BINARY_DIR}/kcor_simulate
	  ${CMAKE_CURRENT_BINARY_DIR}/kcor_simulate_data
	  ${CMAKE_CURRENT_BINARY_DIR}/kcor_simulate_processing
        DESTINATION bin)
