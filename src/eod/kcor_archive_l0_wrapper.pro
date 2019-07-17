; docformat = 'rst'

;+
; Wrapper to call `kcor_archive_l0`.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;
; :Keywords:
;   config_filename : in, required, type=string
;     filename of config file
;-
pro kcor_archive_l0_wrapper, date, config_filename=config_filename
  compile_opt strictarr

  ; catch and log any crashes
  catch, error
  if (error ne 0L) then begin
    catch, /cancel
    mg_log, /last_error, name='kcor/eod', /critical
    kcor_crash_notification, /realtime, run=run
    goto, done
  endif

  valid_date = kcor_valid_date(date, msg=msg)
  if (~valid_date) then message, msg

  run = kcor_run(date, config_filename=config_filename)
  kcor_archive_l0, run=run

  done:
  if (obj_valid(run)) then obj_destroy, run
end
