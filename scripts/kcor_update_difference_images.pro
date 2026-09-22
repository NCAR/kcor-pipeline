; docformat = 'rst'

;+
; Update rolling 28-day synoptic maps.
;
; :Params:
;   date : in, required, type=string
;     date in the form YYYYMMDD
;
; :Keywords:
;   config_filename : in, required, type=string
;     config filename
;-
pro kcor_update_difference_images, date, config_filename=config_filename
  compile_opt strictarr

  logger_name = 'kcor/eod'

  run = kcor_run(date, config_filename=config_filename)
  db = kcordbmysql()
  db->connect, config_filename=run->config('database/config_filename'), $
               config_section=run->config('database/config_section')

  archive_dir = filepath('', $
                         subdir=kcor_decompose_date(date), $
                         root=run->config('results/archive_basedir'))
  fullres_dir = filepath('', $
                         subdir=kcor_decompose_date(date), $
                         root=run->config('results/fullres_basedir'))
  l2_dir = filepath('level2', $
                    subdir=date, $
                    root=run->config('processing/raw_basedir'))

  ; remove difference images from web archive, fullres, and level2 dir

  old_diff_files = file_search(filepath('*kcor_minus*', root=archive_dir), $
                               count=n_old_diff_files)
  mg_log, 'removing %d old web archive diff files...', $
          n_old_diff_files, name=logger_name, /info
  for f = 0L, n_old_diff_files - 1L do begin
    file_delete, old_diff_files[f]
  endfor

  old_diff_files = file_search(filepath('*kcor_minus*', root=fullres_dir), $
                               count=n_old_diff_files)
  mg_log, 'removing %d old fullres diff files...', $
          n_old_diff_files, name=logger_name, /info
  for f = 0L, n_old_diff_files - 1L do begin
    file_delete, old_diff_files[f]
  endfor

  old_diff_files = file_search(filepath('*minus*', root=l2_dir), $
                               count=n_old_diff_files)
  mg_log, 'removing %d old level2 diff files...', n_old_diff_files, $
          name=logger_name, /info
  for f = 0L, n_old_diff_files - 1L do begin
    file_delete, old_diff_files[f]
  endfor

  ; remove difference images from database

  obsday_id = mlso_obsday_insert(date, $
                                 run=run, $
                                 database=db, $
                                 status=status, $
                                 log_name=log_name)

  mg_log, 'obsday_id %d for %s', obsday_id, date, $
          name=logger_name, /debug
  q = 'select producttype_id from mlso_producttype where producttype=''pbdiff'' limit 1;'
  results = db->query(q, status=status)
  producttype_id = results[0].producttype_id
  mg_log, 'product type ID for ''pbdiff'': %d', producttype_id, $
          name=logger_name, /debug

  q = 'delete from kcor_img where obs_day=%d and producttype=%d'
  db->execute, q, obsday_id, producttype_id, status=status

  l2_files = file_search(filepath('*_l2_pb.fts.gz', $
                                  subdir=[date, 'level2'], $
                                  root=run->config('processing/raw_basedir')), $
                      count=n_l2_files)

  kcor_create_differences, date, l2_files, run=run

  obj_destroy, [db, run]
end
