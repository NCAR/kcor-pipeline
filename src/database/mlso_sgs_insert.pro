; docformat = 'rst'

;+
; Insert values into the MLSO database table: mlso_sgs.
;
; Reads a list of L1 files for a specified date and inserts a row of data into
; 'kcor_sgs'.  TODO: will also need to read from sgs text files.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;   filelist: in, required, type=array of strings
;     array of FITS files to insert into the database
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;   obsday_index : in, required, type=integer
;     index into mlso_numfiles database table
;   database : in, optional, type=MGdbMySql object
;     database connection to use
;
; :Examples:
;   For example::
;
;     date = '20170204'
;     filelist = ['20170204_205610_kcor_l1_nrgf.fts.gz', '20170204_205625_kcor_l1.fts.gz']
;     mlso_sgs_insert, date, filelist, run=run, obsday_index=obsday_index
;
; :Author: 
;   Don Kolinski
;   HAO/NCAR  K-coronagraph
;
; :History:
;   10 March, 2017 - Edits by DJK to work with a filelist and with new sgs database table
;-
pro mlso_sgs_insert, date, fits_list, $
                     run=run, $
                     database=database, $
                     obsday_index=obsday_index
  compile_opt strictarr
  on_error, 2

  if (n_params() ne 2) then begin
    mg_log, 'missing date or filelist parameters', name='kcor/dbinsert', /error
    return
  endif

  ; connect to MLSO database

  ; Note: The connect procedure accesses DB connection information in the file
  ;       .mysqldb. The "config_section" parameter specifies which group of data
  ;       to use.

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

  year    = strmid (date, 0, 4)             ; yyyy
  month   = strmid (date, 4, 2)             ; mm
  day     = strmid (date, 6, 2)             ; dd

  sgs_source = ''                           ; 'k' or 's'  (kcor or sgs)
  
  l1_dir = filepath('level1', subdir=date, root=run.raw_basedir)
  cd, current=start_dir
  cd, l1_dir

  ; step through list of fits files passed in parameter
  nfiles = n_elements(fits_list)

  if (nfiles eq 0) then begin
    mg_log, 'no images in fits list', name='kcor/rt', /info
    goto, done
  endif

  i = -1
  while (++i lt nfiles) do begin
    fts_file = fits_list[i]

    ; no need to look at NRGF files
    is_nrgf = strpos(file_basename(fts_file), 'nrgf') ge 0L
    if (is_nrgf) then continue

    fts_file += '.gz'

    if (~file_test(fts_file)) then begin
      mg_log, '%s not found', fts_file, name='kcor/rt', /warn
      continue
    endif else begin
      mg_log, 'ingesting %s', fts_file, name='kcor/rt', /info
    endelse

    ; if in this conditional, then the source is KCor
    sgs_source = 'k'

    ; extract desired items from header
    hdu = headfits(fts_file, /silent)   ; read FITS header

    date_obs  = sxpar(hdu, 'DATE-OBS', count=qdate_obs)
    sgsdimv   = sxpar(hdu, 'SGSDIMV', count=qsgsdimv)
    sgsdims   = sxpar(hdu, 'SGSDIMS', count=qsgsdims)
    sgssumv   = sxpar(hdu, 'SGSSUMV', count=qsgssumv)
    sgsrav    = sxpar(hdu, 'SGSRAV', count=qsgsrav)
    sgsras    = sxpar(hdu, 'SGSRAS', count=qsgsras)
    sgsrazr   = sxpar(hdu, 'SGSRAZR', count=qsgsrazr)
    sgsrazr_str = qsgsrazr eq 0L ? 'NULL' : string(sgsrazr, format='(%"%f")')
    sgsdecv   = sxpar(hdu, 'SGSDECV', count=qsgsdecv)
    sgsdecs   = sxpar(hdu, 'SGSDECS', count=qsgsdecs)
    sgsdeczr  = sxpar(hdu, 'SGSDECZR', count=qsgsdeczr)
    sgsdeczr_str = qsgsdeczr eq 0L ? 'NULL' : string(sgsdeczr, format='(%"%f")')
    sgsscint  = sxpar(hdu, 'SGSSCINT', count=qsgsscint)
    sgssums   = sxpar(hdu, 'SGSSUMS', count=qsgssums)
    sgsloop   = sxpar(hdu, 'SGSLOOP', count=qsgsloop)
		
    ;fits_file = file_basename(fts_file, '.gz') ; remove '.gz' from file name.
		
    ; DB insert command
    db->execute, 'INSERT INTO mlso_sgs (date_obs, obs_day, source, sgsdimv, sgsdims, sgssumv, sgsrav, sgsras, sgsrazr, sgsdecv, sgsdecs, sgsdeczr, sgsscint, sgssums, sgsloop) VALUES (''%s'', %d, ''%s'', %f, %f, %f, %f, %f, %s, %f, %f, %s, %f, %f, %d) ', $
                 date_obs, obsday_index, sgs_source, sgsdimv, sgsdims, $
                 sgssumv, sgsrav, sgsras, sgsrazr_str, sgsdecv, sgsdecs, $
                 sgsdeczr_str, sgsscint, sgssums, sgsloop, $
                 status=status, error_message=error_message, sql_statement=sql_cmd
    if (status ne 0L) then begin
      mg_log, 'error inserting to mlso_sgs table', name='kcor/rt', /error
      mg_log, 'status: %d, error message: %s', status, error_message, $
              name='kcor/rt', /error
      mg_log, 'SQL command: %s', sql_cmd, name='kcor/rt', /error
    endif
  endwhile

  done:
  if (~obj_valid(database)) then obj_destroy, db
  cd, start_dir

  mg_log, 'done', name='kcor/rt', /info
end


; main-level example program

date = '20170204'
filelist = ['20170204_205610_kcor_l1_nrgf.fts.gz','20170204_205625_kcor_l1.fts.gz','20170204_205640_kcor_l1.fts.gz','20170204_205656_kcor_l1.fts.gz','20170204_205711_kcor_l1.fts.gz']
run = kcor_run(date, $
               config_filename=filepath('kcor.kolinski.mahi.latest.cfg', $
                                        subdir=['..', '..', 'config'], $
                                        root=mg_src_root()))
mlso_sgs_insert, date, filelist, run=run

end