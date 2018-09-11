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

  ; difference images
  diff_filenames = file_search(filepath('*minus*', $
                                        subdir=[date, 'level1'], $
                                        root=run.raw_basedir), $
                               count=n_diff_filenames)
  if (n_diff_filenames gt 0L) then begin
    file_copy, diff_filenames, filepath('difference', save_dir)
  endif

  ; extended average files
  extavg_filenames = file_search(filepath('*extavg*', $
                                          subdir=[date, 'level1'], $
                                          root=run.raw_basedir), $
                                 count=n_extavg_filenames)
  if (n_extavg_filenames gt 0L) then begin
    file_copy, extavg_filenames, filepath('extavg', save_dir)
  endif

  ; p and q directories
  file_copy, filepath('p', subdir=date, root=run.raw_basedir), $
             save_dir, $
             /recursive

  file_copy, filepath('q', subdir=date, root=run.raw_basedir), $
             save_dir, $
             /recursive

  done:
  mg_log, 'done', name='kcor/eod', /info
end
