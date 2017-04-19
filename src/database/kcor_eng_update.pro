; docformat = 'rst'

;+
; Update mean/median values in the MLSO database table: kcor_eng.
;
; Reads a list of L0 files corresponding to NRGFs for a specified date and
; updates the mean/median values for a row of data in 'kcor_eng'.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;   nrgf_files : in, required, type=array of strings
;     array of NRGF FITS files to insert into the database
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;   obsday_index : in, required, type=integer
;     index into mlso_numfiles database table
;   database : in, optional, type=MGdbMySql object
;     database connection to use
;   line_means : out, optional, type="fltarr(2, n_files)"
;     set to a named variable to retrieve the mean of the pixel values of the
;     corresponding camera/raw file at `im[10:300, 512]`
;   line_medians : out, optional, type="fltarr(2, n_files)"
;     set to a named variable to retrieve the median of the pixel values of the
;     corresponding camera/raw file at `im[10:300, 512]`
;   radial_means : out, optional, type="fltarr(2, n_files)"
;     set to a named variable to retrieve the mean of the pixel values of the
;     corresponding camera/raw file at a fixed solar radius 
;   radial_medians : out, optional, type="fltarr(2, n_files)"
;     set to a named variable to retrieve the median of the pixel values of the
;     corresponding camera/raw file at a fixed solar radius
;-
pro kcor_eng_update, date, nrgf_files, $
                     line_means=line_means, line_medians=line_medians, $
                     radial_means=radial_means, radial_medians=radial_medians, $
                     run=run, database=db, obsday_index=obsday_index
  compile_opt strictarr

  ; connect to MLSO database

  ; Note: The connect procedure accesses DB connection information in the file
  ;       .mysqldb. The "config_section" parameter specifies
  ;       which group of data to use.
  if (obj_valid(database)) then begin
    db = database

    db->getProperty, host_name=host
    mg_log, 'using connection to %s', host, name='kcor/eod', /debug
  endif else begin
    db = mgdbmysql()
    db->connect, config_filename=run.database_config_filename, $
                 config_section=run.database_config_section

    db->getProperty, host_name=host
    mg_log, 'connected to %s', host, name='kcor/eod', /info
  endelse

  year    = strmid(date, 0, 4)   ; YYYY
  month   = strmid(date, 4, 2)   ; MM
  day     = strmid(date, 6, 2)   ; DD

  for f = 0L, n_elements(nrgf_files) - 1L do begin
    l1_filename = strmid(nrgf_files[f], 0, 20) + '_l1.fts'
    mg_log, 'updating db for %s', l1_filename, name='kcor/eod', /info
    db->execute, 'UPDATE kcor_eng SET l0inthorizmeancam0=''%d'',l0inthorizmeancam1=''%d'', l0inthorizmediancam0=''%d'', l0inthorizmediancam1=''%d'', l0intradialmeancam0=''%d'',l0intradialmeancam1=''%d'', l0intradialmediancam0=''%d'', l0intradialmediancam1=''%d'' WHERE file_name=''%s''', $
                 line_means[0, f], line_means[1, f], $
                 line_medians[0, f], line_medians[1, f], $
                 radial_means[0, f], radial_means[1, f], $
                 radial_medians[0, f], radial_medians[1, f], $
                 l1_filename, $
                 status=status, error_message=error_message, sql_statement=sql_cmd
    if (status ne 0L) then begin
      mg_log, 'error updating values in kcor_eng table for obsday index %d', $
              obsday_index, name='kcor/eod', /error
      mg_log, 'status: %d, error message: %s', status, error_message, $
              name=log_name, /error
      mg_log, 'SQL command: %s', sql_cmd, name='kcor/eod', /error
    endif
  endfor

  done:
  if (~obj_valid(database)) then obj_destroy, db

  mg_log, 'done', name='kcor/eod', /info
end