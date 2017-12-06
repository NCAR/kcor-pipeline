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

  run = kcor_run(date, config_filename=config_filename)

  n_files = file_lines(filelist_filename)
  filelist = strarr(n_files)

  calfile = ''

  if (n_elements(filelist_filename) gt 0L) then begin
    openr, lun, filelist_filename, /get_lun

    for f = 0L, n_files - 1L do begin
      readf, lun, calfile
      filelist[f] = calfile
    endfor

    free_lun, lun
  endif else begin
    if (run.catalog_files) then kcor_catalog, date, list=filelist, run=run
  endelse

  kcor_reduce_calibration, date, run=run, filelist=filelist

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
                         run=run, database=db, obsday_index=obsday_index
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

  obj_destroy, run
end