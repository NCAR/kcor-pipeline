; docformat = 'rst'

;+
; Find all the files in the `kcor_eng` database table in the `raw/level2`
; directory. The processed files stored on dawn are on the dates:
;
; - 20130930-20140101
; - 20200101-20210101
; - 20220101-
;-
pro kcor_check_data, run, db
  compile_opt strictarr

  level_dirs = hash('L1', 'level1', 'L1.5', 'level15', 'L2', 'level2', 'L0', 'level0')
  archive_dir = run->config('results/archive_basedir')

  n_missing_processed_files = 0L
  n_missing_archive_files = 0L
  openw, lun, 'kcor.missing.log', /get_lun

  ; total number of FITS files in kcor_img
  n_total_files = db->query('select count(*) from kcor_img where filetype=1;')
  n_total_files = n_total_files.(0)

  n_processed_files = 1L
  batch = 0L
  batch_size = 10000L
  while (n_processed_files gt 0L) do begin
    sql_query = 'select file_name, kcor_level.level, mlso_numfiles.obs_day from kcor_img join kcor_level on kcor_img.level=kcor_level.level_id join mlso_numfiles on kcor_img.obs_day=mlso_numfiles.day_id where filetype=1 order by file_name limit %d offset %d;'
    processed_files = db->query(sql_query, batch_size, batch * batch_size, $
                                error_message=error_message, $
                                status=status, $
                                sql_statement=sql_statement, $
                                count=n_processed_files)
    if (status ne 0L) then begin
      print, status, format='database query failed with status: %d'
      print, error_message, format='error message: %s'
      print, sql_statement, format='SQL statement: %s'
      return
    endif

    print, n_processed_files, format='new query retrieved %d files'

    for f = 0L, n_processed_files - 1L do begin
      if (f mod 1000 eq 0) then begin
        print, f + batch * batch_size, $
               n_total_files, $
               100.0 * (f + batch * batch_size) / n_total_files, $
               format='%07d/%07d: %0.2f%% done'
      endif
      file = processed_files[f]
      date = file.obs_day.replace('-', '')

      ; need to update date/time before getting raw base directory
      run.date = date
      run.time = '000000'
      processing_dir = run->config('processing/raw_basedir')

      level = level_dirs[file.level]
      path = filepath(file.file_name + '*', subdir=[date, level], root=processing_dir)
      if (~file_test(path, /regular)) then begin
        ; print, file.file_name, format='%s not found [processing]'
        printf, lun, file.file_name, format='%s not found [processing]'
        n_missing_processed_files += 1L
      endif
      path = filepath(file.file_name + '*', subdir=kcor_decompose_date(date), root=archive_dir)
      if (~file_test(path, /regular)) then begin
        ; print, file.file_name, level, format='%s not found [%s] [archive]'
        printf, lun, file.file_name, format='%s not found [archive]'
        n_missing_archive_files += 1L
      endif
    endfor
    batch += 1L
    flush, lun
  endwhile
  free_lun, lun

  print, n_missing_processed_files, format='%d missing processed files'
  print, n_missing_archive_files, format='%d missing archive files'

  openw, lun, 'kcor.raw-missing.log', /get_lun

  n_missing_raw_files = 0L

  n_total_raw_files = db->query('select count(*) from kcor_raw;')
  n_total_raw_files = n_total_raw_files.(0)
  n_processed_files = 1L
  batch = 0L
  while (n_raw_files gt 0L) do begin
    sql_query = 'select file_name, mlso_numfiles.obs_day from kcor_raw join mlso_numfiles on kcor_raw.obs_day=mlso_numfiles.day_id limit %d offset %d;'
    raw_files = db->query(sql_query, batch_size, batch, batch_size, count=n_raw_files)

    for f = 0L, n_raw_files - 1L do begin
      if (f mod 1000 eq 0) then begin
        print, f + batch * batch_size, $
               n_total_raw_files, $
               100.0 * (f + batch * batch_size) / n_total_raw_files, $
               format='%07d/%07d: %0.2f%% done'
      endif

      file = raw_files[f]
      date = file.obs_day.replace('-', '')

      run.date = date
      run.time = '000000'

      raw_dir = run->config('processing/raw_basedir')
      path = filepath(file.file_name, subdir=[date, 'level0'], root=raw_dir)
      if (~file_test(path, /regular)) then begin
        printf, lun, file.file_name, format='%s not found'
        n_missing_raw_files += 1L
      endif
    endfor
    flush, lun
    batch += 1L
  endwhile

  free_lun, lun

  print, n_missing_raw_files, format='%d missing raw files'

  obj_destroy, level_dirs
end


; main-level example program

start_date = '20130930'

config_basename = 'kcor.reprocess.cfg'
config_filename = filepath(config_basename, $
    subdir=['..', '..', 'kcor-config'], $
    root=mg_src_root())

run = kcor_run(start_date, config_filename=config_filename, mode='find_missing')

db = kcordbmysql(logger_name=log_name)
db->connect, config_filename=run->config('database/config_filename'), $
             config_section=run->config('database/config_section'), $
             status=status, error_message=error_message

kcor_check_data, run, db

obj_destroy, [run, db]

end
