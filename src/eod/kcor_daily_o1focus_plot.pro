; docformat = 'rst'

;+
; Produce plot of the day's O1 focus values by time of day.
;
; :Keywords:
;   run : in, required, type=object
;     KCor run object
;-
pro kcor_daily_o1focus_plot, run=run
  compile_opt strictarr

  p_dir = filepath('p', subdir=run.date, $
                   root=run->config('processing/raw_basedir'))
  if (~file_test(p_dir, /directory)) then file_mkdir, p_dir

  filename = filepath(string(run.date, format='(%"%s.kcor.daily.o1focus.gif")'), $
                      root=p_dir)

  raw_files = file_search(filepath('*.fts*', $
                                  subdir=[run.date, 'level0'], $
                                  root=run->config('processing/raw_basedir')), $
                          count=n_raw_files)
  if (n_raw_files eq 0L) then begin
    mg_log, 'no raw files to plot', name=run.logger_name, /info
    goto, done
  endif else begin
    mg_log, 'plotting O1FOCS of %d raw files', n_raw_files, $
            name=run.logger_name, /info
  endelse

  times = fltarr(n_raw_files) + !values.f_nan
  o1focus = fltarr(n_raw_files) + !values.f_nan
  for r = 0L, n_raw_files - 1L do begin
    run.time = strmid(file_basename(raw_files[r]), 9, 6)
    if (~run->epoch('process')) then begin
      mg_log, 'skipping %s', file_basename(raw_files[r]), name=run.logger_name, /warn
      continue
    endif

    header = headfits(raw_files[r])

    date_obs = sxpar(header, 'DATE-OBS')
    hst_time = kcor_dateobs2hst(date_obs)
    times[r] = kcor_decimal_time(hst_time)

    o1focus[r] = sxpar(header, 'O1FOCS')
  endfor

  title = string(run.date, format='(%"O1 focus for %s")')
  kcor_o1focus_plot, filename, times, o1focus, title=title, run=run

  done:
  mg_log, 'done', name=run.logger_name, /info
end


; main-level example program

date = '20240330'
config_basename = 'kcor.production.cfg'
config_filename = filepath(config_basename, $
                           subdir=['..', '..', '..', 'kcor-config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)
kcor_daily_o1focus_plot, run=run
obj_destroy, run

end
