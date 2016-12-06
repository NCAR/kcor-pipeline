; docformat = 'rst'

;+
; Insert values into the MLSO database table: kcor_eng.
;
; Reads a list of L1 files for a specified date and inserts a row of data into
; 'kcor_eng'.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;
; :Examples:
;   For example::
;
;     kcor_eng_insert, '20150324'
;
; :Author: 
;   Andrew Stanger
;   HAO/NCAR  K-coronagraph
;
; :History:
;   8 Sep 2015 IDL procedure created.
;              Use /hao/mlsodata1/Data/KCor/raw/yyyymmdd directory.
;   15 Sep 2015 Use /hao/acos/year/month/day directory for L1 fits files.
;
;-
pro kcor_eng_insert, date, run=run
  compile_opt strictarr
  on_error, 2

  np = n_params() 
  if (np ne 1) then begin
    mg_log, 'missing date parameter', name='kcor/dbinsert', /error
    return
  endif

  ;--------------------------
  ; Connect to MLSO database.
  ;--------------------------

  db = mgdbmysql()
  db->connect, config_filename=run.database_config_filename, $
               config_section=run.database_config_section

  db->getProperty, host_name=host
  mg_log, 'connected to %s...', host, name='kcor/dbinsert', /info

  db->setProperty, database='MLSO'

  ;----------------------------------
  ; Print DB tables in MLSO database.
  ;----------------------------------

  ;print, db, format='(A, /, 4(A-20))'

  ;-------------------------------------------------------------------------------
  ; Delete all pre-existing rows with date = designated date to be processed.
  ;-------------------------------------------------------------------------------

  year    = strmid (date, 0, 4)             ; yyyy
  month   = strmid (date, 4, 2)             ; mm
  day     = strmid (date, 6, 2)             ; dd
  pdate_dash = year + '-' + month + '-' + day	; 'yyyy-mm-dd%'
  pdate_wild = pdate_dash + "%"

  db->execute, 'DELETE FROM kcor_eng WHERE date like ''%s''', pdate_wild, $
               status=status, error_message=error_message, sql_statement=sql_cmd
  mg_log, 'sql_cmd: %s', sql_cmd, name='kcor/dbinsert', /info
  mg_log, 'status: %d, error message: %s', status, error_message, $
          name='kcor/dbinsert', /info

  ; Delete table & reset auto-increment value to 1.
  ;db->execute, 'TRUNCATE TABLE kcor_eng', $
  ;             status=status, error_message=error_message, sql_statement=sql_cmd

  ; Set auto-increment value to 1.
  ;db->execute, 'ALTER TABLE kcor_eng AUTO_INCREMENT = 1'

  ;mg_log, 'sql_cmd: %s', sql_cmd, name='kcor/dbinsert', /info
  ;mg_log, 'status: %d, error message: %s', status, error_message, $
  ;        name='kcor/dbinsert', /info

  ;-----------------------
  ; Directory definitions.
  ;-----------------------

  fts_dir = filepath('', subdir=[year, month, day], root=run.archive_dir)

  ;----------------
  ; Move to fts_dir.
  ;----------------

  cd, current=start_dir
  cd, fts_dir

  ;------------------------------------------------
  ; Create list of fits files in current directory.
  ;------------------------------------------------

  fits_list = file_search('*kcor_l1.fts*', count=nfiles)

  if (nfiles eq 0) then begin
    mg_log, 'no images in list file', name='kcor/dbinsert', /info
    goto, done
  endif

  i       = -1
  fts_file = 'img.fts'

  while (++i lt nfiles) do begin
    fts_file = fits_list[i]
    finfo = file_info(fts_file)	  ; Get file information.

    ; Read FITS header.

    hdu = headfits(fts_file, /silent)

    ; Extract desired items from header.

    date_obs   = sxpar(hdu, 'DATE-OBS', count=qdate_obs)
    rcamfocs   = sxpar(hdu, 'RCAMFOCS', count=qrcamfocs)
    tcamfocs   = sxpar(hdu, 'TCAMFOCS', count=qtcamfocs)
    modltrt    = sxpar(hdu, 'MODLTRT',  count=qmodltrt)
    o1focs     = sxpar(hdu, 'O1FOCS',   count=q01focs)
    sgsdimv    = sxpar(hdu, 'SGSDIMV',  count=qsgsdimv)
    sgsdims    = sxpar(hdu, 'SGSDIMS',  count=qsgsdims)
    sgssumv    = sxpar(hdu, 'SGSSUMV',  count=qsgssumv)
    sgsrav     = sxpar(hdu, 'SGSRAV',   count=qsgsrav)
    sgsras     = sxpar(hdu, 'SGSRAS',   count=qsgsras)
    sgsrazr    = sxpar(hdu, 'SGSRAZR',  count=qsgsrazr)
    sgsdecv    = sxpar(hdu, 'SGSDECV',  count=qsgsdecv)
    sgsdecs    = sxpar(hdu, 'SGSDECS',  count=qsgsdecs)
    sgsdeczr   = sxpar(hdu, 'SGSDECZR', count=qsgsdeczr)
    sgsscint   = sxpar(hdu, 'SGSSCINT', count=qsgsscint)
    sgssums    = sxpar(hdu, 'SGSSUMS',  count=qsgssums)

    rcamfocs_str = strtrim(rcamfocs, 2)
    tcamfocs_str = strtrim(tcamfocs, 2)
    mg_log, 'rcamfocs: %f, tcamfocs: %f', rcamfocs, tcamfocs, name='kcor/dbinsert', /debug
    ;  if (rcamfocs_str EQ 'NaN') then print, 'rcamfocs: Not a Number'
    ;  if (tcamfocs_str EQ 'NaN') then print, 'tcamfocs: Not a Number' 
    if (rcamfocs_str eq 'NaN') then rcamfocs = -99.99
    if (tcamfocs_str eq 'NaN') then tcamfocs = -99.99

    ; Construct variables for database table fields.

    year  = strmid (date_obs, 0, 4)   ; yyyy
    month = strmid (date_obs, 5, 2)   ; mm
    day   = strmid (date_obs, 8, 2)   ; dd

    ; Determine DOY.

    mday      = [0,31,59,90,120,151,181,212,243,273,304,334]
    mday_leap = [0,31,60,91,121,152,182,213,244,274,305,335] ;leap year 

    if ((fix(year) mod 4) eq 0) then begin
      doy = mday_leap[fix(month) - 1] + fix(day)
    endif else begin 
      doy = mday[fix(month) - 1] + fix(day)
    endelse
  doy_str = string(doy, format='(%"%3d")')

  date_dash    = strmid(date_obs, 0, 10)	; yyyy-mm-dd
  time_obs     = strmid(date_obs, 11, 8)	; hh:mm:ss
  date_eng     = date_dash + ' ' + time_obs	; yyyy-mm-dd hh:mm:ss
  fits_file    = strmid(fts_file, 0, 27)	; remove '.gz' from file name.

  ; DB insert command.

  db->execute, 'INSERT INTO kcor_eng (file_name, date, rcamfocs, tcamfocs, modltrt, o1focs, sgsdimv, sgsdims, sgssumv, sgsrav, sgsras, sgsrazr, sgsdecv, sgsdecs, sgsdeczr, sgsscint, sgssums) VALUES (''%s'', ''%s'', %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f) ', $
               fits_file, date_eng, rcamfocs, tcamfocs, modltrt, o1focs, $
               sgsdimv, sgsdims, sgssumv, sgsrav, sgsras, sgsrazr, sgsdecv, $
               sgsdecs, sgsdeczr, sgsscint, sgssums, $
               status=status, error_message=error_message, sql_statement=sql_cmd

    mg_log, '%s: status: %d, error message: %s', status, error_message, $
            name='kcor/dbinsert', /debug
    mg_log, 'sql_cmd: %s', sql_cmd, name='kcor/dbinsert', /debug
  endwhile

  done:
  obj_destroy, db

  mg_log, '*** end of kcor_eng_insert ***', name='kcor/dbinsert', /info
end
