; docformat = 'rst'

;+
; Wrapper to be called from kcor script to remove the raw directory for a day.
;
; :Params:
;   date : in, required, type=string
;     date to process in the form "YYYYMMDD"
;
; :Keywords:
;    config_filename : in, required, type=string
;      filename of config file
;-
pro kcor_remove, date, config_filename=config_filename
  compile_opt strictarr

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

  run = kcor_run(date, config_filename=config_filename)

  mg_log, 'starting remove for %s', date, name='kcor/reprocess', /info

  mg_log, 'removing level1/ directory', name='kcor/reprocess', /info

  level1_dir = filepath('level1', $
                        subdir=date, $
                        root=run->config('processing/raw_basedir'))
  file_delete, level1_dir, /recursive, /allow_nonexistent

  mg_log, 'done', name='kcor/reprocess', /info

  done:
  if (obj_valid(run)) then obj_destroy, run
end
