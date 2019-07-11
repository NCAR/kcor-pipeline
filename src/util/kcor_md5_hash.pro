; docformat = 'rst'

;+
; Return the md5 hash of a local file.
;
; :Returns:
;   string
;
; :Params:
;   filename : in, required, type=string
;     HPSS filename to check
;
; :Keywords:
;   logger_name : in, type=string
;     name of logger
;   run : in, required, type=object
;     KCor run object
;   status : out, optional, type=integer
;     set to a named variable to retrieve the error status for the HPSS query,
;     0 for none
;-
function kcor_md5_hash, filename, $
                        logger_name=logger_name, run=run, status=status
  compile_opt strictarr

  cmd = string(filename, format='(%"openssl dgst -md5 %s")')
  spawn, cmd, output, openssl_error_output, exit_status=status
  if (status eq 0L) then begin
    hash = (strsplit(output[0], /extract))[-1]
  endif else begin
    hash = ''
    mg_log, 'problem calculating md5 hash with openssl', name=logger_name, /error
    mg_log, '%s', mg_strmerge(openssl_error_output), name=logger_name, /error
    status = 1
  endelse

  return, hash
end


