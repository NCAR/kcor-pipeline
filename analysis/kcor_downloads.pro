; docformat = 'rst'

pro kcor_downloads
  compile_opt strictarr

  db = kcordbmysql()
  db->connect, config_filename='/home/mgalloy/.mysqldb', $
               config_section='mgalloy@databases'
  
  query = 'select tot_filesize, file from HAO.hao_download where instrument_id=3;'
  results = db->query(query, count=n_rows)
  tokens = stregex(results.file, '20[[:digit:]]{6}', /extract)

  obj_destroy, db

  filesizes = hash()
  for r = 0L, n_rows - 1L do begin
    if (tokens[r] eq '') then continue

    if (filesizes->haskey(tokens[r])) then begin
      filesizes[tokens[r]] += results[r].tot_filesize
    endif else begin
      filesizes[tokens[r]] = results[r].tot_filesize
    endelse
  endfor
  dates_list = filesizes->keys()
  sizes_list = filesizes->values()
  dates = dates_list->toArray()
  sizes = sizes_list->toArray()

  sort_indices = sort(dates)
  dates = dates[sort_indices]
  sizes = sizes[sort_indices]

  n_dates = n_elements(dates)
  for d = 0L, n_dates - 1L do begin
    print, dates[d], mg_float2str(sizes[d], places_sep=','), format='%s: %12s K'
  endfor

  obj_destroy, [filesizes, dates_list, sizes_list]
end
