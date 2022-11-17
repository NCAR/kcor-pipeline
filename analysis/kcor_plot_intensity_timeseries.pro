; docformat = 'rst'

pro kcor_plot_intensity_timeseries, run=run
  compile_opt strictarr

  db = kcordbmysql(logger_name=log_name)
  db->connect, config_filename=run->config('database/config_filename'), $
               config_section=run->config('database/config_section'), $
               status=status, error_message=error_message

  data = db->query('select date_obs, intensity from kcor_sci order by date_obs', $
                   status=status, error_message=error_message, sql_statement=sql_cmd)

  n_days = n_elements(data)
  jds = dblarr(n_days)
  for d = 0L, n_days - 1L do jds[d] = kcor_dateobs2julian(data[d].date_obs)

  heights = [1.11, 1.15, 1.19, 1.25]
  height_indices = [3, 5, 7, 10]
  intensity = fltarr(n_days, n_elements(heights))

  for d = 0L, n_days - 1L do begin
    intensity[d, *] = (float(*data[d].intensity, 0, 90))[height_indices]
  endfor

  start_date = julday(12, 1, 2012)
  end_date = julday(4, 6, 2018)
  !null = label_date(date_format='%Y-%N')

  window, xsize=1000, ysize=1200, title='KCor intensity', /free
  !p.multi = [0, 1, n_elements(heights)]
  for h = 0L, n_elements(heights) - 1L do begin
    plot, jds, intensity[*, h], $
          title=string(heights[h], format='KCor intensity at %0.2f Rsun'), $
          xstyle=1, xrange=[start_date, end_date], xtickformat='label_date', xticks=10, $
          ystyle=1, yrange=[0.0, 6.0e-7], $
          psym=6, symsize=0.25, $
          charsize=2.0
  endfor
  !p.multi = 0

  obj_destroy, db
end


; main-level program

date = '20130930'
config_basename = 'kcor.production.cfg'
config_filename = filepath(config_basename, subdir=['..', 'config'], root=mg_src_root())
run = kcor_run(date, config_filename=config_filename, mode='test')

kcor_plot_intensity_timeseries, run=run

end
