; docformat = 'rst'

;+
; Routine to create a calibration for a day, given a file list, date, and config
; file.
;
; Updates the database if `FILELIST_FILENAME` is not present.
;
; :Params:
;   date : in, required, type=date
;     date in the form 'YYYYMMDD' to produce calibration for
;
; :Keywords:
;   config_filename : in, required, type=string
;     filename of configuration file
;   filelist_filename : in, optional, type=string
;     filename of list of files, if not present, does a catalog to make the list
;     of cal files for the day
;-
pro kcor_calibration, date, $
                      config_filename=config_filename, $
                      filelist_filename=filelist_filename
  compile_opt strictarr

  ; catch and log any crashes
  catch, error
  if (error ne 0L) then begin
    catch, /cancel
    mg_log, /last_error, name='kcor/eod', /critical
    goto, done
  endif

  run = kcor_run(date, config_filename=config_filename)
  run.mode = 'eod'

  mg_log, '------------------------------', name='kcor/eod', /info

  version = kcor_find_code_version(revision=revision, branch=branch)
  mg_log, 'kcor-pipeline %s (%s) [%s]', version, revision, branch, $
          name='kcor/eod', /info
  mg_log, 'IDL %s (%s %s)', !version.release, !version.os, !version.arch, $
          name='kcor/eod', /info
  mg_log, 'starting calibration for %s', date, name='kcor/eod', /info

  if (n_elements(filelist_filename) gt 0L) then begin
    n_files = file_lines(filelist_filename)
    filelist = strarr(n_files)

    mg_log, 'using provided list of files for calibration', name='kcor/eod', info
    openr, lun, filelist_filename, /get_lun

    calfile = ''
    for f = 0L, n_files - 1L do begin
      readf, lun, calfile
      filelist[f] = calfile
    endfor

    free_lun, lun
  endif else begin
    if (run.catalog_files) then begin
      ; clear inventory files before catalog'ing
      txt_glob = filepath('*.txt', subdir=date, root=run.process_basedir)
      txt_files = file_search(txt_glob, count=n_files)
      if (n_files gt 0L) then begin
        mg_log, 'deleting %d old inventory files', n_files, $
                name='kcor/eod', /debug
        file_delete, txt_files, /allow_nonexistent
      endif else begin
        mg_log, 'no old inventory log files to delete', name='kcor/eod', /debug
      endelse

      kcor_catalog, date, run=run, catalog_dir=catalog_dir
    endif
  endelse

  kcor_reduce_calibration, date, run=run, filelist=filelist, catalog_dir=catalog_dir

  ; update databases
  if (run.update_database && (n_elements(filelist_filename) eq 0L)) then begin
    mg_log, 'updating database', name='kcor/eod', /info
    cal_files = kcor_read_calibration_text(date, run.process_basedir, $
                                           exposures=exposures, $
                                           n_files=n_cal_files)

    obsday_index = mlso_obsday_insert(date, $
                                      run=run, $
                                      database=db, $
                                      status=db_status, $
                                      log_name='kcor/eod')

    if (db_status eq 0L) then begin
      kcor_db_clearday, run=run, database=db, $
                        obsday_index=obsday_index, $
                        log_name='kcor/eod', /calibration

      if (n_cal_files gt 0L) then begin
        kcor_cal_insert, date, cal_files, $
                         catalog_dir=catalog_dir, $
                         run=run, $
                         database=db, $
                         obsday_index=obsday_index
      endif else begin
        mg_log, 'no cal files for kcor_cal table', name='kcor/eod', /info
      endelse
    endif else begin
      mg_log, 'error connecting to database', name='kcor/eod', /warn
    endelse
    obj_destroy, db
  endif else begin
    mg_log, 'skipping updating database', name='kcor/eod', /info
  endelse

  done:
  mg_log, 'done', name='kcor/eod', /info
  if (obj_valid(run)) then obj_destroy, run
end