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

  filename = filepath(string(run.date, format='(%"%s.kcor.daily.o1focus.gif")'), $
                      subdir=[run.date, 'p'], $
                      root=run->config('processing/raw_basedir'))

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

  times = fltarr(n_raw_files)
  o1focus = fltarr(n_raw_files)
  for r = 0L, n_raw_files - 1L do begin
    header = headfits(raw_files[r])

    date_obs = sxpar(header, 'DATE-OBS')
    hour = strmid(date_obs, 11, 2)
    minute = strmid(date_obs, 14, 2)
    second = strmid(date_obs, 17, 2)
    hst_time = kcor_ut2hst(hour + minute + second)
    hour = long(strmid(hst_time, 0, 2))
    minute = long(strmid(hst_time, 2, 2))
    second = long(strmid(hst_time, 4, 2))
    times[r] = hour + (minute + second / 60.0) / 60.0

    o1focus[r] = sxpar(header, 'O1FOCS')
  endfor

  title = string(run.date, format='(%"O1 focus for %s")')
  kcor_o1focus_plot, filename, times, o1focus, title=title, run=run

  done:
  mg_log, 'done', name=run.logger_name, /info
end


; main-level example program

date = '20200813'
config_basename = 'kcor.production.cfg'
config_filename = filepath(config_basename, $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)
kcor_daily_o1focus_plot, run=run
obj_destroy, run

end
