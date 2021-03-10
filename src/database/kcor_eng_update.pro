; docformat = 'rst'

;+
; Update mean/median values in the MLSO database table: kcor_eng.
;
; Reads a list of NRGF files for a specified date and updates the mean/median
; values for a row of data in 'kcor_eng'.
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
;   database : in, optional, type=KCordbMySql object
;     database connection to use
;   line_means : out, optional, type="fltarr(2, n_files)"
;     set to a named variable to retrieve the mean of the pixel values of the
;     corresponding camera/raw file at `im[10:300, 512]`
;   line_medians : out, optional, type="fltarr(2, n_files)"
;     set to a named variable to retrieve the median of the pixel values of the
;     corresponding camera/raw file at `im[10:300, 512]`
;   azi_means : out, optional, type="fltarr(2, n_files)"
;     set to a named variable to retrieve the mean of the pixel values of the
;     corresponding camera/raw file at a fixed solar radius 
;   azi_medians : out, optional, type="fltarr(2, n_files)"
;     set to a named variable to retrieve the median of the pixel values of the
;     corresponding camera/raw file at a fixed solar radius
;-
pro kcor_eng_update, date, nrgf_files, $
                     line_means=line_means, line_medians=line_medians, $
                     azi_means=azi_means, azi_medians=azi_medians, $
                     run=run, database=db, obsday_index=obsday_index
  compile_opt strictarr

  ; connect to MLSO database
  db->getProperty, host_name=host
  mg_log, 'using connection to %s', host, name='kcor/eod', /debug

  year    = strmid(date, 0, 4)   ; YYYY
  month   = strmid(date, 4, 2)   ; MM
  day     = strmid(date, 6, 2)   ; DD

  for f = 0L, n_elements(nrgf_files) - 1L do begin
    l2_filename = strmid(file_basename(nrgf_files[f]), 0, 20) + '_l2.fts.gz'

    mg_log, 'updating db for %s', l2_filename, name='kcor/eod', /info
    db->execute, 'update kcor_eng set l0inthorizmeancam0=%f,l0inthorizmeancam1=%f, l0inthorizmediancam0=%f, l0inthorizmediancam1=%f, l0intazimeancam0=%f,l0intazimeancam1=%f, l0intazimediancam0=%f, l0intazimediancam1=%f where file_name=''%s''', $
                 line_means[0, f], line_means[1, f], $
                 line_medians[0, f], line_medians[1, f], $
                 azi_means[0, f], azi_means[1, f], $
                 azi_medians[0, f], azi_medians[1, f], $
                 file_basename(l2_filename, '.gz'), $
                 status=status, error_message=error_message, sql_statement=sql_cmd
    if (status ne 0L) then continue
  endfor

  done:
  mg_log, 'done', name='kcor/eod', /info
end
