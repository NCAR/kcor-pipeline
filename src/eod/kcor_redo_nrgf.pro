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

  l2_dir = filepath('level2', subdir=date, root=run->config('processing/raw_basedir'))
  cd, current=current_dir
  cd, l2_dir

  ; remove existing NRGF from database and archive

  if (run->config('database/update')) then begin
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
    if (obj_valid(db)) then obj_destroy, db
  endif else begin
    mg_log, 'skipping updating database', name='kcor/eod', /info
  endelse

  ; remove NRGF files from level1, archive, nrgf, and cropped dirs

  date_parts = kcor_decompose_date(date)
  archive_dir = filepath('', subdir=date_parts, $
                         root=run->config('results/archive_basedir'))
  nrgf_dir    = filepath('', subdir=date_parts, $
                         root=run->config('results/nrgf_basedir'))
  cropped_dir = filepath('', subdir=date_parts, $
                         root=run->config('results/croppedgif_basedir'))

  if (run->config('realtime/distribute')) then begin
    dirs = [l2_dir, archive_dir, nrgf_dir, cropped_dir]
    names = ['level2', 'archive', 'NRGF', 'cropped']
  endif else begin
    dirs = [l2_dir]
    names = ['level2']
  endelse

  for d = 0L, n_elements(dirs) - 1L do begin
    ; delete any (L1, L1.5, or L2) NRGF files
    files = file_search(filepath('*_kcor_l*_nrgf*', root=dirs[d]), $
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

  if (~run->config('realtime/distribute')) then begin
    mg_log, 'not removing NRGF from archive, fullres, cropped dirs', $
            name='kcor/eod', /info
  endif

  ; create new NRGF files corresponding to average files
  average_files = file_search(filepath('*_kcor_l2_avg.fts.gz', $
                                       subdir=[date, 'level2'], $
                                       root=run->config('processing/raw_basedir')), $
                              count=n_average_files)
  if (n_average_files gt 0L) then begin
    nrgf_average_files = strarr(n_average_files)
    for f = 0L, n_average_files - 1L do begin
      mg_log, '%d/%d: creating NRGF for %s', $
              f + 1, n_average_files, file_basename(fits_filename), $
              name='kcor/eod', /info
      kcor_nrgf, average_files[f], run=run, /averaged, $
                 fits_filename=fits_filename, log_name='kcor/eod'
      nrgf_average_files[f] = fits_filename
      kcor_nrgf, average_files[f], run=run, /averaged, /cropped, log_name='kcor/eod'
    endfor
  endif

  ; create NRGF daily average file corresponding to daily average file
  daily_average_files = file_search(filepath('*_kcor_l2_extavg.fts.gz', $
                                             subdir=[date, 'level2'], $
                                             root=run->config('processing/raw_basedir')), $
                                    count=n_daily_average_files)
  for f = 0L, n_daily_average_files - 1L do begin   ; only 1 right now
    kcor_nrgf, daily_average_files[f], run=run, /averaged, /daily, log_name='kcor/eod'
    kcor_nrgf, daily_average_files[f], run=run, /averaged, /daily, /cropped, log_name='kcor/eod'
  endfor

  ; create NRGF 15-second files
  l2_files = file_search(filepath('*_kcor_l2.fts.gz', $
                                  subdir=[date, 'level2'], $
                                  root=run->config('processing/raw_basedir')), $
                        count=n_l2_files)
  for f = 0L, n_l2_files - 1L do begin
    kcor_nrgf, l2_files[f], run=run, log_name='kcor/eod'
    kcor_nrgf, l2_files[f], /cropped, run=run, log_name='kcor/eod'
  endfor

  ; zip new NRGF FITS files (including daily average)
  unzipped_nrgf_glob = '*_nrgf*.fts'
  unzipped_nrgf_files = file_search(unzipped_nrgf_glob, count=n_nrgf_files)
  if (n_nrgf_files gt 0L) then begin
    mg_log, 'zipping %d NRGF FITS files...', n_nrgf_files, $
            name='kcor/eod', /info
    gzip_cmd = string(run->config('externals/gzip'), unzipped_nrgf_glob, $
                      format='(%"%s %s")')
    spawn, gzip_cmd, result, error_result, exit_status=status
    if (status ne 0L) then begin
      mg_log, 'problem zipping NRGF FITS files with command: %s', gzip_cmd, $
              name='kcor/eod', /error
      mg_log, '%s', strjoin(error_result, ' '), name='kcor/eod', /error
    endif
  endif

  zipped_nrgf_files = unzipped_nrgf_files + '.gz'

  ; distribute new NRGF files
  if (run->config('realtime/distribute')) then begin
    if (n_nrgf_files gt 0L) then begin
      mg_log, 'copying %d NRGF files to archive dir', n_nrgf_files, $
              name='kcor/eod', /info
      file_copy, zipped_nrgf_files, archive_dir, /overwrite

      pos = strpos(zipped_nrgf_files[0], '_nrgf') + 5   ; '_nrgf' is 5 chars

      gif_filenames = strmid(zipped_nrgf_files, 0, pos) + '.gif'
      mg_log, 'copying %d NRGF files to NRGF dir', n_nrgf_files, $
              name='kcor/eod', /info
      for f = 0L, n_nrgf_files - 1L do begin
        if (file_test(gif_filenames[f])) then begin
          file_copy, gif_filenames[f], nrgf_dir, /overwrite
        endif
      endfor

      ; copy NRGF average cropped GIF files to cropped dir and NRGF average
      ; GIF files to NRGF dir
      mg_log, 'copying %d averaged NRGF GIF files to NRGF and cropped dirs', n_average_files, $
              name='kcor/eod', /info
      for f = 0L, n_average_files - 1L do begin
        pos = strpos(nrgf_average_files[f], '.fts')
        basename = strmid(nrgf_average_files[f], 0, pos)
        nrgf_average_gif_filename = basename + '.gif'
        nrgf_average_cropped_gif_filename = basename + '_cropped.gif'
        if (file_test(nrgf_average_gif_filename)) then begin
          file_copy, nrgf_average_gif_filename, nrgf_dir, /overwrite
        endif else begin
          mg_log, 'cannot find %s', nrgf_average_gif_filename, name='kcor/eod', /error
        endelse
        if (file_test(nrgf_average_cropped_gif_filename)) then begin
          file_copy, nrgf_average_cropped_gif_filename, cropped_dir, /overwrite
        endif else begin
          mg_log, 'cannot find %s', nrgf_average_cropped_gif_filename, name='kcor/eod', /error
        endelse
      endfor

      mg_log, 'copying %d NRGF files to cropped dir', n_nrgf_files, $
              name='kcor/eod', /info
      pos = strpos(zipped_nrgf_files[0], '_nrgf') + 5
      cropped_gif_filenames = strmid(zipped_nrgf_files, 0, pos) + '_cropped.gif'
      for f = 0L, n_nrgf_files - 1L do begin
        if (file_test(cropped_gif_filenames[f])) then begin
          file_copy, cropped_gif_filenames[f], cropped_dir, /overwrite
        endif else begin
          mg_log, 'cannot find %s', cropped_gif_filenames[f], name='kcor/eod', /error
        endelse
      endfor
    endif else begin
      mg_log, 'no NRGF files to distribute', name='kcor/eod', /info
    endelse
  endif else begin
    mg_log, 'not distributing NRGF files', name='kcor/eod', /info
  endelse

  ; add new NRGF files to database
  if (run->config('database/update')) then begin
    if (n_nrgf_files gt 0L) then begin
      obsday_index = mlso_obsday_insert(date, $
                                        run=run, $
                                        database=db, $
                                        status=db_status, $
                                        log_name='kcor/eod')
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
  if (run->config('realtime/distribute')) then begin
    nrgf_dailyavg_files = file_search('*nrgf_extavg.gif', $
                                      count=n_nrgf_dailyavg_files)
    if (n_nrgf_dailyavg_files gt 0L) then begin
      file_copy, nrgf_dailyavg_files, nrgf_dir
    endif else begin
      mg_log, 'no NRGF 10 min average GIF to distribute', name='kcor/eod', /info
    endelse

    nrgf_dailyavg_cropped_files = file_search('*nrgf_extavg_cropped.gif', $
                                              count=n_nrgf_dailyavg_cropped_files)
    if (n_nrgf_dailyavg_cropped_files gt 0L) then begin
      file_copy, nrgf_dailyavg_cropped_files, cropped_dir
    endif else begin
      mg_log, 'no NRGF 10 min average cropped GIFs to distribute', name='kcor/eod', /info
    endelse
  endif else begin
    mg_log, 'not distributing NRGF 10 min average GIFs', name='kcor/eod', /info
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