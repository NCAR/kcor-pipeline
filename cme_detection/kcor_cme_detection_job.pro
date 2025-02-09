; docformat = 'rst'

;+
; :Keywords:
;   realtime : in, optional, type=boolean
;     set to indicate that the job is being run in realtime, i.e., files for
;     the are not all present already and the code must wait for them to come in
;-
pro kcor_cme_detection_job, date, $
                            timerange=_timerange, $
                            config_filename=config_filename, $
                            realtime=realtime
  compile_opt strictarr
  @kcor_cme_det_common

  ; catch and log any crashes
  catch, error
  if (error ne 0L) then begin
    catch, /cancel
    mg_log, /last_error, name='kcor/cme', /critical
    kcor_crash_notification, /cme, run=run
    goto, done
  endif

  store = 1
  running = 0B
  cme_occurring = 0B

  if (n_elements(_timerange) eq 2) then begin
    timerange = _timerange
  endif else begin
    delvarx, timerange
  endelse

  ; Define the parameters describing the resulting maps.  Note that the product
  ; of NLON*NAVG should be at least as large as the circumference in pixels of
  ; the outer edge of the coronagraph field of view.
  nlon = 120       ; Number of longitude points
  navg = 40        ; Number of points to average in longitude
  nrad = 310       ; Number of radial points.

  ; Determine the date directory from the date. If no date was passed, then use
  ; today's date.
  if (n_elements(date) eq 0) then begin
    date = string(julday(), format='(C(CYI4, CMOI02, CDI02))')
  endif

  valid_date = kcor_valid_date(date, msg=msg)
  if (~valid_date) then message, msg

  run = kcor_run(date, config_filename=config_filename)

  ; the top of the directory tree containing the KCor data is given by
  ; archive_basedir
  kcor_dir = run->config('results/archive_basedir')

  ; hpr_dir points to the top of the directory tree used for storing images
  ; converted into helioprojective-radial (HPR) coordinates
  kcor_hpr_dir = run->config('cme/hpr_dir')
  if (~file_test(kcor_hpr_dir, /directory)) then file_mkdir, kcor_hpr_dir

  ; hpr_diff_dir points to the top of the directory tree used for storing
  ; running difference maps in helioprojective-radial (HPR) coordinates
  kcor_hpr_diff_dir = run->config('cme/hpr_diff_dir')
  if (~file_test(kcor_hpr_diff_dir, /directory)) then begin
    file_mkdir, kcor_hpr_diff_dir
  endif

  log_dir = filepath(strmid(date, 0, 4), root=run->config('logging/basedir'))
  if (~file_test(log_dir, /directory)) then file_mkdir, log_dir

  ; setup cme log
  log_filename = filepath(string(date, format='(%"%s.cme.log")'), $
                          root=log_dir)
  mg_rotate_log, log_filename, max_version=run->config('logging/max_version')
  mg_log, logger=logger, name='kcor/cme'
  logger->setProperty, filename=log_filename, $
                       format='%(time)s %(levelshortname)s: %(routine)s: %(message)s'

  kcor_cme_det_setdate, date
  kcor_cme_det_reset

  ; start up SolarSoft display routines
  defsysv, '!image', exists=sys_image_defined
  if (~sys_image_defined) then imagelib
  defsysv, '!aspect', exists=sys_aspect_defined
  if (~sys_aspect_defined) then devicelib

  cstop = 0

  version = kcor_find_code_version(revision=revision, branch=branch)
  mg_log, 'kcor-pipeline %s (%s) [%s]', version, revision, branch, $
          name='kcor/cme', /info
  mg_log, 'IDL %s (%s %s)', !version.release, !version.os, !version.arch, $
          name='kcor/cme', /info

  mg_log, 'starting CME detection for %s', date, name='kcor/cme', /info
  mg_log, 'archive dir : %s', datedir, name='kcor/cme', /info

  if (~file_exist(datedir)) then begin
    mg_log, 'creating archive dir...', name='kcor/cme', /debug
    file_mkdir, datedir
  endif

  wait_time = run->config('cme/wait_time')

  ; If running in realtime mode, stop when KCOR_CME_DET_CHECK detects a stop
  ; *and* when it is after the cme_stop_time. If running a job on already
  ; existing files, stop after done with all the files.
  last_heartbeat_jd = julday()
  while (1B) do begin
    mg_log, 'main loop', name='kcor/cme', /debug
    kcor_cme_det_check, stopped=stopped, realtime=realtime

    kcor_cme_send_heartbeat
    kcor_cme_handle_retractions
    kcor_cme_handle_human

    if ((n_elements(date_diff) gt 0L) && cme_occurring) then begin
      itime = n_elements(leadingedge) - 1
      tai0 = date_diff[itime].tai_avg

      interim_report_interval = run->config('cme/interim_report_interval')
      current_time = kcor_cme_current_time(run=run)
      current_tai = utc2tai(current_time)
      send_interim_report = (current_tai - last_interim_report) gt interim_report_interval

      mg_log, 'time since last interim report: %0.1f secs (%s %0.1f secs)', $
              current_tai - last_interim_report, $
              send_interim_report ? '>' : '<', $
              interim_report_interval, $
              name='kcor/cme', /debug

      summary_report_interval = run->config('cme/summary_report_interval')
      send_summary_report = (tai0 - current_cme_tai) gt summary_report_interval

      if (send_interim_report && ~send_summary_report) then begin
        last_interim_report = current_tai
        ref_time = tai2utc(tairef, /time, /truncate, /ccsds)
        mg_log, 'sending interim report', name='kcor/cme', /debug
        kcor_cme_det_report, ref_time, /interim
      endif
    endif

    ; it is useful to know the simulation time if this a realtime simulation
    mode = run->config('cme/mode')
    time_dir = run->config('simulator/time_dir')
    current_time = kcor_cme_current_time(run=run)
    if (strlowcase(mode) eq 'simulated_realtime_nowcast' $
        && (n_elements(time_dir) gt 0L) $
        && (n_elements(current_time) gt 0L)) then begin
      mg_log, 'simulation time: %s', current_time, name='kcor/cme', /info
    endif

    if (stopped) then begin
      if (cme_occurring) then begin
        ref_time = tai2utc(tairef, /time, /truncate, /ccsds)
        kcor_cme_det_report, ref_time
        cme_occurring = 0B
        mg_log, 'CME ended at %s', ref_time, name='kcor/cme', /info
      endif

      if (keyword_set(realtime)) then begin
        current_time = kcor_cme_current_time(run=run)
        current_time = strjoin(strmid(current_time, [11, 14, 17], 2))
        current_time = kcor_ut2hst(current_time)
        if (current_time gt run->config('cme/stop_time')) then begin
          mg_log, 'current time %s later than stop time %s', $
                  current_time, run->config('cme/stop_time'), name='kcor/cme', /info
          break
        endif
        mg_log, 'waiting %0.1f seconds...', wait_time, name='kcor/cme', /info
        wait, wait_time
      endif else begin
        break
      endelse
    endif
  endwhile

  done:
  mg_log, 'quitting...', name='kcor/cme', /info
  if (obj_valid(run)) then obj_destroy, run
end
