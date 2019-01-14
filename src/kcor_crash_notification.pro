; docformat = 'rst'

;+
; Send notification when the pipeline crashes.
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;-
pro kcor_crash_notification, run=run, realtime=realtime, eod=eod
  compile_opt strictarr

  help, /last_message, output=help_output
  body = [help_output, '']

  if (~obj_valid(run)) then begin
    if (n_elements(helpOutput) gt 1L && help_output[0] ne '') then begin
      print, transpose(help_output)
    endif
    return
  endif

  case 1 of
    keyword_set(realtime): begin
        logger_name = 'kcor/rt'
        rt_log_filename = filepath(run.date + '.realtime.log', root=run.log_dir)
        rt_errors = kcor_filter_log(rt_log_filename, /error, n_messages=n_rt_errors)
        name = 'real-time'
        body = [body, rt_log_filename, '', rt_errors]
      end
    keyword_set(eod): begin
        logger_name = 'kcor/eod'
        eod_log_filename = filepath(run.date + '.eod.log', root=run.log_dir)
        eod_errors = kcor_filter_log(eod_log_filename, /error, n_messages=n_eod_errors)
        name = 'end-of-day'
        body = [body, eod_log_filename, '', eod_errors]
      end
  endcase

  if (run.send_notifications) then begin
    mg_log, 'sending crash notification to %s', run.notification_email, $
            name=logger_name, /info
  endif else begin
    mg_log, 'not sending crash notification', name=logger_name, /info
    return
  endelse

  spawn, 'echo $(whoami)@$(hostname)', who, error_result, exit_status=status
  if (status eq 0L) then begin
    who = who[0]
  endif else begin
    who = 'unknown'
  endelse

  credit = string(mg_src_root(/filename), who, format='(%"Sent from %s (%s)")')

  address = run.notification_email
  subject = string(name, run.date, $
                   format='(%"KCor crash during %s processing for %s")')
  body = [body, '', credit]

  kcor_send_mail, address, subject, body, error=error, logger_name=logger_name
end
