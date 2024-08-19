; docformat = 'rst'

;+
; Produce plot of the last 28 days' O1 focus values by time of day.
;
; :Keywords:
;   database : in, required, type=object
;     database connection
;   run : in, required, type=object
;     KCor run object
;-
pro kcor_rolling_o1focus_plot, database=db, run=run
  compile_opt strictarr

  n_days = 28

  p_dir = filepath('p', subdir=run.date, $
                   root=run->config('processing/raw_basedir'))
  if (~file_test(p_dir, /directory)) then file_mkdir, p_dir

  filename = filepath(string(run.date, n_days, format='(%"%s.kcor.%dday.o1focus.gif")'), $
                      root=p_dir)

  end_date_tokens = long(kcor_decompose_date(run.date))
  end_date = string(end_date_tokens, format='(%"%04d-%02d-%02d")')
  end_date_jd = julday(end_date_tokens[1], $
                       end_date_tokens[2], $
                       end_date_tokens[0], $
                       0, 0, 0)
  start_date_jd = end_date_jd - n_days + 1
  start_date = string(start_date_jd, $
                      format='(C(CYI4.4, "-", CMoI2.2, "-", CDI2.2))')

  query = 'select kcor_eng.* from kcor_eng, mlso_numfiles where kcor_eng.obs_day=mlso_numfiles.day_id and mlso_numfiles.obs_day between ''%s'' and ''%s'''
  rows = db->query(query, start_date, end_date, count=n_rows, error=error)
  if (n_rows gt 0L) then begin
    mg_log, '%d dates between %s and %s', n_rows, start_date, end_date, $
            name=run.logger_name, /debug
  endif else begin
    mg_log, 'no data found between %s and %s', start_date, end_date, $
            name=run.logger_name, /warn
    goto, done
  endelse

  times = fltarr(n_rows)
  o1focus = rows.o1focs
  for r = 0L, n_rows - 1L do begin
    hst_time = kcor_dateobs2hst(rows[r].date_obs)
    times[r] = kcor_decimal_time(hst_time)
  endfor

  title = string(start_date, end_date, format='(%"O1 focus for %s to %s")')
  kcor_o1focus_plot, filename, times, o1focus, title=title, run=run

  done:
  mg_log, 'done', name=run.logger_name, /info
end


; main-level example program

date = '20221026'
config_basename = 'kcor.production.cfg'
config_filename = filepath(config_basename, $
                           subdir=['..', '..', '..', 'kcor-config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)
db = kcordbmysql()
db->connect, config_filename=run->config('database/config_filename'), $
             config_section=run->config('database/config_section')

kcor_rolling_o1focus_plot, database=db, run=run

obj_destroy, [db, run]

end
