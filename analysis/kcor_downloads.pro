; docformat = 'rst'

pro kcor_downloads
  compile_opt strictarr

  db = kcordbmysql()
  db->connect, config_filename='/home/mgalloy/.mysqldb', $
               config_section='mgalloy@databases'

  ; query = 'select tot_filesize, file, user_id from HAO.hao_download where instrument_id=3;'
  query = 'select * from HAO.hao_download where instrument_id=3;'
  results = db->query(query, count=n_rows)
  tokens = stregex(results.file, '20[[:digit:]]{6}', /extract)

  obj_destroy, db

  is_tarball = stregex(results.file, '\.(tar|tgz|tar\.gz|zip)$', /boolean)

  filesizes = hash()
  n_individual_files = hash()
  n_tarballs = hash()
  users = hash()
  for r = 0L, n_rows - 1L do begin
    date = tokens[r]
    if (date eq '') then continue

    if (filesizes->haskey(date)) then begin
      filesizes[date] += results[r].tot_filesize
    endif else begin
      filesizes[date] = results[r].tot_filesize
    endelse

    if (~n_tarballs->haskey(date)) then n_tarballs[date] = 0L
    if (~n_individual_files->haskey(date)) then n_individual_files[date] = 0L

    if (is_tarball[r]) then begin
      n_tarballs[date] += 1L
    endif else begin
      n_individual_files[date] += 1L
    endelse

    if (~users->haskey(date)) then users[date] = list()
    (users[date])->add, results[r].user_id

    ; if (date eq '20210515') then begin
    ;   print, results[r].download_id, $
    ;          mg_float2str(results[r].tot_filesize, places_sep=','), $
    ;          results[r].user_id, $
    ;          results[r].file, $
    ;          format='%d: %13s K user=%d %s '
    ; endif
  endfor

  special_days = hash()
  special_days_filename = 'special-days.txt'
  n_special_days = file_lines(special_days_filename)
  line = ''
  openr, lun, special_days_filename, /get_lun
  for i = 0L, n_special_days - 1L do begin
    readf, lun, line
    date = strmid(line, 0, 8)
    comment = strmid(line, 9)
    special_days[date] = comment
  endfor
  free_lun, lun

  dates_list = filesizes->keys()
  dates = dates_list->toArray()

  sort_indices = sort(dates)
  dates = dates[sort_indices]

  openw, lun, 'downloads.csv', /get_lun
  n_dates = n_elements(dates)
  printf, lun, 'date, total filesize, n_tarballs, n_individual_files, n_unique_users, comment'
  for d = 0L, n_dates - 1L do begin
    date_users = (users[dates[d]])->toArray()
    printf, lun, $
            dates[d], $
            ;mg_float2str(filesizes[dates[d]], places_sep=','), $
            filesizes[dates[d]], $
            n_tarballs[dates[d]], $
            n_individual_files[dates[d]], $
            n_elements(uniq(date_users, sort(date_users))), $
            special_days->hasKey(dates[d]) ? special_days[dates[d]] : '', $
            format='%s, %d, %d, %d, %d, \"%s\"'
  endfor
  free_lun, lun

  obj_destroy, [filesizes, n_individual_files, n_tarballs, dates_list, special_days]
  heap_free, users, /obj
end
