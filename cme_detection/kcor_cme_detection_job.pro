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

  run = kcor_run(date, config_filename=config_filename)

  ; the top of the directory tree containing the KCor data is given by
  ; archive_basedir
  kcor_dir = run.archive_basedir

  ; hpr_dir points to the top of the directory tree used for storing images
  ; converted into helioprojective-radial (HPR) coordinates
  kcor_hpr_dir = run.hpr_dir
  if (~file_test(kcor_hpr_dir, /directory)) then file_mkdir, kcor_hpr_dir

  ; hpr_diff_dir points to the top of the directory tree used for storing
  ; running difference maps in helioprojective-radial (HPR) coordinates
  kcor_hpr_diff_dir = run.hpr_diff_dir
  if (~file_test(kcor_hpr_diff_dir, /directory)) then begin
    file_mkdir, kcor_hpr_diff_dir
  endif

  if (~file_test(run.log_dir, /directory)) then file_mkdir, run.log_dir
  mg_log, logger=logger, name='kcor/cme'
  logger->setProperty, filename=filepath(string(date, $
                                                format='(%"%s.cme.log")'), $
                                         root=run.log_dir)

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

  ; If running in realtime mode, stop when KCOR_CME_DET_CHECK detects a stop
  ; *and* when it is after the cme_stop_time. If running a job on already
  ; existing files, stop after done with all the files.
  while (1B) do begin
    kcor_cme_det_check, stopped=stopped

    if (stopped) then begin
      if (cme_occurring) then begin
        ref_time = tai2utc(tairef, /time, /truncate, /ccsds)
        kcor_cme_det_report, ref_time
        cme_occurring = 0B
        mg_log, 'CME ended at %s', ref_time, name='kcor/cme', /info
      endif

      if (keyword_set(realtime)) then begin
        current_time = string(julday(), format='(C(CHI2.2, CMI2.2, CSI2.2))')
        if (current_time gt run.cme_stop_time) then break
        mg_log, 'waiting %0.1f seconds...', run.cme_wait_time, name='kcor/cme', /info
        wait, run.cme_wait_time
      endif else begin
        break
      endelse
    endif
  endwhile

  obj_destroy, run
end
