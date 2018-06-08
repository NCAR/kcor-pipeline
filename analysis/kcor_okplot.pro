; docformat = 'rst'

pro kcor_okplot, year, run=run, n_colors=n_colors
  compile_opt strictarr
;  on_error, 2

  if (n_elements(year) eq 0L) then message, 'year parameter must be present'

  db = mgdbmysql()
  db->connect, config_filename=run.database_config_filename, $
               config_section=run.database_config_section

  q = 'select n.obs_day, n.num_kcor_pb_fits from mlso_numfiles n where n.obs_day >= ''%s-01-01'' and n.obs_day < ''%04d-01-01'' and n.num_kcor_pb_fits > 0'
  days = db->query(q, year, long(year) + 1, $
                   fields=fields, $
                   status=status, error_message=error_msg, sql_statement=sql_cmd)

  if (status ne 0L) then begin
    mg_log, 'status %d', status, /error
    mg_log, error_msg, /error
    mg_log, 'cmd: %s', sql_cmd, /error
  endif

  dates = days.obs_day
  dates = strmid(dates, 0, 4) + strmid(dates, 5, 2) + strmid(dates, 8, 2)

  _n_colors = n_elements(n_colors) eq 0L ? 4L : n_colors
  n_days = n_elements(days)

  h = mg_histogram(days.num_kcor_pb_fits, min=0, max=3000, nbins=_n_colors, $
                   bin_indices=bi, locations=locs)
  bin_starts = locs[bi]
  bin_ends = locs[bi + 1]
  values = bi
  labels = strarr(_n_colors)
  for b = 0L, _n_colors - 1L do begin
    end_label = b eq _n_colors - 1 ? '' : strtrim(locs[b + 1], 2)
    labels[b] = string(locs[b], end_label, format='(%"%d - %s")')
  endfor

  tvlct, original_rgb, /get
  mg_loadct, 0, /brewer
  tvlct, rgb, /get
  tvlct, original_rgb

  rgb = congrid(rgb[16:207, *], _n_colors, 3)

  mg_calendar_plot, year, dates, values, start_on=0, $
                    color_table=rgb, $
                    labels=labels

  obj_destroy, db
end


; main-level example program

year = '2018'
date = year + '0101'

config_filename = filepath('kcor.mgalloy.mahi.analysis.cfg', $
                           subdir=['..', 'config'], $
                           root=mg_src_root())

run = kcor_run(date, config_filename=config_filename)

kcor_okplot, year, run=run, n_colors=6

end
