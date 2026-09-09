; docformat = 'rst'

pro kcor_update_process, db
  compile_opt strictarr

  q = 'select obs_day, file_name, kcor_sw_id from kcor_eng group by obs_day order by date_obs;'
  results = db->query(q, count=n_days)
  for d = 0L, n_days - 1L do begin
    s = 'insert into kcor_process (obsday_id, kcor_sw_id, date_processed, status) values (%d, %d, NULL, ''processed'')'
    db->execute, s, results[d].obs_day, results[d].kcor_sw_id
  endfor
end


; main-level example program

start_date = '20130930'
config_basename = 'kcor.production.cfg'
config_filename = filepath(config_basename, $
                           subdir=['..', '..', 'kcor-config'], $
                           root=mg_src_root())
run = kcor_run(start_date, config_filename=config_filename, mode='update_process')

db = kcordbmysql()
db->connect, config_filename=run->config('database/config_filename'), $
             config_section=run->config('database/config_section')

kcor_update_process, db

obj_destroy, [db, run]

end

