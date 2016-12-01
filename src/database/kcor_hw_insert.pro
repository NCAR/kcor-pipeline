; docformat = 'rst'

;+
; Insert values into the MLSO database table: kcor_hw.
;
; Reads a list of L1 files for a specified date and inserts a row of data into
; 'kcor_hw'.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;
; :Examples:
;   For example::
;
;     kcor_hw_insert, '20150324', 'okligz.ls'
;
; :Author: 
;   Andrew Stanger
;   HAO/NCAR  K-coronagraph
;
; :History:
;   11 Sep 2015 IDL procedure created.
;               Use /hao/mlsodata1/Data/KCor/raw/yyyymmdd for L1 fits files.
;   15 Sep 2015 Use /hao/acos/year/month/day directory    for L1 fits files.
;-
pro kcor_hw_insert, date, run=run
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

  year    = strmid (date, 0, 4)                      ; yyyy
  month   = strmid (date, 4, 2)                      ; mm
  day     = strmid (date, 6, 2)                      ; dd
  pdate_dash = year + '-' + month + '-' + day + '%'  ; 'yyyy-mm-dd%'

  db->execute, 'DELETE FROM kcor_hw WHERE date like ''%s''', pdate_dash, $
               status=status, error_message=error_message, sql_statement=sql_cmd
  mg_log, 'sql_cmd: %s', sql_cmd, name='kcor/dbinsert', /info
  mg_log, 'status: %d, error message: %s', status, error_message, $
          name='kcor/dbinsert', /info

  ;-----------------------
  ; Directory definitions.
  ;-----------------------

  fts_dir = filepath('', subdir=[year, month, day], root=run.archive_dir)

  ;-----------------
  ; Move to fts_dir.
  ;-----------------

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
    fts_file = fits_list [i]

    finfo = file_info(fts_file)          ; Get file information.

    ; Read FITS header.

    hdu   = headfits(fts_file, /silent)  ; Read FITS header.

    ; Extract desired items from header.

    date_obs   = sxpar(hdu, 'DATE-OBS', count=qdate_obs)
    diffsrid   = sxpar(hdu, 'DIFFSRID', count=qdiffsrid)
    rcamid     = sxpar(hdu, 'RCAMID',   count=qrcamid)
    tcamid     = sxpar(hdu, 'TCAMID',   count=qtcamid)
    rcamlut    = sxpar(hdu, 'RCAMLUT',  count=qrcamlut)
    tcamlut    = sxpar(hdu, 'TCAMLUT',  count=qtcamlut)
    modltrid   = sxpar(hdu, 'MODLTRID', count=qmodltrid)
    o1id       = sxpar(hdu, 'O1ID',     count=qo1id)
    occltrid   = sxpar(hdu, 'OCCLTRID', count=qoccltrid)
    filterid   = sxpar(hdu, 'FILTERID', count=qfilterid)
    sgsloop    = sxpar(hdu, 'SGSLOOP',  count=qsgsloop)

    modltrid   = strtrim(modltrid, 2)	; Remove leading/trailing blanks
    o1id       = strtrim(o1id,     2)	; Remove leading/trailing blanks
    occltrid   = strtrim(occltrid, 2)	; Remove leading/trailing blanks
    filterid   = strtrim(filterid, 2)	; Remove leading/trailing blanks

    ; Construct variables for database table fields.

    year  = strmid(date_obs, 0, 4)	; yyyy
    month = strmid(date_obs, 5, 2)	; mm
    day   = strmid(date_obs, 8, 2)	; dd

    ; Determine DOY.

  mday      = [0,31,59,90,120,151,181,212,243,273,304,334]
  mday_leap = [0,31,60,91,121,152,182,213,244,274,305,335] ;leap year 

  if ((fix(year) mod 4) eq 0) then begin
  doy = mday_leap[fix(month) - 1] + fix(day)
  endif else begin
    doy = mday[fix(month) - 1] + fix(day)
  endelse
  doy_str = string(doy, format='(%"%3d")')

  date_dash = strmid(date_obs, 0, 10)	 ; yyyy-mm-dd
  time_obs  = strmid(date_obs, 11, 8)    ; hh:mm:ss
  date_hw   = date_dash + ' ' + time_obs ; yyyy-mm-dd hh:mm:ss
  fits_file = strmid (fts_file, 0, 27)   ; eliminate ".gz" from file name.

  ;--- DB insert command.

  db->execute, 'INSERT INTO kcor_hw (date, diffsrid, rcamid, tcamid, rcamlut, tcamlut, modltrid, o1id, occltrid, filterid, sgsloop) VALUES (''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', %d) ',  $
               date_hw, diffsrid, rcamid, tcamid, rcamlut, tcamlut, modltrid, $
               o1id, occltrid, filterid, sgsloop, $
               status=status, error_message=error_message, sql_statement=sql_cmd

    mg_log, '%s: status: %d, error message: %s', status, error_message, $
            name='kcor/dbinsert', /debug
    mg_log, 'sql_cmd: %s', sql_cmd, name='kcor/dbinsert', /debug

    if (i eq 0) then  goto, done   ; Process only the first file in the list.
  endwhile

  done:
  obj_destroy, db

  mg_log, '*** end of kcor_hw_insert ***', name='kcor/dbinsert', /info
end
