; docformat = 'rst'

;+
; Redo the NRGF that were done during the realtime processing, now using
; averaged files.
;
; :Params:
;   date : in, required, type=date
;     date in the form 'YYYYMMDD' to process
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;-
pro kcor_redo_nrgf, date, run=run
  compile_opt strictarr

  mg_log, 'Redoing NRGFs', name='kcor/eod', /info

  l1_dir = filepath('level1', subdir=date, root=run.raw_basedir)
  cd, current=current_dir
  cd, l1_dir

  ; remove existing NRGF from database and archive

  if (run.update_database) then begin
    obsday_index = mlso_obsday_insert(date, $
                                      run=run, $
                                      database=db, $
                                      status=db_status, $
                                      log_name='kcor/eod')

    if (db_status eq 0L) then begin
      kcor_nrgf_clear, run=run, database=db, obsday_index=obsday_index, $
                       log_name='kcor/eod'
    endif else begin
      mg_log, 'error connecting to database', name='kcor/eod', /warn
      goto, done
    endelse
  endif else begin
    mg_log, 'skipping updating database', name='kcor/eod', /info
  endelse

  ; remove NRGF files from level1, archive, nrgf, and cropped dirs

  date_parts = kcor_decompose_date(date)
  archive_dir = filepath('', subdir=date_parts, root=run.archive_basedir)
  nrgf_dir    = filepath('', subdir=date_parts, root=run.nrgf_basedir)
  cropped_dir = filepath('', subdir=date_parts, root=run.croppedgif_basedir)

  if (run.distribute) then begin
    dirs = [l1_dir, archive_dir, nrgf_dir, cropped_dir]
    names = ['level1', 'archive', 'NRGF', 'cropped']
  endif else begin
    dirs = [l1_dir]
    names = ['level1']
  endelse

  for d = 0L, n_elements(dirs) - 1L do begin
    files = file_search(filepath('*_kcor_l1_nrgf*', root=dirs[d]), $
                        count=n_files)
    mg_log, 'removing %d NRGF files from %s dir', n_files, names[d], $
            name='kcor/eod', /info
    for f = 0L, n_files - 1L do begin
      mg_file_delete, files[f], status=error, message=message
      if (error ne 0L) then begin
        mg_log, 'error deleting %s', files[f], name='kcor/eod', /error
        mg_log, message, name='kcor/eod', /error
        goto, done
      endif
    endfor
  endfor

  if (~run.distribute) then begin
    mg_log, 'not removing NRGF from archive, fullres, cropped dirs', $
            name='kcor/eod', /info
  endif

  ; create new NRGF files corresponding to average files
  average_files = file_search(filepath('*_kcor_l1_avg.fts.gz', $
                                       subdir=[date, 'level1'], $
                                       root=run.raw_basedir), $
                              count=n_average_files)
  for f = 0L, n_average_files - 1L do begin
    kcor_nrgf, average_files[f], run=run, /averaged, log_name='kcor/eod'
    kcor_nrgf, average_files[f], run=run, /averaged, /cropped, log_name='kcor/eod'
  endfor

  ; create NRGF daily average file corresponding to daily average file
  daily_average_files = file_search(filepath('*_kcor_l1_dailyavg.fts.gz', $
                                             subdir=[date, 'level1'], $
                                             root=run.raw_basedir), $
                                    count=n_daily_average_files)
  for f = 0L, n_daily_average_files - 1L do begin   ; only 1 right now
    kcor_nrgf, daily_average_files[f], run=run, /averaged, /daily, log_name='kcor/eod'
    kcor_nrgf, daily_average_files[f], run=run, /averaged, /daily, /cropped, log_name='kcor/eod'
  endfor

  ; zip new NRGF FITS files (including daily average)
  unzipped_nrgf_glob = '*_nrgf*.fts'
  unzipped_nrgf_files = file_search(unzipped_nrgf_glob, count=n_nrgf_files)
  if (n_nrgf_files gt 0L) then begin
    mg_log, 'zipping %d NRGF FITS files...', n_nrgf_files, $
            name='kcor/eod', /info
    gzip_cmd = string(run.gzip, unzipped_nrgf_glob, format='(%"%s %s")')
    spawn, gzip_cmd, result, error_result, exit_status=status
    if (status ne 0L) then begin
      mg_log, 'problem zipping NRGF FITS files with command: %s', gzip_cmd, $
              name='kcor/eod', /error
      mg_log, '%s', strjoin(error_result, ' '), name='kcor/eod', /error
    endif
  endif

  zipped_nrgf_files = unzipped_nrgf_files + '.gz'

  ; distribute new NRGF files
  if (run.distribute) then begin
    if (n_nrgf_files gt 0L) then begin
      mg_log, 'copying %d NRGF files to archive dir', n_nrgf_files, $
              name='kcor/eod', /info
      file_copy, zipped_nrgf_files, archive_dir, /overwrite

      pos = strpos(zipped_nrgf_files[0], '_nrgf') + 5   ; '_nrgf' is 5 chars

      mg_log, 'copying %d NRGF files to NRGF dir', n_nrgf_files, $
              name='kcor/eod', /info
      file_copy, strmid(zipped_nrgf_files, 0, pos) + '.gif', nrgf_dir, /overwrite

      mg_log, 'copying %d NRGF files to cropped dir', n_nrgf_files, $
              name='kcor/eod', /info
      file_copy, strmid(zipped_nrgf_files, 0, pos) + '_cropped.gif', cropped_dir, $
                 /overwrite
    endif else begin
      mg_log, 'no NRGF files to distribute', name='kcor/eod', /info
    endelse
  endif else begin
    mg_log, 'not distributing NRGF files', name='kcor/eod', /info
  endelse

  ; add new NRGF files to database
  if (run.update_database) then begin
    if (n_nrgf_files gt 0L) then begin
      mg_log, 'adding %d NRGF files to database', n_nrgf_files, $
              name='kcor/eod', /info
      kcor_img_insert, date, unzipped_nrgf_files, run=run, database=db, $
                       obsday_index=obsday_index, log_name='kcor/eod'
    endif else begin
      mg_log, 'no NRGF files to add to database', name='kcor/eod', /info
    endelse
  endif else begin
    mg_log, 'not adding NRGF files to database', name='kcor/eod', /info
  endelse

  ; distribute NRGF daily average GIFs
  if (run.distribute) then begin
    nrgf_dailyavg_files = file_search('*nrgf_dailyavg.gif', $
                                      count=n_nrgf_dailyavg_files)
    if (n_nrgf_dailyavg_files gt 0L) then begin
      file_copy, nrgf_dailyavg_files, nrgf_dir
    endif else begin
      mg_log, 'no NRGF daily average GIF to distribute', name='kcor/eod', /info
    endelse

    nrgf_dailyavg_cropped_files = file_search('*nrgf_dailyavg_cropped.gif', $
                                              count=n_nrgf_dailyavg_cropped_files)
    if (n_nrgf_dailyavg_cropped_files gt 0L) then begin
      file_copy, nrgf_dailyavg_cropped_files, cropped_dir
    endif else begin
      mg_log, 'no NRGF daily average cropped GIFs to distribute', name='kcor/eod', /info
    endelse
  endif else begin
    mg_log, 'not distributing NRGF daily average GIFs', name='kcor/eod', /info
  endelse

  done:
  cd, current_dir
  if (obj_valid(db)) then obj_destroy, db
end


; main-level example program

date = '20180208'
config_filename = filepath('kcor.mgalloy.mahi.latest.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)

kcor_redo_nrgf, date, run=run

end