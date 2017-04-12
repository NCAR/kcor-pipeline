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
;
; :Examples:
;   For example::
;
;     date = '20170204'
;     filelist = ['20170204_205610_kcor_l1_nrgf.fts.gz', '20170204_205625_kcor_l1.fts.gz']
;     kcor_eng_insert, date, filelist, run=run, obsday_index=obsday_index
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
    mg_log, 'already connected to %s...', host, name='kcor/rt', /info
  endif else begin
    db = mgdbmysql()
    db->connect, config_filename=run.database_config_filename, $
                 config_section=run.database_config_section

    db->getProperty, host_name=host
    mg_log, 'connected to %s...', host, name='kcor/rt', /info
  endelse

  year    = strmid(date, 0, 4)   ; YYYY
  month   = strmid(date, 4, 2)   ; MM
  day     = strmid(date, 6, 2)   ; DD

  ; TODO: find corresponding L1 files and add means/medians

  done:
  if (~obj_valid(database)) then obj_destroy, db

  mg_log, 'done', name='kcor/eod', /info
end