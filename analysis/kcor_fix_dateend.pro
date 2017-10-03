; docformat = 'rst'

pro kcor_fix_dateend_file, results, r, filename, db
  compile_opt strictarr

  header = headfits(filename)
  date_end = sxpar(header, 'DATE-END')
  normalized_date_end = kcor_normalize_datetime(date_end, error=error)

  mg_log, 'found %s', filename, /debug

  if (error gt 0L) then begin
    ; TODO: should try to add 15 sec to DATE-OBS?
    mg_log, 'cannot normalize %s', date_end, /error
  endif else begin
    mg_log, '[img_id=%d] %s -> %s', $
            results[r].img_id, results[r].date_end, normalized_date_end, $
            /debug

    sql_cmd = string(date_end, results[r].img_id, $
                   format='(%"UPDATE kcor_img SET date_end=''%s'' WHERE img_id=%d")')
    db->execute, sql_cmd, status=status, error_message=error_message
  endelse
end


pro kcor_fix_dateend
  compile_opt strictarr

  mg_log, logger=logger
  logger->setProperty, filename='fix-date-end.log'

  _config_filename = n_elements(config_filename) eq 0L $
                       ? filepath('.mysqldb', root=getenv('HOME')) $
                       : config_filename

  config = mg_read_config(_config_filename)
  config->getProperty, sections=sections
  _section = sections[0]

  db = mgdbmysql()
  db->connect, config_filename=_config_filename, $
               config_section=_section, $
               error_message=error_message
  db->getProperty, host_name=host, connected=connected

  days = db->query('select * from mlso_numfiles')

  sql_query = 'select kcor_img.* from kcor_img, mlso_numfiles where date_end = ''0000-00-00 00:00:00'' order by mlso_numfiles.obs_day'

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
    mg_log, '## Looking for %d/%d [%d]: %s...', r + 1, n_results, n_found, basename, /info
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

          kcor_fix_dateend_file, results, r, filename1, db

          break
        endif

        filename2 = string(year, date, basename, exts[e], format=loc2)
        if (file_test(filename2)) then begin
          found = 1B
          n_found += 1
        
          kcor_fix_dateend_file, results, r, filename2, db

          break
        endif


        filename3 = string(i, date, basename, exts[e], format=loc3)
        if (file_test(filename3)) then begin
          found = 1B
          n_found += 1

          kcor_fix_dateend_file, results, r, filename3, db

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
