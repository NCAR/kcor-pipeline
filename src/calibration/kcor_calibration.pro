; docformat = 'rst'

;+
; Routine to create a calibration for a day, given a file list, date, and config
; file.
;
; Updates the database if `FILELIST_FILENAME` is not present.
;
; :Params:
;   date : in, required, type=date
;     date in the form 'YYYYMMDD' to produce calibration for
;
; :Keywords:
;   config_filename : in, required, type=string
;     filename of configuration file
;   filelist_filename : in, optional, type=string
;     filename of list of files, if not present, does a catalog to make the list
;     of cal files for the day
;-
pro kcor_calibration, date, $
                      config_filename=config_filename, $
                      filelist_filename=filelist_filename
  compile_opt strictarr

  cal_clock = tic('cal')

  ; catch and log any crashes
  catch, error
  if (error ne 0L) then begin
    catch, /cancel
    mg_log, /last_error, name='kcor/eod', /critical
    goto, done
  endif

  valid_date = kcor_valid_date(date, msg=msg)
  if (~valid_date) then message, msg

  run = kcor_run(date, config_filename=config_filename, mode='eod')

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
  mg_log, 'starting calibration for %s', date, name='kcor/eod', /info

  if (~run->epoch('produce_calibration')) then begin
    mg_log, 'skipping reducing calibration', name='kcor/eod', /info
    goto, done
  endif
      
  if (n_elements(filelist_filename) gt 0L) then begin
    n_files = file_lines(filelist_filename)
    filelist = strarr(n_files)

    mg_log, 'using provided list of files for calibration', name='kcor/eod', /info
    openr, lun, filelist_filename, /get_lun

    filelist_line = ''
    for f = 0L, n_files - 1L do begin
      readf, lun, filelist_line
      tokens = strsplit(filelist_line, /extract)
      filelist[f] = tokens[0]
    endfor

    free_lun, lun
  endif else begin
    if (run->config('eod/catalog_files')) then begin
      ; clear inventory files before catalog'ing
      txt_glob = filepath('*.txt', subdir=date, $
                          root=run->config('processing/process_basedir'))
      txt_files = file_search(txt_glob, count=n_files)
      if (n_files gt 0L) then begin
        mg_log, 'deleting %d old inventory files', n_files, $
                name='kcor/eod', /debug
        file_delete, txt_files, /allow_nonexistent
      endif else begin
        mg_log, 'no old inventory log files to delete', name='kcor/eod', /debug
      endelse

      kcor_catalog, date, run=run, catalog_dir=catalog_dir
    endif
  endelse

  kcor_reduce_calibration, date, run=run, filelist=filelist, $
                           catalog_dir=catalog_dir, $
                           cal_filename=cal_filename, $
                           status=cal_status

  if (cal_status eq 0L) then begin
    kcor_plot_calibration, cal_filename, $
                           run=run, gain_norm_stddev=gain_norm_stddev
  endif

  cal_files = kcor_read_calibration_text(date, $
                                         run->config('processing/process_basedir'), $
                                         exposures=exposures, $
                                         n_files=n_cal_files, $
                                         n_all_files=n_all_cal_files, $
                                         run=run, $
                                         quality=cal_quality)

  ; update databases
  if (run->config('database/update') && (n_elements(filelist_filename) eq 0L)) then begin
    mg_log, 'updating database', name='kcor/eod', /info

    obsday_index = mlso_obsday_insert(date, $
                                      run=run, $
                                      database=db, $
                                      status=db_status, $
                                      log_name='kcor/eod')

    if (db_status eq 0L) then begin
      kcor_db_clearday, run=run, database=db, $
                        obsday_index=obsday_index, $
                        log_name='kcor/eod', /calibration

      if (n_cal_files gt 0L) then begin
        kcor_cal_insert, date, cal_files, cal_quality, $
                         catalog_dir=catalog_dir, $
                         run=run, $
                         database=db, $
                         obsday_index=obsday_index
      endif else begin
        mg_log, 'no cal files for kcor_cal table', name='kcor/eod', /info
      endelse
    endif else begin
      mg_log, 'error connecting to database', name='kcor/eod', /warn
    endelse
    obj_destroy, db
  endif else begin
    mg_log, 'skipping updating database', name='kcor/eod', /info
  endelse

  ; send notification
  if (run->config('notifications/send') $
        && n_elements(run->config('notifications/email')) gt 0L) then begin
    case cal_status of
      0: cal_status_text = 'Successful calibration reduction'
      1: cal_status_text = 'Incomplete data for calibration reduction'
      2: cal_status_text = 'Error during calibration reduction'
      else: cal_status_text = 'Unknown error during calibration reduction'
    endcase
    msg = [string(date, $
                  format='(%"KCor calibration for %s")'), $
           '', $
           string(version, revision, branch, $
                  format='(%"kcor-pipeline %s (%s) [%s]")'), $
           '', $
           '# Basic statistics', $
           '', $
           string(n_cal_files, $
                  format='(%"number of OK cal files: %d")'), $
           string(n_all_cal_files, $
                  format='(%"number of cal files: %d")'), $
           cal_status_text $
             + (cal_status eq 0L ? string(gain_norm_stddev, $
                                          format='(%" [std dev / median cam 0: %0.4f, cam 1: %0.4f]")') : '')]

    spawn, 'echo $(whoami)@$(hostname)', who, error_result, exit_status=status
    if (status eq 0L) then begin
      who = who[0]
    endif else begin
      who = 'unknown'
    endelse

    log_dir = run->config('logging/dir')

    eod_logfile = filepath(run.date + '.eod.log', root=log_dir)
    eod_errors = kcor_filter_log(eod_logfile, /error, n_messages=n_eod_errors)
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

    case cal_status of
      0: cal_status_msg = 'success'
      1: cal_status_msg = 'incomplete'
      2: cal_status_msg = 'problems'
      else: cal_status_msg = string(cal_status, format='(%"unknown status: %d")')
    endcase

    mg_log, 'sending notification to %s', run->config('notifications/email'), $
            name='kcor/eod', /info
    kcor_send_mail, run->config('notifications/email'), $
                    string(run.date, $
                           cal_status_msg, $
                           format='(%"KCor calibration for %s (%s)")'), $
                    msg, $
                    logger_name='kcor/eod'
  endif else begin
    mg_log, 'not sending notification email', name='kcor/eod', /warn
  endelse

  done:
  mg_log, /check_math, name='kcor/eod', /debug

  cal_time = toc(cal_clock)
  mg_log, 'done, cal processing time: %s', $
          kcor_sec2str(cal_time), $
          name='kcor/eod', /info

  if (obj_valid(run)) then obj_destroy, run
end