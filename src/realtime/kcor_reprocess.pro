; docformat = 'rst'

;+
; This is the top-level reprocessing pipeline routine.
;
; :Params:
;   date : in, required, type=string
;     date to process in the form "YYYYMMDD"
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;   error : out, optional, type=long
;     set to named variable to retrieve the status of the reprocessing, 0L
;     indicates no error
;-
pro kcor_reprocess, date, run=run, error=error
  compile_opt strictarr

  ; catch and log any crashes
  catch, error
  if (error ne 0L) then begin
    catch, /cancel
    mg_log, /last_error, name='kcor/reprocess', /critical
    goto, done
  endif

  case 1 of
    run.reprocess: mg_log, 'prepping for reprocessing', name='kcor/reprocess', /info
    run.update_processing: mg_log, 'prepping for updating', name='kcor/reprocess', /info
    else: begin
        mg_log, 'exiting, neither reprocessing nor udpating', $
                name='kcor/reprocess', /error
        goto, done
      end
  endcase

  ; zip any unzipped raw files
  unzipped_raw_fits_glob = filepath('*_kcor.fts', $
                                    subdir=[date, 'level0'], $
                                    root=run.raw_basedir)
  unzipped_raw_files = file_search(unzipped_raw_fits_glob, $
                                   count=n_unzipped_raw_files)
  if (n_unzipped_raw_files gt 0L) then begin
    mg_log, 'zipping %d L0 FITS files', n_unzipped_raw_files, $
            name='kcor/reprocess', /info
    gzip_cmd = string(run.gzip, unzipped_raw_fits_glob, format='(%"%s %s")')
    spawn, gzip_cmd, result, error_result, exit_status=status
    if (status ne 0L) then begin
      mg_log, 'problem zipping files with command: %s', gzip_cmd, $
                name='kcor/reprocess', /error
      mg_log, '%s', stjoin(error_result, ' '), name='kcor/reprocess', /error
    endif
  endif else begin
    mg_log, 'no L0 FITS files to zip', name='kcor/reprocess', /info
  endelse

  ; move level 0 FITS files and t1/t2 logs up a level
  raw_files = file_search(filepath('*_kcor.fts.gz', $
                                   subdir=[date, 'level0'], $
                                   root=run.raw_basedir), $
                          count=n_raw_files)
  if (n_raw_files gt 0L) then begin
    mg_log, 'moving %d raw files from level0/ to top-level', n_raw_files, $
            name='kcor/reprocess', /info
    file_move, raw_files, filepath(date, root=run.raw_basedir), /overwrite
  endif else begin
    mg_log, 'no raw files to move', name='kcor/reprocess', /info
  endelse

  log_files = file_search(filepath('*.log', $
                                   subdir=[date, 'level0'], $
                                   root=run.raw_basedir), $
                          count=n_log_files)
  if (n_log_files gt 0L) then begin
    mg_log, 'moving %d t1/t2 log files from level0/ to top-level', n_log_files, $
            name='kcor/reprocess', /info
    file_move, log_files, filepath(date, root=run.raw_basedir), /overwrite
  endif else begin
    mg_log, 'no log files to move', name='kcor/reprocess', /info
  endelse

  ; remove quicklook dir in level0 dir
  if (run.reprocess) then begin
    quicklook_dir = filepath('quicklook', subdir=[date, 'level0'], $
                             root=run.raw_basedir)
    mg_log, 'removing level0/quicklook dir', name='kcor/reprocess', /info
    file_delete, quicklook_dir, /recursive, /allow_nonexistent
  endif

  ; remove level1 dir
  if (run.reprocess) then begin
    l1_dir = filepath('level1', subdir=[date], root=run.raw_basedir)
    mg_log, 'removing level1 dir', name='kcor/reprocess', /info
    file_delete, l1_dir, /recursive, /allow_nonexistent
  endif

  ; remove *kcor* files from archive, fullres, croppedgif, rg dirs
  if (run.reprocess) then begin
    mg_log, 'removing old archived files...', name='kcor/reprocess', /info
    date_parts = kcor_decompose_date(date)
    wildcard = '*kcor*'
    dirs = [run.archive_basedir, run.fullres_basedir, run.croppedgif_basedir, $
            run.nrgf_basedir]
    dir_names = ['archive', 'fullres', 'cropped GIF', 'NRGF'] + ' directory'
    for d = 0L, n_elements(dirs) - 1L do begin
      old_files = file_search(filepath(wildcard, $
                                       subdir=date_parts, $
                                       root=dirs[d]), $
                              count=n_old_files)
      if (n_old_files gt 0L) then begin
        mg_log, 'removing %d files from %s', n_old_files, dir_names[d], $
                name='kcor/reprocess', /info
        for f = 0L, n_old_files - 1L do begin
          mg_file_delete, old_files[f], status=error, message=message
          if (error ne 0L) then begin
            mg_log, 'error deleting %s', old_files[f], name='kcor/reprocess', /error
            mg_log, message, name='kcor/reprocess', /error
            goto, done
          endif
        endfor
      endif else begin
        mg_log, 'no files to remove from %s', dir_names[d], $
                name='kcor/reprocess', /info
      endelse
    endfor
  endif

  ; remove JPEG2000 files
  if (run.hv_basedir eq '') then begin
    mg_log, 'no jp2 directory to remove', name='kcor/reprocess', /info
  endif else begin
    mg_log, 'removing jp2 results...', name='kcor/reproess', /info
    date_parts = kcor_decompose_date(date)
    file_delete, filepath('', subdir=date_parts, root=run.hv_basedir), $
                 /allow_nonexistent
  endelse

  ; remove old saved results
  if (run.save_basedir eq '') then begin
    mg_log, 'no save directory to remove', name='kcor/reprocess', /info
  endif else begin
    mg_log, 'removing save results...', name='kcor/reproess', /info
    file_delete, filepath(date, root=run.save_basedir), $
                 /recursive, /allow_nonexistent
  endelse

  if (run.reprocess) then begin
    p_dir = filepath('p', subdir=date, root=run.raw_basedir)
    mg_log, 'removing p dir', name='kcor/reprocess', /info
    file_delete, p_dir, /recursive, /allow_nonexistent

    q_dir = filepath('q', subdir=date, root=run.raw_basedir)
    mg_log, 'removing q dir', name='kcor/reprocess', /info
    file_delete, q_dir, /recursive, /allow_nonexistent
  endif

  ; remove inventory files in process directory
  inventory = ['science', 'calibration', 'engineering']
  for i = 0L, n_elements(inventory) - 1L do begin
    inventory_filename = filepath(inventory[i] + '_files.txt', subdir=run.date, $
                                  root=run.process_basedir)
    mg_log, 'removing inventory file %s', file_basename(inventory_filename), $
            name='kcor/reprocess', /info
    file_delete, inventory_filename, /allow_nonexistent
  endfor

  ; clear database for the day
  if (run.update_database && run.reprocess) then begin
    mg_log, 'clearing database for the day', name='kcor/reprocess', /info

    obsday_index = mlso_obsday_insert(date, $
                                      run=run, $
                                      database=db, $
                                      status=status, $
                                      log_name='kcor/reprocess')
    if (status eq 0L) then begin
      kcor_db_clearday, run=run, $
                        database=db, $
                        obsday_index=obsday_index, $
                        log_name='kcor/reprocess'
    endif else begin
      mg_log, 'skipping clearing database', name='kcor/reprocess', /info
    endelse

    obj_destroy, db
  endif else begin
    mg_log, 'skipping updating database', name='kcor/reprocess', /info
  endelse

  done:
  mg_log, 'done prepping for reprocessing', name='kcor/reprocess', /info
end
