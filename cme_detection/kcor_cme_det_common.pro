common kcor_cme_detection, $
  nlon, $
  navg, $
  nrad, $
  lon, $
  lat, $
  store, $
  timerange, $

  kcor_dir, $
  kcor_hpr_dir, $
  kcor_hpr_diff_dir, $
  datedir, $
  hpr_out_dir, $
  diff_out_dir, $
  cme_detection_params_filename, $

  cstop, $

  ; widget IDs
  wtopbase, $                        ; top-level base widget ID
  wdate, $
  wstart, $
  wstop, $
  wexit, $
  wmessage, $                        ; text widget ID
  wfile, $
  wangle, $
  wspeed, $

  mapwin, $
  plotwin, $
  ifile, $
  date_orig, $
  maps, $
  date_diff, $
  mdiffs, $
  itheta, $
  detected, $
  leadingedge, $
  param, $
  tairef, $                          ; [TODO]: time of ? in TAI
  angle, $
  speed, $
  cme_occurring, $                   ; whether a CME is occurring (boolean)
  current_cme_start_time, $
  current_cme_tai, $                 ; event time of current CME in TAI
  current_cme_id, $                  ; database ID for current CME
  tracked_pt, $
  speed_history, $
  angle_history, $
  running, $                         ; [TODO]: not needed?
  simple_date, $
  last_heartbeat_jd, $
  last_heartbeat_last_data_time, $
  last_data_time, $
  last_sci_data_time, $
  last_interim_report, $
  run                                ; kcor_run object
