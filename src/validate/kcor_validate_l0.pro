; docformat = 'rst'

pro kcor_validate_l0, l0_fits_files, spec, logger_name=logger_name, run=run
  compile_opt strictarr

  body = list()

  n_problem_files = 0L
  n_problems      = 0L

  for f = 0L, n_elements(l0_fits_files) - 1L do begin
    is_valid = kcor_validate_l0_file(l0_fits_files[f], spec, $
                                     error_msg=error_msg)
    if (~is_valid) then begin
      n_problem_files++
      n_problems += n_elements(error_msg)

      body->add, string(l0_fits_files[f], format='(%"%s")')
      body->add, '    ' + error_msg, /extract
      body->add, ''

      mg_log, 'problem with: %s', l0_fits_files[f], name=logger_name, /warn
      for e = 0L, n_elements(error_msg) - 1L do begin
        mg_log, ' - %s', error_msg[e], name=logger_name, /warn
      endfor
    endif
  endfor

  ; send notification if some files are not valid
  if (n_problems gt 0L) then begin
    if (run->config('notifications/send')) then begin
      if (n_elements(run->config('notifications/email')) eq 0L) then begin
        mg_log, 'no email specified to send notification to', name=logger_name, /info
        goto, done
      endif else begin
        mg_log, 'sending L0 validation failures to %s', $
                run->config('notifications/email'), $
                name=logger_name, /info
      endelse
    endif else begin
      mg_log, 'not sending L0 validation failures', name=logger_name, /info
      goto, done
    endelse

    spawn, 'echo $(whoami)@$(hostname)', who, error_result, exit_status=status
    if (status eq 0L) then begin
      who = who[0]
    endif else begin
      who = 'unknown'
    endelse

    credit = string(mg_src_root(/filename), who, format='(%"Sent from %s (%s)")')

    address = run->config('notifications/email')
    subject = string(run.date, n_problems, n_problem_files, $
                     format='(%"KCor L0 validation failures for %s (%d problems in %s files)")')
    body->add, credit

    kcor_send_mail, address, subject, body->toArray(), $
                    error=error, logger_name=logger_name
  endif

  done:

  obj_destroy, body
end
