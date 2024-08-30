; docformat = 'rst'

;+
; Remove files that potentially had moving hardware. This is defined as the
; first "ok" file after a "dev" file.
;
; :Keywords:
;   run : in, required, type=object
;     KCor run object
;-
pro kcor_remove_moving_files, run=run
  compile_opt strictarr

  raw_rootdir     = run->config('processing/raw_basedir')
  web_rootdir     = run->config('results/archive_basedir')
  fullres_rootdir = run->config('results/fullres_basedir')
  cropped_rootdir = run->config('results/croppedgif_basedir')

  ; create list of all level 0 filenames and status
  oka_filename = filepath('oka.ls', subdir=[run.date, 'q'], root=raw_rootdir)
  n_oka_files = file_test(oka_filename, /regular) eq 0L ? 0L : file_lines(oka_filename)
  oka_files = n_oka_files eq 0L ? !null : strarr(n_oka_files)
  oka_status = n_oka_files eq 0L ? !null : (strarr(n_oka_files) + 'oka')
  if (n_oka_files gt 0L) then begin
    openr, lun, oka_filename, /get_lun
    readf, lun, oka_files
    free_lun, lun
  endif

  dev_filename = filepath('dev.ls', subdir=[run.date, 'q'], root=raw_rootdir)
  n_dev_files = file_test(dev_filename, /regular) eq 0L ? 0L : file_lines(dev_filename)
  dev_files = n_dev_files eq 0L ? !null : strarr(n_dev_files)
  dev_status = n_dev_files eq 0L ? !null : (strarr(n_dev_files) + 'dev')
  if (n_dev_files gt 0L) then begin
    openr, lun, dev_filename, /get_lun
    readf, lun, dev_files
    free_lun, lun
  endif

  n_files = n_oka_files + n_dev_files
  l0_basename = [oka_files, dev_files]
  l0_status = [oka_status, dev_status]

  sort_indices = sort(l0_basename)
  l0_basename = l0_basename[sort_indices]
  l0_status = l0_status[sort_indices]

  if (run->config('database/update')) then begin
    db = kcordbmysql(logger_name=log_name)
    db->connect, config_filename=run->config('database/config_filename'), $
                 config_section=run->config('database/config_section'), $
                 status=status, error_message=error_message
    if (status eq 0L) then begin
      obsday_index = mlso_obsday_insert(run.date, $
                                        run=run, $
                                        database=db, $
                                        status=db_status, $
                                        log_name=run.logger_name)
    endif else begin
      mg_log, 'failed to connect to database', name=run.logger_name, /error
      mg_log, '%s', error_message, name=run.logger_name, /error
      if (obj_valid(db)) then obj_destroy, db
    endif
  endif

  after_dev_sequence = 0B
  n_files_removed = 0L
  for f = 0L, n_files - 1L do begin
    if (l0_status[f] eq 'dev') then after_dev_sequence = 1B
    if (l0_status[f] eq 'ok' && after_dev_sequence) then begin
      n_files_removed += 1L
      kcor_remove_okfile, l0_basename[f], run.date, db, obsday_index, $
                          raw_rootdir, web_rootdir, fullres_rootdir, cropped_rootdir, $
                          logger_name=run.logger_name
      after_dev_sequence = 0B
    endif
  endfor

  done:
  if (obj_valid(db)) then obj_destroy, db

  mg_log, 'removed %d level 0 files', n_files_removed, name=run.logger_name, /warn
end
