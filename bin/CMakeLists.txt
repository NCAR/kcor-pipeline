configure_file(kcor_include.sh.in kcor_include.sh @ONLY)

configure_file(runkcor_rt.sh.in runkcor_rt.sh @ONLY)
configure_file(runkcor_rt_range.sh.in runkcor_rt_range.sh @ONLY)

configure_file(runkcor_calibrate.sh.in runkcor_calibrate.sh @ONLY)
configure_file(runkcor_calibrate_list.sh.in runkcor_calibrate_list.sh @ONLY)
configure_file(runkcor_calibrate_range.sh.in runkcor_calibrate_range.sh @ONLY)

configure_file(runkcor_eod.sh.in runkcor_eod.sh @ONLY)
configure_file(runkcor_eod_range.sh.in runkcor_eod_range.sh @ONLY)

configure_file(runkcor_eodcheck.sh.in runkcor_eodcheck.sh @ONLY)

configure_file(runkcor_process.sh.in runkcor_process.sh @ONLY)
configure_file(runkcor_process_range.sh.in runkcor_process_range.sh @ONLY)

configure_file(runkcor_script.sh.in runkcor_script.sh @ONLY)
configure_file(runkcor_script_range.sh.in runkcor_script_range.sh @ONLY)

configure_file(runkcor_cmedetection.sh.in runkcor_cmedetection.sh @ONLY)
configure_file(runkcor_cmedetection_range.sh.in runkcor_cmedetection_range.sh @ONLY)

configure_file(runkcor_savecme.sh.in runkcor_savecme.sh @ONLY)
configure_file(runkcor_savecme_range.sh.in runkcor_savecme_range.sh @ONLY)

configure_file(runkcor_archive_l0.sh.in runkcor_archive_l0.sh @ONLY)
configure_file(runkcor_archive_l0_range.sh.in runkcor_archive_l0_range.sh @ONLY)

configure_file(runkcor_archive_l1.sh.in runkcor_archive_l1.sh @ONLY)
configure_file(runkcor_archive_l1_range.sh.in runkcor_archive_l1_range.sh @ONLY)

configure_file(runkcor_archive_l2.sh.in runkcor_archive_l2.sh @ONLY)
configure_file(runkcor_archive_l2_range.sh.in runkcor_archive_l2_range.sh @ONLY)

configure_file(runkcor_purge.sh.in runkcor_purge.sh @ONLY)
configure_file(runkcor_purge_range.sh.in runkcor_purge_range.sh @ONLY)

configure_file(runkcor_remove.sh.in runkcor_remove.sh @ONLY)
configure_file(runkcor_remove_range.sh.in runkcor_remove_range.sh @ONLY)

configure_file(kcor.in kcor @ONLY)
configure_file(kcordb.in kcordb @ONLY)
configure_file(kcorcat.in kcorcat @ONLY)
configure_file(donki.in donki @ONLY)

configure_file(kcor_simulate.in kcor_simulate @ONLY)
configure_file(kcor_simulate_data.in kcor_simulate_data @ONLY)
configure_file(kcor_simulate_processing.in kcor_simulate_processing @ONLY)

configure_file(kcor_verify_dates.sh.in kcor_verify_dates.sh @ONLY)
configure_file(kcor_verify.sh.in kcor_verify.sh @ONLY)

configure_file(runkcor_nrgf.sh.in runkcor_nrgf.sh @ONLY)

configure_file(runkcor_env.sh.in runkcor_env.sh @ONLY)

install(PROGRAMS
          ${CMAKE_CURRENT_BINARY_DIR}/kcor_include.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_rt.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_rt_range.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_calibrate.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_calibrate_range.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_calibrate_list.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_eod.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_eod_range.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_eodcheck.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_process.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_process_range.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_script.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_script_range.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_cmedetection.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_cmedetection_range.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_archive_l0.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_archive_l0_range.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_savecme.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_savecme_range.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_archive_l1.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_archive_l1_range.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_archive_l2.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_archive_l2_range.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_purge.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_purge_range.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_remove.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_remove_range.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_nrgf.sh
          ${CMAKE_CURRENT_BINARY_DIR}/runkcor_env.sh
          ${CMAKE_CURRENT_BINARY_DIR}/kcor
          ${CMAKE_CURRENT_BINARY_DIR}/kcordb
          ${CMAKE_CURRENT_BINARY_DIR}/kcorcat
          ${CMAKE_CURRENT_BINARY_DIR}/donki
          ${CMAKE_CURRENT_BINARY_DIR}/kcor_verify_dates.sh
          ${CMAKE_CURRENT_BINARY_DIR}/kcor_verify.sh
          kcor_makelog.sh
          ${CMAKE_CURRENT_BINARY_DIR}/kcor_simulate
          ${CMAKE_CURRENT_BINARY_DIR}/kcor_simulate_data
          ${CMAKE_CURRENT_BINARY_DIR}/kcor_simulate_processing
        DESTINATION bin)
