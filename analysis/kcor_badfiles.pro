; docformat = 'rst'

pro kcor_badfiles, db
  compile_opt strictarr

  ; per day, find number of OK files and total files

  q = 'select count(*), raw.count, raw.date from (select count(*) as count, kcor_raw.obs_day as obsday_id, mlso_numfiles.obs_day as date from kcor_raw inner join mlso_numfiles on kcor_raw.obs_day=mlso_numfiles.day_id group by kcor_raw.obs_day order by mlso_numfiles.obs_day) as raw inner join kcor_img on raw.obsday_id=kcor_img.obs_day where kcor_img.producttype=1 group by raw.obsday_id order by raw.date;'
  results = db->query(q, count=n_dates)

  jds = dblarr(n_dates)
  for d = 0L, n_dates - 1L do begin
    tokens = long(strsplit(results[d].date, '-', /extract))
    jds[d] = julday(tokens[1], tokens[2], tokens[0], 0, 0, 0)
  endfor

  n_raw_files = results.(0)
  n_ok_files = results.(1)

  ; plot bar from OK files to total files over time
  !null = label_date(date_format='%Y-%m-%d')
  date_range = [jds[0], jds[-1]]
  files_range = [0, max([n_raw_files, n_ok_files])]

  month_ticks = mg_tick_locator(date_range, /months)
  n_months = n_elements(month_ticks)
  if (n_months eq 0L) then begin
    month_ticks = 1L
  endif else begin
    max_ticks = 7
    n_minor = n_months / max_ticks > 1
    month_ticks = month_ticks[0:*:n_minor]
  endelse

  window, xsize=1200, ysize=600, title='Bad files'
  plot, jds, n_ok_files, /nodata, $
        xstyle=1, xrange=date_range, xtickformat='label_date', $
        xtickv=month_ticks, xticks=n_elements(month_ticks) - 1L, xminor=n_minor, $
        xtitle='Date', $
        ystyle=1, yrange=files_range, ytitle='# of files', $
        title='Badfiles'
  for d = 0L, n_dates - 1L do begin
    plots, dblarr(2) + jds[d], [n_ok_files[d], n_raw_files[d]]
  endfor
end


; main-level example program

config_filename = filepath('kcor.production.cfg', $
                           subdir=['..', '..', 'kcor-config'], $
                           root=mg_src_root())

run = kcor_run('20130930', config_filename=config_filename)

db = mgdbmysql()
db->connect, config_filename=run->config('database/config_filename'), $
             config_section=run->config('database/config_section')

kcor_badfiles, db

obj_destroy, [db, run]

end
