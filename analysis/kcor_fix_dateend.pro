; docformat = 'rst'

pro kcor_fix_dateend_file, results, r, filename, db, table
  compile_opt strictarr

  header = headfits(filename)
  date_end = sxpar(header, 'DATE-END')
  normalized_date_end = kcor_normalize_datetime(date_end, error=error)

  mg_log, 'found %s with DATE-END=''%s''', filename, date_end, /debug

  if (error gt 0L) then begin
    date_obs = sxpar(header, 'DATE-OBS')
    normalized_date_end = kcor_normalize_datetime(date_obs, error=error, /add_15)

    if (error gt 0L) then begin
      mg_log, 'cannot normalize %s', date_end, /error
      return
    endif
  endif

  tags = tag_names(results[r])
  ind = where(tags eq strupcase(table) + '_ID', count)
  id_index = ind[0]

  mg_log, '[%s_id=%d] %s -> %s', $
          table, results[r].(id_index), results[r].date_end, normalized_date_end, $
          /debug

  sql_cmd = string(table, normalized_date_end, file_basename(filename, '.gz'), $
                   format='(%"UPDATE kcor_%s SET date_end=''%s'' WHERE file_name=''%s''")')
  mg_log, sql_cmd, /debug
  db->execute, sql_cmd, $
               status=status, error_message=error_message, $
               n_affected_rows=n_affected_rows
  mg_log, 'status=%d, msg=%s', status, error_message, /info
  mg_log, 'n_affected_rows=%d', n_affected_rows, /info
end


pro kcor_fix_dateend, table
  compile_opt strictarr

  _table = n_elements(table) eq 0L ? 'img' : table

  mg_log, logger=logger
  logger->setProperty, filename=string(_table, format='(%"fix-date-end-%s.log")')

  _config_filename = n_elements(config_filename) eq 0L $
                       ? filepath('.mysqldb', root=getenv('HOME')) $
                       : config_filename

  config = mg_read_config(_config_filename)

  db = mgdbmysql()
  db->connect, config_filename=_config_filename, $
               config_section='pipeline@databases', $
               error_message=error_message
  mg_log, '%s', error_message, /info

  db->getProperty, host_name=host, connected=connected

  days = db->query('select * from mlso_numfiles')

  sql_query = string(_table, _table, format='(%"select kcor_%s.* from kcor_%s, mlso_numfiles where date_end = ''0000-00-00 00:00:00'' order by mlso_numfiles.obs_day")')

  mg_log, 'ready to query...', /info

  results = db->query(sql_query, sql_statement=sql_statement, error=error, fields=fields)

  loc1 = '(%"/hao/mlsodata%d/Data/KCor/raw/%s/%s/level0/%s_kcor.fts%s")'
  loc2 = '(%"/hao/mahidata1/Data/KCor/raw/%s/%s/level0/%s_kcor.fts%s")'
  loc3 = '(%"/hao/mlsodata%d/Data/KCor/raw/%s/level0/%s_kcor.fts%s")'

  exts = ['', '.gz']
  n_found = 0L
  n_results = n_elements(results)
  for r = 0L, n_results - 1L do begin
    basename = strmid(results[r].file_name, 0, 15)
    mg_log, 'Filename %s', results[r].file_name, /debug
    mg_log, 'Looking for %d/%d [%d]: %s...', r + 1, n_results, n_found, basename, /info
    year = strmid(basename, 0, 4)

    ind = where(results[r].obs_day eq days.day_id, count)
    date = (days[ind[0]]).obs_day
    date = strmid(date, 0, 4) + strmid(date, 5, 2) + strmid(date, 8, 2)

    found = 0B
    for i = 1, 3 do begin
      for e = 0, 1 do begin
        filename1 = string(i, year, date, basename, exts[e], format=loc1)
        if (file_test(filename1)) then begin
          found = 1B
          n_found += 1

          kcor_fix_dateend_file, results, r, filename1, db, _table

          break
        endif

        filename2 = string(year, date, basename, exts[e], format=loc2)
        if (file_test(filename2)) then begin
          found = 1B
          n_found += 1
        
          kcor_fix_dateend_file, results, r, filename2, db, _table

          break
        endif


        filename3 = string(i, date, basename, exts[e], format=loc3)
        if (file_test(filename3)) then begin
          found = 1B
          n_found += 1

          kcor_fix_dateend_file, results, r, filename3, db, _table

          break
        endif
      endfor
      if (found) then break
    endfor

    if (~found) then mg_log, '%s not found', basename, /warn
  endfor

  mg_log, '%d/%d rows fixed', n_found, n_results, /info

  obj_destroy, [db, config]
end
