; docformat = 'rst'

;+
; This is the top-level reprocessing pipeline routine.
;
; :Params:
;   date : in, required, type=string
;     date to process in the form "YYYYMMDD"
;
; :Keywords:
;   config_filename : in, required, type=string
;     configuration file specifying the parameters of the run
;-
pro kcor_reprocess, date, config_filename=config_filename
  compile_opt strictarr

  ; catch and log any crashes
  catch, error
  if (error ne 0L) then begin
    catch, /cancel
    mg_log, /last_error, name='kcor/reprocess', /critical
    goto, done
  endif

  run = kcor_run(date, config_filename=config_filename)

  mg_log, 'prepping for reprocessing', name='kcor/reprocess', /info

  ; zip any unzipped raw files
  unzipped_raw_fits_glob = filepath('*_kcor.fts', $
                                    subdir=[date, 'level0'], $
                                    root=run.raw_basedir)
  unzipped_raw_files = file_search(unzipped_raw_fits_glob, $
                                   count=n_unzipped_raw_files)
  if (n_unzipped_raw_files gt 0L) then begin
    mg_log, 'unzipping %d L0 FITS files', n_unzipped_raw_files, $
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

  ; copy level 0 FITS files and t1/t2 logs up a level
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

  ; TODO: remove entire level1 directory
  ; TODO: remove *kcor* files from archive, movie, fullres, croppedgif, rg dirs

  ; remove level 1 files
  l1_files = file_search(filepath('*', $
                                  subdir=[date, 'level1'], $
                                  root=run.raw_basedir), $
                         count=n_l1_files)
  if (n_l1_files gt 0L) then begin
    mg_log, 'deleting %d level 1 files', n_l1_files, name='kcor/reprocess', /info
    file_delete, l1_files
  endif else begin
    mg_log, 'no level 1 files to delete', name='kcor/reprocess', /info
  endelse

  p_dir = filepath('p', subdir=date, root=run.raw_basedir)
  if (file_test(p_dir, /directory)) then file_delete, p_dir, /recursive
  q_dir = filepath('q', subdir=date, root=run.raw_basedir)
  if (file_test(q_dir, /directory)) then file_delete, q_dir, /recursive

  ; clear database for the day
  if (run.update_database) then begin
    mg_log, 'clear database for the day', name='kcor/reprocess', /info

    obsday_index = mlso_obsday_insert(date, $
                                      run=run, $
                                      database=db, $
                                      log_name='kcor/reprocess')
    kcor_db_clearday, run=run, $
                      database=db, $
                      obsday_index=obsday_index, $
                      log_name='kcor/reprocess'

    obj_destroy, db
  endif else begin
    mg_log, 'skipping updating database', name='kcor/reprocess', /info
  endelse

  done:
  mg_log, 'done prepping for reprocessing', name='kcor/reprocess', /info
  obj_destroy, run
end
