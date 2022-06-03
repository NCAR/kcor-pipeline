; docformat = 'rst'

pro kcor_db_heights, start_date, filename
  compile_opt strictarr

  config_basename = 'kcor.production.cfg'
  config_filename = filepath(config_basename, $
                             subdir=['..', 'config'], $
                             root=mg_src_root())
  run = kcor_run(start_date, config_filename=config_filename)

  db = kcordbmysql()
  db->connect, config_filename=run->config('database/config_filename'), $
               config_section=run->config('database/config_section')

  _start_date = strjoin(kcor_decompose_date(start_date), '-')
  results = db->query('select * from kcor_sci where date_obs > ''%s'' order by date_obs', $
                      _start_date, $
                      count=n_rows)

  openw, lun, filename, /get_lun
  for r = 0L, n_rows - 1L do begin
    if (n_elements(*results[r].r111) eq 0L) then continue
    if (n_elements(*results[r].r13) eq 0L) then continue
    if (n_elements(*results[r].r18) eq 0L) then continue
    r111 = mean(float(*results[r].r111, 0, 720))
    r13  = mean(float(*results[r].r13, 0, 720))
    r18  = mean(float(*results[r].r18, 0, 720))
    printf, lun, $
            strmid(results[r].date_obs, 0, 10), r111, r13, r18, $
            format='(%"%-10s  %0.5g  %0.5g  %0.5g")'
  endfor
  free_lun, lun
  obj_destroy, db
  obj_destroy, run
end


; main-level example

filename = 'kcor-heights.txt'
kcor_db_heights, '20170101', filename

n_lines = file_lines(filename)
dates = dblarr(n_lines)
r111 = fltarr(n_lines)
r13  = fltarr(n_lines)
r18  = fltarr(n_lines)

openr, lun, filename, /get_lun
line = ''
for i = 0L, n_lines - 1L do begin
  readf, lun, line
  tokens = strsplit(line, /extract)
  date = tokens[0]
  year = strmid(date, 0, 4)
  month = strmid(date, 5, 2)
  day = strmid(date, 8, 2)
  dates[i] = julday(month, day, year)
  r111[i] = float(tokens[1])
  r13[i] = float(tokens[2])
  r18[i] = float(tokens[3])
endfor

free_lun, lun

end

