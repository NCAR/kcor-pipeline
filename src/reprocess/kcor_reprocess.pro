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

  ; clear database for the day
  if (run.update_database) then begin
    mg_log, 'clear database for the day', name='kcor/reprocess', /info

    db = mgdbmysql()
    db->connect, config_filename=run.database_config_filename, $
                 config_section=run.database_config_section

    db->getProperty, host_name=host
    mg_log, 'connected to %s...', host, name='kcor/reprocess', /debug

    db->setProperty, database='MLSO'

    test_db = 1B
    db_suffix = keyword_set(test_db) ? '_test' : ''

    kcor_db_clearday, db, date, 'kcor_img' + db_suffix
    kcor_db_clearday, db, date, 'kcor_eng' + db_suffix
    kcor_db_clearday, db, date, 'kcor_dp' + db_suffix
    kcor_db_clearday, db, date, 'kcor_hw' + db_suffix
    kcor_db_clearday, db, date, 'kcor_cal' + db_suffix

    obj_destroy, db
  endif else begin
    mg_log, 'skipping updating database', name='kcor/reprocess', /info
  endelse

  done:
  mg_log, 'done prepping for reprocessing', name='kcor/reprocess', /info
  obj_destroy, run
end
