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

  run = kcor_run(date, config_filename=config_filename, mode='eod')
  if (~obj_valid(run)) then message, 'problem creating run object'

  ; catch and log any crashes
  catch, error
  if (error ne 0L) then begin
    catch, /cancel
    mg_log, /last_error, name='kcor/eod', /critical
    kcor_crash_notification, /eod, run=run
    goto, done
  endif

  mg_log, '------------------------------', name='kcor/eod', /info

  ; do not print math errors, we check for them explicitly
  !except = 0

  version = kcor_find_code_version(revision=revision, branch=branch)
  mg_log, 'kcor-pipeline %s (%s) [%s]', version, revision, branch, $
          name='kcor/eod', /info
  mg_log, 'IDL %s (%s %s)', !version.release, !version.os, !version.arch, $
          name='kcor/eod', /info
  mg_log, 'starting end-of-day processing for %s', date, name='kcor/eod', /info

  q_dir = filepath('q', subdir=date, root=run.raw_basedir)
  quality_plot = filepath(string(date, format='(%"%s.kcor.quality.png")'), $
                          root=q_dir)
  kcor_quality_plot, q_dir, quality_plot

  date_dir = filepath(date, root=run.raw_basedir)
  if (~file_test(date_dir, /directory)) then begin
    mg_log, '%s does not exist', date_dir, name='kcor/eod', /error
    goto, done
  endif

  l0_dir = filepath('level0', root=date_dir)
  if (~file_test(l0_dir, /directory)) then begin
    mg_log, '%s does not exist', l0_dir, name='kcor/eod', /error
    goto, done
  endif

  ; level 0 files still in root
  l0_fits_files = file_search(filepath('*_kcor.fts.gz', root=date_dir), $
                              count=n_l0_fits_files)
  if (n_l0_fits_files gt 0L) then begin
    mg_log, 'L0 FITS files exist in %s', date_dir, name='kcor/eod', $
            error=keyword_set(reprocess), info=~keyword_set(reprocess)
    mg_log, 'L1.5 processing incomplete', name='kcor/eod', $
            error=keyword_set(reprocess), info=~keyword_set(reprocess)
    goto, done
  endif

  ; level 0 files in the level0/ directory
  l0_fits_files = file_search(filepath('*_kcor.fts.gz', root=l0_dir), $
                              count=n_l0_fits_files)

  ; determine end-of-day is already done if t1.log has already been copied to
  ; the level0 directory
  t1_log_file = filepath(date + '.kcor.t1.log', root=l0_dir)
  if (file_test(t1_log_file, /regular)) then begin
    mg_log, 't1 log in level0/, validation already done', name='kcor/eod', /info
    goto, done
  endif

  if (run->epoch('require_machine_log')) then begin
    machine_log_file = filepath(date + '.kcor.machine.log', root=date_dir)
    if (file_test(machine_log_file, /regular)) then begin
      mg_log, 'copying machine log to level0/', name='kcor/eod', /info
      file_copy, machine_log_file, l0_dir, /overwrite
    endif else begin
      mg_log, 'machine log does not exist in %s', date_dir, name='kcor/eod', /info
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

  ; check for logs from other days -- sometimes the machine.log comes in late
  ; and is placed in the next day
  all_logs = file_search(filepath('*.log', root=date_dir), count=n_all_logs)
  misplaced_log_indices = where(strpos(file_basename(all_logs), date), $
                                 n_misplaced_logs)
  for i = 0L, n_misplaced_logs - 1L do begin
    mg_log, 'found misplaced log: %s', $
            file_basename(all_logs[misplaced_log_indices[i]]), $
            name='kcor/eod', /error
  endfor

  cd, l0_dir

  l1_dir = filepath('level1', root=date_dir)
  if (~file_test(l0_dir, /directory)) then begin
    mg_log, '%s does not exist', l0_dir, name='kcor/eod', /error
    n_l1_zipped_files = 0L
  endif else begin
    cd, l1_dir
    l1_zipped_fits_glob = '*_l1.5.fts.gz'
    l1_zipped_files = file_search(l1_zipped_fits_glob, count=n_l1_zipped_files)
    cd, l0_dir
  endelse

  if (run.create_daily_movies && n_l1_zipped_files gt 0L) then begin
    kcor_create_differences, date, l1_zipped_files, run=run
    kcor_create_averages, date, l1_zipped_files, run=run
    kcor_redo_nrgf, date, run=run
  endif

  oka_filename = filepath('oka.ls', subdir=[date, 'q'], root=run.raw_basedir)
  n_oka_files = file_lines(oka_filename)
  if (file_test(oka_filename, /regular) && n_oka_files gt 0L) then begin
    mg_log, 'producing nomask files...', name='kcor/eod', /info

    oka_files = strarr(n_oka_files)
    openr, lun, oka_filename, /get_lun
    readf, lun, oka_files
    free_lun, lun

    oka_files = filepath(oka_files, $
                         subdir=[date, 'level0'], $
                         root=run.raw_basedir)
    kcor_l1, date, oka_files[0:*:60], /nomask, run=run, $
             log_name='kcor/eod', error=error
  endif else begin
    mg_log, 'no OK L0 files to produce nomask files for', name='kcor/eod', /info
  endelse

  nrgf_glob = filepath('*_kcor_l1.5_nrgf.fts.gz', $
                       subdir=[date, 'level1'], root=run.raw_basedir)
  nrgf_files = file_search(nrgf_glob, count=n_nrgf_files)
  if (n_nrgf_files gt 0L) then begin
    if (run.produce_plots) then begin
      kcor_plotraw, date, list=nrgf_files, run=run, $
                    line_means=line_means, line_medians=line_medians, $
                    azi_means=azi_means, azi_medians=azi_medians
    endif

    if (run.create_daily_movies) then begin
      kcor_create_animations, date, list=nrgf_files, run=run
    endif
  endif

  ok_list = filepath('okfgif.ls', $
                     subdir=[date, 'level1'], $
                     root=run.raw_basedir)
  n_ok_files = file_test(ok_list) ? file_lines(ok_list) : 0L

  n_missing = 0L
  n_wrongsize = 0L

  if (run.validate_t1) then begin
    mg_log, 'validating t1.log', name='kcor/eod', /info
    n_lines = file_lines(t1_log_file)
    lines = strarr(n_lines)
    openr, lun, t1_log_file, /get_lun
    readf, lun, lines
    free_lun, lun

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

  done_validating:

  if (success) then begin
    files = file_search(filepath('*_kcor.fts.gz', root=l0_dir), count=n_files)
    
    ; TODO: should really check process flag from epochs file here to filter
    ;       out L0 files that should not be processed

    if (run.produce_plots) then begin
      kcor_plotparams, date, list=files, run=run
      kcor_plotcenters, date, list=files, run=run
    endif
    if (run.catalog_files) then kcor_catalog, date, list=files, run=run

    if (run.send_to_archive) then kcor_archive_l0, run=run, reprocess=reprocess

    ; produce calibration for tomorrow
    if (run.reduce_calibration && run->epoch('produce_calibration')) then begin
      kcor_reduce_calibration, date, run=run
    endif else begin
      mg_log, 'skipping reducing calibration', name='kcor/eod', /info
    endelse

    kcor_archive_l1, run=run
  endif else begin
    ; t{1,2}.log in level0/ directory indicates eod done
    file_delete, filepath(date + '.kcor.t1.log', root=l0_dir), $
                 filepath(date + '.kcor.t2.log', root=l0_dir), $
                 /allow_nonexistent
  endelse

  if (n_l1_zipped_files gt 0L) then begin
    daily_science_file = l1_zipped_files[n_l1_zipped_files ge 20 ? 20 : 0]
  endif

  ; update databases
  if (run.update_database && success) then begin
    mg_log, 'updating database', name='kcor/eod', /info
    cal_files = kcor_read_calibration_text(date, run.process_basedir, $
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

      if (n_l1_zipped_files gt 0L) then begin
        kcor_sci_insert, date, daily_science_file, $
                         run=run, $
                         database=db, $
                         obsday_index=obsday_index
      endif else begin
        mg_log, 'no L1.5 files for daily science', name='kcor/eod', /warn
      endelse
    endif else begin
      mg_log, 'error connecting to database', name='kcor/eod', /warn
    endelse

    obj_destroy, db
  endif else begin
    mg_log, 'skipping updating database', name='kcor/eod', /info
  endelse

  if (n_l1_zipped_files gt 0L) then begin
    kcor_plotsci, date, daily_science_file, run=run
  endif

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

  if (run.send_notifications && run.notification_email ne '') then begin
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
           string(n_nrgf_files, $
                  format='(%"number of NRGFs: %d")')]

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

    spawn, 'echo $(whoami)@$(hostname)', who, error_result, exit_status=status
    if (status eq 0L) then begin
      who = who[0]
    endif else begin
      who = 'unknown'
    endelse

    run->getProperty, log_dir=log_dir, date=date

    realtime_logfile = filepath(run.date + '.realtime.log', root=log_dir)
    eod_logfile = filepath(run.date + '.eod.log', root=log_dir)

    rt_errors = kcor_filter_log(realtime_logfile, /error, n_messages=n_rt_errors)
    eod_errors = kcor_filter_log(eod_logfile, /error, n_messages=n_eod_errors)

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

    msg = [msg, '', '', '# Config file', '', run.config_content, '', '', $
           string(mg_src_root(/filename), who, $
                  format='(%"Sent from %s (%s)")')]

    n_errors_msg = n_rt_errors eq 0L && n_eod_errors eq 0L $
                     ? '' $
                     : string(n_rt_errors, n_eod_errors, $
                              format='(%" - %d rt, %d eod errors")')

    kcor_send_mail, run.notification_email, $
                    string(date, $
                           success ? 'success' : 'problems', $
                           n_errors_msg, $
                           format='(%"KCor end-of-day processing for %s (%s%s)")'), $
                    msg, $
                    attachments=quality_plot, $
                    logger_name='kcor/eod'
  endif else begin
    mg_log, 'not sending notification email', name='kcor/eod', /warn
  endelse


  done:
  mg_log, /check_math, name='kcor/eod', /debug
  mg_log, 'done', name='kcor/eod', /info
  obj_destroy, run
end


; main-level example program

date = '20180208'
config_filename = filepath('kcor.mgalloy.mahi.latest.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
kcor_eod, date, config_filename=config_filename

end
