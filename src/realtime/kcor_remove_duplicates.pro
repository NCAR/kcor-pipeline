; docformat = 'rst'

;+
; Delete level 0 files if they are already in the `l0_dir`.
;
; :Params:
;   raw_dir : in, required, type=string
;     raw directory where level 0 files are initially placed
;   l0_dir : in, required, type=string
;     directory where processed level 0 files are placed
;
; :Keywords:
;   logger_name : in, optional, type=string
;     name of logger
;-
function kcor_remove_duplicates, raw_dir, l0_dir, $
                                 logger_name=logger_name, $
                                 count=count
  compile_opt strictarr

  count = 0L
  glob = '*_kcor.fts.gz'
  raw_l0_files = file_search(filepath(glob, root=raw_dir), $
                             count=n_raw_l0_files)
  if (n_raw_l0_files eq 0L) then return, !null

  process_datetimes = strmid(file_basename(file_search(filepath(glob, root=l0_dir), $
                                                       count=n_processed_l0_files)), $
                             0, 15)

  keep = bytarr(n_raw_l0_files) + 1B
  if (n_processed_l0_files gt 0L) then begin
    for f = 0L, n_raw_l0_files - 1L do begin
      basename = file_basename(raw_l0_files[f])
      dt = strmid(basename, 0, 15)
      !null = where(dt eq process_datetimes, n_matches)
      if (n_matches gt 0L) then begin
        mg_log, 'removing %s...', basename, $
                name=logger_name, /warn
        file_delete, raw_l0_files[f]
        keep[f] = 0B
      endif
    endfor
  endif

  keep_indices = where(keep eq 1B, count, /null)
  return, raw_l0_files[keep_indices]
end
