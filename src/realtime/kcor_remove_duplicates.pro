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
pro kcor_remove_duplicates, raw_dir, l0_dir, logger_name=logger_name
  compile_opt strictarr

  raw_l0_files = file_search(filepath('*.fts*', root=raw_dir), $
                             count=n_raw_l0_files)
  process_datetimes = strmid(file_basename(file_search(filepath('*.fts*', root=l0_dir), $
                                                       count=n_processed_l0_files)), $
                             0, 15)
  for f = 0L, n_raw_l0_files - 1L do begin
    basename = file_basename(raw_l0_files[f])
    dt = strmid(basename, 0, 15)
    !null = where(dt eq process_datetimes, n_matches)
    if (n_matches gt 0L) then begin
      mg_log, '%s already in level0/ directory, removing...', basename, $
              name=logger_name, /warn
      file_delete, raw_l0_files[f]
    endif
  endfor
end
