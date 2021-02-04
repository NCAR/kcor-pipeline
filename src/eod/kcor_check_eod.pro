; docformat = 'rst'

;+
; Check if end-of-day results were produced for the given date (if there were
; any level 0 files for the day).
;
; :Params:
;   date : in, required, type=date
;     date in the form 'YYYYMMDD' to process
;
; :Keywords:
;   config_filename : in, required, type=string
;     filename of configuration file controlling the run
;-
pro kcor_check_eod, date, config_filename=config_filename
  compile_opt strictarr

  mode = 'eod'
  log_name = 'kcor/' + mode

  ; catch and log any crashes
  catch, error
  if (error ne 0L) then begin
    catch, /cancel
    mg_log, /last_error, name=log_name, /critical
    kcor_crash_notification, /eod, run=run
    goto, done
  endif

  run = kcor_run(date, config_filename=config_filename, mode=mode)
  if (~obj_valid(run)) then message, 'problem creating run object'

  ; check if there were raw files
  processed_raw_files = file_search(filepath('*.fts*', $
                                             subdir=[date, 'level0'], $
                                             root=run->config('processing/raw_basedir')), $
                                    count=n_processed_raw_files)

  unprocessed_raw_files = file_search(filepath('*.fts*', $
                                               subdir=[date, 'level0'], $
                                               root=run->config('processing/raw_basedir')), $
                                      count=n_unprocessed_raw_files)

  ; check if there was a level 0 tarball produced
  level0_tarball = file_search(filepath('*.tgz', $
                                        subdir=[date, 'level0'], $
                                        root=run->config('processing/raw_basedir')), $
                               count=n_level0_tarball)

  mg_log, 'processed level 0 files: %d', n_processed_raw_files, $
          name=log_name, /info
  mg_log, 'unprocessed level 0 files: %d', n_unprocessed_raw_files, $
          name=log_name, /info
  mg_log, 'level 0 tarball %sfound', n_level0_tarball gt 0L ? '' : 'not ', $
          name=log_name, /info

  ; if there were raw files, but no level 0 tarball send an email notification
  problems = (n_processed_raw_files + n_unprocessed_raw_files gt 0L) $
               && n_level0_tarball eq 0L
  if (problems) then begin
    if (run->config('notifications/send') $
          && n_elements(run->config('notifications/email')) gt 0L) then begin
      mg_log, 'sending notification to %s', run->config('notifications/email'), $
              name=log_name, /info

      machine_log = filepath(string(date, format='(%"%s.kcor.machine.log")'),
                             root=run->config('processing/raw_basedir'))
      t1_log = filepath(string(date, format='(%"%s.kcor.t1.log")'),
                        root=run->config('processing/raw_basedir'))

      spawn, 'echo $(whoami)@$(hostname)', who, error_result, exit_status=status
      if (status eq 0L) then begin
        who = who[0]
      endif else begin
        who = 'unknown'
      endelse

      msg = [string(n_processed_raw_files, format='(%"processed level 0 files: %d")'), $
             string(n_unprocessed_raw_files, format='(%"unprocessed level 0 files: %d")'), $
             string(n_level0_tarball gt 0L ? '' : 'not ', format='(%"level 0 tarball %sfound")'), $
             string(file_test(machine_log, /regular) ? '' : 'not ', format='(%"machine log %spresent")'), $
             string(file_test(t1_log, /regular) ? '' : 'not ', format='(%"t1 log %spresent")'), $
             '', $
             string(mg_src_root(/filename), who, format='(%"Sent from %s (%s)")')]

      kcor_send_mail, run->config('notifications/email'), $
              string(date, $
                     format='(%"KCor end-of-day processing for %s did not run")'), $
              msg, $
              logger_name=log_name
    endif else begin
      mg_log, 'not sending notification email', name=log_name, /warn
    endelse
  endif

  done:
  mg_log, 'done, eod check', name=log_name, /info
  obj_destroy, run
end
