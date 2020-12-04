; docformat = 'rst'

;+
; Validate given FITS files.
;
; :Params:
;   fits_files : in, required, type=strarr
;     array of FITS filenames to check
;   spec_filename : in, required, type=string
;     filename of validation spec to use
;   type : in, required, type=string
;     type of files, "L0" or "L1.5"
;
; :Keywords:
;   n_invalid_files : out, optional, type=integer
;     set to a named variable to retrieve the number of files with a validation
;     problem
;   logger_name : in, optional, type=string
;     name of logger to send output to; if not present, sent to stdout
;   run : in, required, type=object
;     `kcor_run` object
;-
pro kcor_validate, fits_files, spec_filename, type, $
                   n_invalid_files=n_problem_files, $
                   logger_name=logger_name, run=run
  compile_opt strictarr

  body = list()

  n_problem_files = 0L
  n_problems      = 0L

  for f = 0L, n_elements(fits_files) - 1L do begin
    is_valid = kcor_validate_file(fits_files[f], spec_filename, type, $
                                  error_msg=error_msg, run=run)
    if (~is_valid) then begin
      n_problem_files++
      n_problems += n_elements(error_msg)

      body->add, string(fits_files[f], format='(%"%s")')
      body->add, '    ' + error_msg, /extract
      body->add, ''

      mg_log, 'problem with: %s', file_basename(fits_files[f]), $
              name=logger_name, /warn
      for e = 0L, n_elements(error_msg) - 1L do begin
        mg_log, ' - %s', error_msg[e], name=logger_name, /warn
      endfor
    endif
  endfor

  ; send notification if some files are not valid
  if (n_problems gt 0L && run->config('validation/send_warnings')) then begin
    mg_log, '%d invalid %s files', n_problems, type, $
            name=logger_name, /info

    if (run->config('validation/send_warnings')) then begin
      if (n_elements(run->config('validation/email')) eq 0L) then begin
        mg_log, 'no email specified to send notification to', name=logger_name, /info
        goto, done
      endif else begin
        mg_log, 'sending %s validation failures to %s', $
                type, $
                run->config('validation/email'), $
                name=logger_name, /info
      endelse
    endif else begin
      mg_log, 'not sending %s validation failures', type, name=logger_name, /info
      goto, done
    endelse

    spawn, 'echo $(whoami)@$(hostname)', who, error_result, exit_status=status
    if (status eq 0L) then begin
      who = who[0]
    endif else begin
      who = 'unknown'
    endelse

    credit = string(mg_src_root(/filename), who, format='(%"Sent from %s (%s)")')

    address = run->config('validation/email')
    subject = string(type, run.date, n_problems, n_problem_files, $
                     format='(%"KCor %s validation failures for %s (%d problems in %d files)")')
    body->add, credit

    kcor_send_mail, address, subject, body->toArray(), $
                    error=error, logger_name=logger_name
  endif else begin
    mg_log, 'no invalid %s files', type, name=logger_name, /info
  endelse

  done:

  obj_destroy, body
end
