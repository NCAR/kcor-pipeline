; docformat = 'rst'

;+
; Main end-of-day routine.
;
; :Params:
;   date : in, required, type=date
;     date in the form 'YYYYMMDD' to process
;
; :Keywords:
;   config_filename : in, required, type=string
;     filename of configuration file
;   reprocess : in, optional, type=boolean
;     set to indicate a reprocessing; level 0 files are not distributed in a
;     reprocessing
;-
pro kcor_eod, date, config_filename=config_filename, reprocess=reprocess
  compile_opt strictarr

  eod_clock = tic('eod')

  ; catch and log any crashes
  catch, error
  if (error ne 0L) then begin
    catch, /cancel
    mg_log, /last_error, name='kcor/eod', /critical
    kcor_crash_notification, /eod, run=run
    goto, done
  endif

  valid_date = kcor_valid_date(date, msg=msg)
  if (~valid_date) then message, msg

  run = kcor_run(date, config_filename=config_filename, mode='eod')
  if (~obj_valid(run)) then message, 'problem creating run object'

  _reprocess = n_elements(reprocess) eq 0L $
                 ? run->config('realtime/reprocess') $
                 : keyword_set(reprocess)

  mg_log, '------------------------------', name='kcor/eod', /info

  ; do not print math errors, we check for them explicitly
  !except = 0

  version = kcor_find_code_version(revision=revision, branch=branch)
  full_hostname = mg_hostname()
  hostname_tokens = strsplit(full_hostname, '.', /extract)
  hostname = hostname_tokens[0]
  mg_log, 'kcor-pipeline %s (%s) [%s] on %s', $
          version, revision, branch, hostname, $
          name='kcor/eod', /info

  mg_log, 'IDL %s (%s %s)', !version.release, !version.os, !version.arch, $
          name='kcor/eod', /debug
  mg_log, 'starting end-of-day processing for %s', date, name='kcor/eod', /info

  date_dir = filepath(date, root=run->config('processing/raw_basedir'))
  if (~file_test(date_dir, /directory)) then begin
    mg_log, '%s does not exist, creating...', date_dir, name='kcor/eod', /error
    file_mkdir, date_dir
  endif

  l0_dir = filepath('level0', root=date_dir)
  if (~file_test(l0_dir, /directory)) then begin
    mg_log, '%s does not exist, creating...', l0_dir, name='kcor/eod', /error
    file_mkdir, l0_dir
  endif

  ; determine end-of-day is already done if t1.log has already been copied to
  ; the level0 directory
  t1_log_file = filepath(date + '.kcor.t1.log', root=l0_dir)
  if (file_test(t1_log_file, /regular)) then begin
    mg_log, 't1 log in level0/, validation already done', name='kcor/eod', /info
    goto, done
  endif

  available = kcor_state(/lock, run=run)
  if (~available) then begin
    mg_log, 'raw directory locked, quitting', name='kcor/eod', /info
    goto, done
  endif

  q_dir = filepath('q', subdir=date, root=run->config('processing/raw_basedir'))
  quality_plot = filepath(string(date, format='(%"%s.kcor.quality.png")'), $
                          root=q_dir)
  kcor_quality_plot, q_dir, quality_plot
  kcor_daily_synoptic_map, run=run
  kcor_daily_o1focus_plot, run=run

  ; level 0 files still in root
  l0_fits_files = file_search(filepath('*_kcor.fts.gz', root=date_dir), $
                              count=n_l0_fits_files)
  if (n_l0_fits_files gt 0L) then begin
    mg_log, 'L0 FITS files exist in %s', date_dir, name='kcor/eod', $
            error=keyword_set(_reprocess), info=~keyword_set(_reprocess)
    mg_log, 'L2 processing incomplete', name='kcor/eod', $
            error=keyword_set(_reprocess), info=~keyword_set(_reprocess)
    goto, done
  endif

  ; level 0 files in the level0/ directory
  l0_fits_files = file_search(filepath('*_kcor.fts.gz', root=l0_dir), $
                              count=n_l0_fits_files)

  ; check for logs from other days -- sometimes the machine.log comes in late
  ; and is placed in the next day
  all_logs = file_search(filepath('*.log', root=date_dir), count=n_all_logs)
  if (n_all_logs gt 0L) then begin   ; if no logs then empty string is false pos
    misplaced_log_indices = where(strpos(file_basename(all_logs), date) eq -1, $
                                  n_misplaced_logs)
    for i = 0L, n_misplaced_logs - 1L do begin
      mg_log, 'found misplaced log: %s', $
              file_basename(all_logs[misplaced_log_indices[i]]), $
              name='kcor/eod', /error
    endfor
  endif

  if (run->epoch('require_machine_log')) then begin
    machine_log_file = filepath(date + '.kcor.machine.log', root=date_dir)
    if (file_test(machine_log_file, /regular)) then begin
      mg_log, 'copying machine log to level0/', name='kcor/eod', /info
      file_copy, machine_log_file, l0_dir, /overwrite
    endif else begin
      mg_log, 'machine log not present', name='kcor/eod', /info
      goto, done
    endelse
  endif

  t1_log_file = filepath(date + '.kcor.t1.log', root=date_dir)
  if (file_test(t1_log_file, /regular)) then begin
    mg_log, 'copying t1 log to level0/', name='kcor/eod', /info
    file_copy, t1_log_file, l0_dir, /overwrite
  endif else begin
    mg_log, 't1 log does not exist in %s', date_dir, name='kcor/eod', /info
    goto, done
  endelse

  t2_log_file = filepath(date + '.kcor.t2.log', root=date_dir)
  if (file_test(t2_log_file, /regular)) then begin
    mg_log, 'copying t2 log to level0/', name='kcor/eod', /info
    file_copy, t2_log_file, l0_dir, /overwrite
  endif else begin
    mg_log, 't2 log does not exist in %s', date_dir, name='kcor/eod', /warn
  endelse

  ; copy config file to YYYYMMDD/ directory
  file_copy, config_filename, filepath('kcor.cfg', root=date_dir), /overwrite

  if (run->config('database/update')) then kcor_realtime_lag, run=run

  cd, l0_dir

  quicklook_creation_time = run->config('quicklooks/creation_time')
  produce_quicklooks = (n_elements(quicklook_creation_time) gt 0L) && (strlowcase(quicklook_creation_time) eq 'eod')

  if (produce_quicklooks) then begin
    l0_files = file_search(filepath('*.fts*', root=l0_dir), count=n_l0_files)
    ok_files = kcor_quality(date, l0_fits_files, /eod, $
                            run=run)
  endif

  l1_dir = filepath('level1', root=date_dir)
  l2_dir = filepath('level2', root=date_dir)

  if (~file_test(l0_dir, /directory)) then begin
    mg_log, '%s does not exist', l0_dir, name='kcor/eod', /error
    n_l1_zipped_files = 0L
    n_l2_zipped_files = 0L
  endif else begin
    if (file_test(l1_dir, /directory)) then begin
      cd, l1_dir
      l1_zipped_fits_glob = '*_l1.fts.gz'
      l1_zipped_files = file_search(l1_zipped_fits_glob, count=n_l1_zipped_files)
      cd, l0_dir
    endif else begin
      n_l1_zipped_files = 0L
      n_l2_zipped_files = 0L
    endelse

    if (file_test(l2_dir, /directory)) then begin
      cd, l2_dir
      l2_zipped_fits_glob = '*_l2.fts.gz'
      l2_zipped_files = file_search(l2_zipped_fits_glob, count=n_l2_zipped_files)
      cd, l0_dir
    endif else begin
      n_l2_zipped_files = 0L
    endelse
  endelse

  if (run->config('eod/create_daily_movies') && n_l2_zipped_files gt 0L) then begin
    kcor_create_differences, date, l2_zipped_files, run=run
    kcor_zip_files, filepath('*minus*.fts', root=l2_dir), run=run

    kcor_create_averages, date, l2_zipped_files, run=run
    kcor_redo_nrgf, date, run=run
  endif

  oka_filename = filepath('oka.ls', subdir=[date, 'q'], $
                          root=run->config('processing/raw_basedir'))
  n_oka_files = file_test(oka_filename) ? file_lines(oka_filename) : 0L
  if (file_test(oka_filename, /regular) && n_oka_files gt 1L) then begin
    mg_log, 'producing nomask files...', name='kcor/eod', /info

    oka_files = strarr(n_oka_files)
    openr, lun, oka_filename, /get_lun
    readf, lun, oka_files
    free_lun, lun

    oka_files = filepath(oka_files, $
                         subdir=[date, 'level0'], $
                         root=run->config('processing/raw_basedir'))

    ; skipping first good image of the day, starting with index=1
    kcor_process_files, oka_files[1:*:60], /nomask, /eod, run=run, $
                        l1_filenames=l1_filenames, $
                        log_name='kcor/eod', error=error

    ; need to remove new .fts version of L1 files, .fts.gz version from the
    ; realtime should still be there
    mg_log, 'removing nomask L1 files...', name='kcor/eod', /info
    file_delete, filepath(l1_filenames, root=l1_dir), /quiet

    mg_log, 'zipping nomask L2 FITS files...', $
            name='kcor/eod', /info
    unzipped_glob = filepath('*_kcor_l2_nomask.fts', root=l2_dir)
    kcor_zip_files, unzipped_glob, run=run
  endif else begin
    mg_log, 'no OK L0 files to produce nomask files for', name='kcor/eod', /info
  endelse

  nrgf_glob = filepath('*_kcor_l2_nrgf.fts.gz', $
                       subdir=[date, 'level2'], $
                       root=run->config('processing/raw_basedir'))
  nrgf_files = file_search(nrgf_glob, count=n_nrgf_files)
  if (n_nrgf_files gt 0L) then begin
    if (run->config('eod/produce_plots')) then begin
      kcor_plotraw, date, list=nrgf_files, run=run, $
                    line_means=line_means, line_medians=line_medians, $
                    azi_means=azi_means, azi_medians=azi_medians
    endif
  endif

  nrgf_avg_glob = filepath('*_kcor_l2_nrgf_avg.fts.gz', $
                           subdir=[date, 'level2'], $
                           root=run->config('processing/raw_basedir'))
  nrgf_avg_files = file_search(nrgf_avg_glob, count=n_nrgf_avg_files)
  if (n_nrgf_avg_files gt 0L) then begin
    if (run->config('eod/create_daily_movies')) then begin
      nrgf_avg_timestamps = strmid(file_basename(nrgf_avg_files), 0, 15)
      kcor_create_animations, date, timestamps=nrgf_avg_timestamps, run=run
      kcor_nrgf_diff_movie, run=run
    endif
  endif

  ok_list = filepath('okfgif.ls', $
                     subdir=[date, 'level2'], $
                     root=run->config('processing/raw_basedir'))
  n_ok_files = file_test(ok_list) ? file_lines(ok_list) : 0L

  failed_list = filepath('failed.ls', $
                         subdir=[date, 'level2'], $
                         root=run->config('processing/raw_basedir'))
  n_failed_files = file_test(failed_list) ? file_lines(failed_list) : 0L

  n_missing = 0L
  n_wrongsize = 0L

  if (run->config('eod/validate_t1')) then begin
    mg_log, 'validating t1.log', name='kcor/eod', /info
    n_lines = file_lines(t1_log_file)
    if (n_lines gt 0L) then begin
      lines = strarr(n_lines)
      openr, lun, t1_log_file, /get_lun
      readf, lun, lines
      free_lun, lun
    endif

    for i = 0L, n_lines - 1L do begin
      tokens = strsplit(lines[i], /extract, count=n_tokens)
      if (n_tokens ne 2) then begin
        mg_log, 'malformed t1.log file on line %d', i + 1, name='kcor/eod', /error
        success = 0B
        goto, done_validating
      endif

      t1_file = tokens[0] + '.gz'
      t1_size = long(tokens[1])

      if (file_test(t1_file, /regular)) then begin
        if (t1_size ne kcor_zipsize(t1_file, run=run)) then begin
          n_wrongsize += 1
          mg_log, '%s file size: %d != %d', $
                  t1_file, t1_size, kcor_zipsize(t1_file, run=run), $
                  name='kcor/eod', /warn
        endif
      endif else begin
        n_missing += 1
        mg_log, '%s in t1, but not in level0/', t1_file, name='kcor/eod', /warn
      endelse
    endfor

    mg_log, 't1.log: # L0 files: %d', n_l0_fits_files, name='kcor/eod', /info
    if (n_missing gt 0L) then begin
      mg_log, 't1.log: # missing files: %d', n_missing, name='kcor/eod', /warn
    endif
    if (n_wrongsize gt 0L) then begin
      mg_log, 't1.log: # wrong size files: %d', n_wrongsize, name='kcor/eod', /warn
    endif
  endif else begin
    mg_log, 'skipping validating t1.log', name='kcor/eod', /info
  endelse

  if (run->epoch('header_changes')) then begin
    success = n_missing eq 0L
  endif else begin
    success = n_missing eq 0L && n_wrongsize eq 0L
  endelse

  cal_status = 4L

  ; default start_state if KCOR_REDUCE_CALIBRATION is not performed
  start_state = lonarr(2)

  done_validating:

  if (success) then begin
    files = file_search(filepath('*_kcor.fts.gz', root=l0_dir), count=n_files)

    ; TODO: should really check process flag from epochs file here to filter
    ;       out L0 files that should not be processed

    if (n_files gt 0L) then begin
      if (run->config('eod/produce_plots')) then begin
        kcor_plotparams, date, list=files, run=run
        kcor_plotcenters, date, list=files, run=run

        kcor_plot_l2, run=run
      endif

      if (run->config('eod/catalog_files')) then begin
        kcor_catalog, date, list=files, run=run
      endif

      if (run->config('eod/send_to_archive')) then begin
        kcor_archive_l0, run=run, reprocess=_reprocess
      endif

      ; produce calibration for tomorrow
      if (run->config('eod/reduce_calibration') $
          && run->epoch('produce_calibration')) then begin
        kcor_reduce_calibration, date, run=run, $
                                 status=cal_status, start_state=start_state, $
                                 cal_filename=cal_filename
        if (cal_status eq 0L) then begin
          kcor_plot_calibration, cal_filename, run=run, gain_norm_stddev=gain_norm_stddev
        endif
      endif else begin
        mg_log, 'skipping reducing calibration', name='kcor/eod', /info
      endelse

      kcor_archive_l1, run=run
      kcor_archive_l2, run=run
    endif else begin
      mg_log, 'no L0 files to plot, catalog, or archive', name='kcor/eod', /warn
    endelse
  endif else begin
    ; t{1,2}.log in level0/ directory indicates eod done
    file_delete, filepath(date + '.kcor.t1.log', root=l0_dir), $
                 filepath(date + '.kcor.t2.log', root=l0_dir), $
                 /allow_nonexistent
  endelse

  if (n_l2_zipped_files gt 0L) then begin
    daily_science_file = l2_zipped_files[n_l2_zipped_files ge 20 ? 20 : 0]
  endif

  ; update databases
  if (run->config('database/update') && success) then begin
    mg_log, 'updating database', name='kcor/eod', /info
    cal_files = kcor_read_calibration_text(date, $
                                           run->config('processing/process_basedir'), $
                                           exposures=exposures, $
                                           run=run, $
                                           all_files=all_cal_files, $
                                           n_all_files=n_all_cal_files, $
                                           quality=cal_quality)

    obsday_index = mlso_obsday_insert(date, $
                                      run=run, $
                                      database=db, $
                                      status=db_status, $
                                      log_name='kcor/eod')

    if (db_status eq 0L) then begin
      if (n_all_cal_files gt 0L) then begin
        kcor_cal_insert, date, all_cal_files, cal_quality, $
                         run=run, database=db, obsday_index=obsday_index
      endif else begin
        mg_log, 'no cal files for kcor_cal table', name='kcor/eod', /info
      endelse

      if (n_nrgf_files gt 0L) then begin
        kcor_eng_update, date, nrgf_files, $
                         line_means=line_means, line_medians=line_medians, $
                         azi_means=azi_means, azi_medians=azi_medians, $
                         run=run, database=db, obsday_index=obsday_index
      endif else begin
        mg_log, 'no NRGF files to add mean/median values for', name='kcor/eod', /warn
      endelse

      kcor_rolling_o1focus_plot, database=db, run=run

      if (n_l2_zipped_files gt 0L) then begin
        kcor_sci_insert, date, daily_science_file, $
                         run=run, $
                         database=db, $
                         obsday_index=obsday_index
        kcor_rolling_synoptic_map, database=db, run=run
      endif else begin
        mg_log, 'no L2 files for daily science', name='kcor/eod', /warn
      endelse
    endif else begin
      mg_log, 'error connecting to database', name='kcor/eod', /warn
    endelse
  endif else begin
    mg_log, 'skipping updating database', name='kcor/eod', /info
  endelse

  if (n_l2_zipped_files gt 0L) then begin
    kcor_plotsci, date, daily_science_file, run=run
  endif

  ; create median/mean row/col images
  kcor_rowcol_image, run=run

  ; check for bad lines
  kcor_detect_badlines, run=run

  ; remove zero length files in 'q' sub-directory
  cd, filepath('q', root=date_dir)

  list_files = ['brt', 'cal', 'cld', 'dev', 'dim', 'nsy', 'oka', 'sat'] + '.ls'
  list_files = [list_files, 'list_okf']
  for f = 0L, n_elements(list_files) - 1L do begin
    if (mg_filesize(list_files[f]) eq 0L) then begin
      file_delete, list_files[f], /allow_nonexistent
    endif
  endfor

  cd, filepath('', root=date_dir)
  file_delete, 'list_okf', /allow_nonexistent

  kcor_save_results, date, run=run

  kcor_report_results, date, run=run

  l1_spec = run->config('validation/l1_specification')
  n_invalid_l1_files = 0L
  if (n_elements(l1_spec) eq 0L || ~file_test(l1_spec, /regular)) then begin
    mg_log, 'no spec to validate L1 files against', name='kcor/eod', /info
  endif else begin
    if (n_l1_zipped_files eq 0L) then begin
      mg_log, 'no L1 files to validate', name='kcor/eod', /info
    endif else begin
      mg_log, 'validating %d L1 files', n_l1_zipped_files, name='kcor/eod', /info
      kcor_validate, filepath(l1_zipped_files, root=l1_dir), $
                     l1_spec, 'L1', $
                     n_invalid_files=n_invalid_l1_files, $
                     logger_name='kcor/eod', run=run
    endelse
  endelse

  l2_spec = run->config('validation/l2_specification')
  n_invalid_l2_files = 0L
  if (n_elements(l2_spec) eq 0L || ~file_test(l2_spec, /regular)) then begin
    mg_log, 'no spec to validate L2 files against', name='kcor/eod', /info
  endif else begin
    if (n_l2_zipped_files eq 0L) then begin
      mg_log, 'no L2 files to validate', name='kcor/eod', /info
    endif else begin
      mg_log, 'validating %d L2 files', n_l2_zipped_files, name='kcor/eod', /info
      kcor_validate, filepath(l2_zipped_files, root=l2_dir), $
                     l2_spec, 'L2', $
                     n_invalid_files=n_invalid_l2_files, $
                     logger_name='kcor/eod', run=run
    endelse
  endelse

  if (run->config('notifications/send') $
        && n_elements(run->config('notifications/email')) gt 0L) then begin
    case cal_status of
      0: cal_status_text = 'successful calibration reduction'
      1: cal_status_text = 'incomplete data for calibration reduction'
      2: cal_status_text = 'error during calibration reduction'
      3: cal_status_text = string(start_state, format='(%"bad polarization sequence (recommended start_state: [%d, %d])")')
      4: cal_status_text = 'calibration reduction skipped'
      else: cal_status_text = 'unknown error during calibration reduction'
    endcase
    msg = [string(date, $
                  format='(%"KCor end-of-day processing for %s")'), $
           '', $
           string(version, revision, branch, $
                  format='(%"kcor-pipeline %s (%s) [%s]")'), $
           '', $
           '# Basic statistics', $
           '', $
           string(n_l0_fits_files, $
                  format='(%"number of raw files: %d")'), $
           string(n_ok_files, $
                  format='(%"number of OK FITS files: %d")'), $
           string(n_failed_files, $
                  format='(%"number of files failing L1/L2 processing: %d")'), $
           string(n_nrgf_files, $
                  format='(%"number of NRGFs: %d")'), $
           cal_status_text $
             + (cal_status eq 0L ? string(gain_norm_stddev, $
                                          format='(%" [std dev / median cam 0: %0.4f, cam 1: %0.4f]")') : '')]

    if (n_missing gt 0L) then begin
      msg = [msg, $
             string(n_missing, $
                    format='(%"number of missing files: %d")')]
    endif
    if (n_wrongsize gt 0L) then begin
      msg = [msg, $
             string(n_wrongsize, $
                    format='(%"number of wrong sized files: %d")')]
    endif

    if (n_invalid_l2_files gt 0L) then begin
      msg = [msg, $
             string(n_invalid_l2_files, $
                    format='(%"number of invalid L2 files: %d")')]
    endif

    spawn, 'echo $(whoami)@$(hostname)', who, error_result, exit_status=status
    if (status eq 0L) then begin
      who = who[0]
    endif else begin
      who = 'unknown'
    endelse

    log_dir = filepath(strmid(run.date, 0, 4), root=run->config('logging/basedir'))
    if (~file_test(log_dir, /directory)) then file_mkdir, log_dir

    realtime_logfile = filepath(run.date + '.realtime.log', root=log_dir)
    eod_logfile = filepath(run.date + '.eod.log', root=log_dir)
    cme_logfile = filepath(run.date + 'cme.log', root=log_dir)

    rt_errors = kcor_filter_log(realtime_logfile, /error, n_messages=n_rt_errors)
    eod_errors = kcor_filter_log(eod_logfile, /error, n_messages=n_eod_errors)
    if (file_test(cme_logfile, /regular)) then begin
      cme_errors = kcor_filter_log(cme_logfile, /error, n_messages=n_cme_errors)
    endif

    if (n_rt_errors gt 0L) then begin
      msg = [msg, '', $
             string(n_rt_errors, format='(%"# Realtime log errors (%d errors)")'), $
             '', rt_errors]
    endif else begin
      msg = [msg, '', '# No realtime log errors']
    endelse

    if (n_eod_errors gt 0L) then begin
      msg = [msg, '', $
             string(n_eod_errors, format='(%"# End-of-day log errors (%d errors)")'), $
             '', eod_errors]
    endif else begin
      msg = [msg, '', '# No end-of-day log errors']
    endelse

    if (file_test(cme_logfile, /regular)) then begin
      if (n_eod_errors gt 0L) then begin
        msg = [msg, '', $
               string(n_eod_errors, format='(%"# CME log errors (%d errors)")'), $
               '', eod_errors]
      endif else begin
        msg = [msg, '', '# No CME log errors']
      endelse
    endif else msg = [msg, '', '# No CME log']

    ; bad line warning messages in EOD log
    eod_warnings = kcor_filter_log(eod_logfile, /warn, n_messages=n_eod_warnings)
    if (n_eod_warnings gt 0L) then begin
      badline_mask = stregex(eod_warnings, 'KCOR_DETECT_BADLINES', /boolean)
      badline_indices = where(badline_mask, n_badlines)
      if (n_badlines gt 0L) then begin
        msg = [msg, '', '# Bad lines', '', eod_warnings[badline_indices]]
      endif
    endif

    msg = [msg, '', '', '# Config file', '', run.config_content, '', '', $
           string(mg_src_root(/filename), who, $
                  format='(%"Sent from %s (%s)")')]

    n_errors_msg = n_rt_errors eq 0L && n_eod_errors eq 0L $
                     ? '' $
                     : string(n_rt_errors, n_eod_errors, $
                              format='(%" - %d rt, %d eod errors")')

    attachments = [quality_plot]

    ; add realtime lag image, if it was produced, i.e., if this run was done
    ; in realtime
    lag_basename = string(run.date, format='(%"%s.kcor.rt-lag.gif")')
    lag_filename = filepath(lag_basename, $
                            subdir=[run.date, 'p'], $
                            root=run->config('processing/raw_basedir'))
    if (file_test(lag_filename, /regular)) then begin
      attachments = [attachments, lag_filename]
    endif

    mg_log, 'sending notification to %s', run->config('notifications/email'), $
            name='kcor/eod', /info
    kcor_send_mail, run->config('notifications/email'), $
                    string(run.date, $
                           success ? 'success' : 'problems', $
                           n_errors_msg, $
                           format='(%"KCor end-of-day processing for %s (%s%s)")'), $
                    msg, $
                    attachments=attachments, $
                    logger_name='kcor/eod'
  endif else begin
    mg_log, 'not sending notification email', name='kcor/eod', /warn
  endelse

  done:

  if (obj_valid(db)) then obj_destroy, db

  mg_log, /check_math, name='kcor/eod', /debug

  if (n_elements(available) gt 0L && available) then begin
    !null = kcor_state(/unlock, run=run)
  endif

  eod_time = toc(eod_clock)
  mg_log, 'done, eod processing time: %s', $
          kcor_sec2str(eod_time), $
          name='kcor/eod', /info

  obj_destroy, run
end


; main-level example program

date = '20180208'
config_filename = filepath('kcor.mgalloy.mahi.latest.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
kcor_eod, date, config_filename=config_filename

end
