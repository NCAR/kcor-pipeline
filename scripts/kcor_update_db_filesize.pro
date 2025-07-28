; docformat = 'rst'

pro kcor_update_db_filesize, date, config_filename=config_filename
  compile_opt strictarr

  run = kcor_run(date, mode='script', config_filename=config_filename)
  db = kcordbmysql(logger_name=run.logger_name)
  db->connect, config_filename=run->config('database/config_filename'), $
               config_section=run->config('database/config_section')

  obsday_id = mlso_obsday_insert(date, database=db, status=status, run=run, log_name=run.logger_name)

  ; find files on the given day
  query = 'select * from kcor_img where obs_day=%d order by date_obs'
  data = db->query(query, obsday_id, $
                   count=n_files, error=error, fields=fields, sql_statement=sql)

  web_basedir = run->config('results/archive_basedir')
  web_dir = filepath('', subdir=kcor_decompose_date(date), root=web_basedir)
  fullres_basedir = run->config('results/fullres_basedir')
  fullres_dir = filepath('', subdir=kcor_decompose_date(date), root=fullres_basedir)

  ; for each file, update filesize
  for f = 0L, n_files - 1L do begin
    if (data[f].filetype eq 1) then begin
      filename = filepath(data[f].file_name + '.gz', root=web_dir)
    endif else begin
      filename = filepath(data[f].file_name, root=fullres_dir)
    endelse
    if (file_test(filename, /regular)) then begin
      filesize = mg_filesize(filename)
      mg_log, '[%08d] %s: updating to %d bytes', $
              data[f].img_id, data[f].file_name, filesize, $
              /info, name=run.logger_name
      sql_cmd = 'update kcor_img set filesize=%d where img_id=%d'
      db->execute, sql_cmd, filesize, data[f].img_id
    endif else begin
      mg_log, '[%08d] %s: file does not exist', $
              data[f].img_id, data[f].file_name, $
              /info, name=run.logger_name
    endelse
  endfor

  obj_destroy, [db, run]
end


; main-level example program

date = '20240330'
config_basename = 'kcor.production.cfg'
config_filename = filepath(config_basename, subdir=['..', '..', 'kcor-config'], root=mg_src_root())
kcor_update_db_filesize, date, config_filename=config_filename

end
