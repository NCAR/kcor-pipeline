; docformat = 'rst'

pro kcor_swplot, year, run=run
  compile_opt strictarr
  on_error, 2

  if (n_elements(year) eq 0L) then message, 'year parameter must be present'

  db = mgdbmysql()
  db->connect, config_filename=run.database_config_filename, $
               config_section=run.database_config_section

  q = 'select n.day_id, n.obs_day, e.kcor_sw_id from mlso_numfiles n, kcor_eng e where n.obs_day >= ''%s-01-01'' and n.obs_day < ''%04d-01-01'' and e.obs_day = n.day_id'
  eng = db->query(q, year, long(year) + 1, $
                   fields=fields, $
                   status=status, error_message=error_msg, sql_statement=sql_cmd)

  if (status ne 0L) then begin
    mg_log, 'status %d', status, /error
    mg_log, error_msg, /error
    mg_log, 'cmd: %s', sql_cmd, /error
  endif

  q = 'select s.sw_id, s.sw_version from kcor_sw s'
  sw_versions = db->query(q, $
                          status=status, error_message=error_msg, sql_statement=sql_cmd)

  if (status ne 0L) then begin
    mg_log, 'status %d', status, /error
    mg_log, error_msg, /error
    mg_log, 'cmd: %s', sql_cmd, /error
  endif

  day_ids = eng.day_id
  day_ids_indices = uniq(day_ids, sort(day_ids))
  day_ids = day_ids[day_ids_indices]

  dates = (eng.obs_day)[day_ids_indices]

  chronological_indices = sort(dates)

  n_dates = n_elements(dates)

  versions = strarr(n_dates)
  for d = 0L, n_elements(day_ids_indices) - 1L do begin
    i = day_ids_indices[d]
    id = eng[i].kcor_sw_id
    if (id eq 0L) then versions[d] = '' else begin
      ind = where(sw_versions.sw_id eq id, count)
      if (count eq 0L) then versions[d] = '' else begin
        versions[d] = (sw_versions[ind[0]]).sw_version
      endelse
    endelse
  endfor

  day_ids = day_ids[chronological_indices]
  dates = dates[chronological_indices]
  versions = versions[chronological_indices]

  dates = strmid(dates, 0, 4) + strmid(dates, 5, 2) + strmid(dates, 8, 2)

  mg_calendar_plot, year, dates, versions, start_on=0

  obj_destroy, db
end


; main-level example program

year = '2018'
date = year + '0101'

config_filename = filepath('kcor.mgalloy.mahi.analysis.cfg', $
                           subdir=['..', 'config'], $
                           root=mg_src_root())

run = kcor_run(date, config_filename=config_filename)

kcor_swplot, year, run=run

end
