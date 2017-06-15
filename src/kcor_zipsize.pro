; docformat = 'rst'

;+
; Determine the unzipped size of a zipped file.
;
; NOTE: this routine is dependent on the format of the output from `gunzip
; -l`. If this changes in a new version of `gunzip`, it will probably break this
; routine.
;
; :Returns:
;   number of bytes as a long
;
; :Params:
;   filename : in, required, type=string
;     name of file to check
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;-
function kcor_zipsize, filename, run=run
  compile_opt strictarr

  cmd = string(run.gunzip, filename, format='(%"%s -l %s")')
  spawn, cmd, result, error_result, exit_status=status
  if (status ne 0L) then begin
    logger_name = run.mode eq 'realtime' ? 'kcor/rt' : 'kcor/eod'
    mg_log, 'error checking unzipped size of %s', filename, $
            name=logger_name, /error
    mg_log, '%s', strjoin(error_result, ' '), name=logger_name, /error
    return, -1L
  endif

  tokens = strsplit(result[1], /extract)
  return, long(tokens[1])
end


; main-level example

date = '20140415'
config_filename = '../config/kcor.mgalloy.mahi.reprocess.cfg'
run = kcor_run(date, config_filename=config_filename)

files = file_search(filepath('*.fts.gz', $
                             subdir=[date, 'level0'], $
                             root=run.raw_basedir), $
                    count=nfiles)

for f = 0L, nfiles - 1L do begin
  zsize = kcor_zipsize(files[f], run=run)
  print, files[f], zsize, format='(%"%s: %d bytes")'
endfor

obj_destroy, run

end
