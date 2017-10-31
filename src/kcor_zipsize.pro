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
function kcor_zipsize, filenames, run=run, logger_name=logger_name, block_size=block_size
  compile_opt strictarr

  n_files = n_elements(filenames)
  _block_size = n_elements(block_size) eq 0L ? 10L : block_size

  if (n_files gt _block_size) then begin
    sizes = lonarr(n_files)
    for b = 0L, ceil(n_files / float(_block_size)) - 1L do begin
      first = b * _block_size
      last = ((b + 1) * _block_size - 1L) < (n_files - 1L)
      sizes[first:last] = kcor_zipsize(filenames[first:last], $
                                       run=run, $
                                       logger_name=logger_name, $
                                       block_size=_block_size)
    endfor
    return, sizes
  endif

  cmd = string(run.gunzip, strjoin(filenames, ' '), format='(%"%s -l %s")')
  spawn, cmd, result, error_result, exit_status=status
  if (status ne 0L) then begin
    _logger_name = n_elements(logger_name) eq 0L $
                   ? (run.mode eq 'realtime' ? 'kcor/rt' : 'kcor/eod') $
                   : logger_name
    mg_log, 'error checking unzipped size of %s', strjoin(filenames, ', '), $
            name=_logger_name, /error
    mg_log, '%s', strjoin(error_result, ' '), name=_logger_name, /error
    return, -1L
  endif

  sizes = lonarr(n_files)
  for f = 0L, n_files - 1L do begin
    matches = strmatch(result, '*' + file_basename(filenames[f], '.gz'))
    ind = where(matches, count)
    tokens = strsplit(result[ind[0]], /extract)
    sizes[f] = long(tokens[1])
  endfor

  return, n_files eq 1L ? sizes[0] : sizes
end


; main-level example

date = '20140415'
config_filename = '../config/kcor.mgalloy.mahi.reprocess.cfg'
run = kcor_run(date, config_filename=config_filename)

files = file_search(filepath('*.fts.gz', $
                             subdir=[date, 'level0'], $
                             root=run.raw_basedir), $
                    count=nfiles)

tic
individual_zsizes = lonarr(nfiles)
for f = 0L, nfiles - 1L do begin
  individual_zsizes[f] = kcor_zipsize(files[f], run=run)
endfor
toc

tic
zsizes = kcor_zipsize(files, run=run)
toc

for f = 0L, nfiles - 1L do begin
  print, file_basename(files[f]), zsizes[f], format='(%"%s: %d bytes")'
endfor

print, array_equal(zsizes, individual_zsizes) ? 'equal' : 'not equal'

obj_destroy, run

end
