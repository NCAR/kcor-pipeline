; docformat = 'rst'

;+
; Save some of the processing.
;
; :Params:
;   date : in, required, type=string, 
;     format='yyyymmdd', where yyyy=year, mm=month, dd=day
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;-
pro kcor_save_results, date, run=run
  compile_opt strictarr

  if (run.save_basedir eq '') then begin
    mg_log, 'no save_basedir specified, skipping saving results', $
            name='kcor/eod', /info
    goto, done
  endif else begin
    mg_log, 'saving results...', name='kcor/eod', /info
  endelse

  save_dir = filepath(date, root=run.save_basedir)
  if (~file_test(save_dir, /directory)) then file_mkdir, save_dir

  ; difference images
  diff_filenames = file_search(filepath('*minus*', $
                                        subdir=[date, 'level1'], $
                                        root=run.raw_basedir), $
                               count=n_diff_filenames)
  if (n_diff_filenames gt 0L) then begin
    diff_dir = filepath('difference', root=save_dir)
    if (~file_test(diff_dir, /directory)) then file_mkdir, diff_dir
    file_copy, diff_filenames, diff_dir, /overwrite
  endif

  ; extended average files
  extavg_filenames = file_search(filepath('*extavg*', $
                                          subdir=[date, 'level1'], $
                                          root=run.raw_basedir), $
                                 count=n_extavg_filenames)
  if (n_extavg_filenames gt 0L) then begin
    extavg_dir = filepath('extavg', root=save_dir)
    if (~file_test(extavg_dir, /directory)) then file_mkdir, extavg_dir
    file_copy, extavg_filenames, extavg_dir, /overwrite
  endif

  ; p and q directories
  file_copy, filepath('p', subdir=date, root=run.raw_basedir), $
             save_dir, $
             /recursive, /overwrite

  file_copy, filepath('q', subdir=date, root=run.raw_basedir), $
             save_dir, $
             /recursive, /overwrite

  ; *.log files
  log_files = file_search(filepath('*.log', root=run.raw_basedir), $
                          count=n_log_files)
  if (n_log_files gt 0L) then file_copy, log_files, save_dir

  done:
  mg_log, 'done', name='kcor/eod', /info
end
