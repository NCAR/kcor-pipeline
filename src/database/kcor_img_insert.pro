; docformat = 'rst'

;+
; Utility to insert values into the MLSO database table: kcor_img.
;
; Reads a list of L1 files for a specified date and inserts a row of data into
; 'kcor_img'.
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
;     kcor_img_insert, '20150324'
;
; :Author: 
;   Andrew Stanger
;   HAO/NCAR  K-coronagraph
;
; :History:
;   11 Sep 2015 IDL procedure created.  
;               Use /hao/mlsodata1/Data/raw/yyyymmdd/level1 directory.
;   14 Sep 2015 Use /hao/acos/year/month/day directory.
;   28 Sep 2015 Add date_end field.
;   7 Feb 2017 Starting to edit for new table fields
;
; :Todo:
;   Get image quality to fill "quality" field in db.
;   Add field for raw occulter center.
;   Add field for sky polarization coefficients
;   Add field for modulation matrix coefficients (at 3 pixels).
;-
pro kcor_img_insert, date, run=run
  compile_opt strictarr
  on_error, 2

  np = n_params() 
  if (np ne 1) then begin
    mg_log, 'missing date parameter', name='kcor/dbinsert', /error
    return
  end

  ;--------------------------
  ; Connect to MLSO database.
  ;--------------------------

  ; Note: The connect procedure accesses DB connection information in the file
  ;       /home/stanger/.mysqldb. The "config_section" parameter specifies
  ;       which group of data to use.

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
  ; Delete all pre-existing rows with date_obs = designated date to be processed.
  ;-------------------------------------------------------------------------------

  year    = strmid (date, 0, 4)	; yyyy
  month   = strmid (date, 4, 2)	; mm
  day     = strmid (date, 6, 2)	; dd
  odate_dash = year + '-' + month + '-' + day + '%'

  db->execute, 'DELETE FROM kcor_img WHERE date_obs like ''%s''', odate_dash, $
               status=status, error_message=error_message, sql_statement=sql_cmd
  mg_log, 'sql_cmd: %s', sql_cmd, name='kcor/dbinsert', /info
  mg_log, 'status: %d, error message: %s', status, error_message, $
          name='kcor/dbinsert', /info

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
  end

  i       = -1
  fts_file = 'img.fts'

  while (++i lt nfiles) do begin
    fts_file = fits_list[i]

    finfo = file_info(fts_file)   ; Get file information.

    ; Read FITS header.

    hdu   = headfits(fts_file, /silent)   ; Read FITS header.

    datatype = 'unknown'
    instrume = 'missing_keyword'

    ; Extract desired items from header.

    date_obs   = sxpar(hdu, 'DATE-OBS', count=qdate_obs)
    date_end   = sxpar(hdu, 'DATE-END', count=qdate_end)
    telescop   = sxpar(hdu, 'TELESCOP', count=qtelescop)
    instrume   = sxpar(hdu, 'INSTRUME', count=qinstrume)
    datatype   = sxpar(hdu, 'DATATYPE', count=qdatatype)
    level      = sxpar(hdu, 'LEVEL',    count=qlevel)
    exptime    = sxpar(hdu, 'EXPTIME',  count=qexptime)
    numsum     = sxpar(hdu, 'NUMSUM',   count=qnumsum)
    rsun       = sxpar(hdu, 'RSUN',     count=qrsun)
    solar_p0   = sxpar(hdu, 'SOLAR_P0', count=qsolar_p0)
    carr_lat   = sxpar(hdu, 'CRLT_OBS', count=qcrlt_obs)
    carr_lon   = sxpar(hdu, 'CRLN_OBS', count=qcrln_obs)
    carr_rot   = sxpar(hdu, 'CAR_ROT',  count=car_rot)
    solar_ra   = sxpar(hdu, 'SOLAR_RA', count=qsolar_ra)
    solardec   = sxpar(hdu, 'SOLARDEC', count=qsolardec)

    level_str = strtrim(level, 2)
    quality    = 'u'
    filetype   = 'fits'

    mg_log, 'date_obs: %s', date_obs, name='kcor/dbinsert', /debug
    mg_log, 'date_end: %s', date_end, name='kcor/dbinsert', /debug
    mg_log, 'telescop: %s', telescop, name='kcor/dbinsert', /debug
    mg_log, 'instrume: %s', instrume, name='kcor/dbinsert', /debug
    mg_log, 'datatype: %s', datatype, name='kcor/dbinsert', /debug
    mg_log, 'level:    %s', level, name='kcor/dbinsert', /debug
    mg_log, 'exptime:  %s', exptime, name='kcor/dbinsert', /debug
    mg_log, 'numsum:   %s', numsum, name='kcor/dbinsert', /debug
    mg_log, 'rsun:     %s', rsun, name='kcor/dbinsert', /debug
    mg_log, 'solar_p0: %s', solar_p0, name='kcor/dbinsert', /debug
    mg_log, 'carr_lat: %s', carr_lat, name='kcor/dbinsert', /debug
    mg_log, 'carr_lon: %s', carr_lon, name='kcor/dbinsert', /debug
    mg_log, 'carr_rot: %s', carr_rot, name='kcor/dbinsert', /debug
    mg_log, 'solar_ra: %s', solar_ra, name='kcor/dbinsert', /debug
    mg_log, 'solardec: %s', solardec, name='kcor/dbinsert', /debug

    if (qdatatype eq 0) then begin
      mg_log, 'qdatatype: %s', qdatatype, name='kcor/dbinsert', /debug
      datatype = 'unknown'
    endif

    if (qinstrume eq 0) then begin
      mg_log, 'qinstrume: %s', qinstrume, name='kcor/dbinsert', /debug
      instrume = telescop
    endif

    ; Construct variables for database table fields.

    year  = strmid(date_obs, 0, 4)   ; yyyy
    month = strmid(date_obs, 5, 2)   ; mm
    day   = strmid(date_obs, 8, 2)   ; dd

    ;  cal_year  = strmid (calfile, 0, 4)	; yyyy
    ;  cal_month = strmid (calfile, 4, 2)	; mm
    ;  cal_day   = strmid (calfile, 6, 2)	; dd

    ;--- Determine DOY.

    mday      = [0,31,59,90,120,151,181,212,243,273,304,334]
    mday_leap = [0,31,60,91,121,152,182,213,244,274,305,335] ;leap year 
    
    if ((fix(year) mod 4) eq 0) then begin
      doy = mday_leap[fix(month) - 1] + fix(day)
    endif else begin
      doy = mday[fix(month) - 1] + fix(day)
    endelse
    doy_str = string(doy, format='(%"%3d")')

    date_dash = strmid(date_obs, 0, 10)      ; yyyy-mm-dd
    time_obs  = strmid(date_obs, 11, 8)      ; hh:mm:ss
    date_img  = date_dash + ' ' + time_obs   ; yyyy-mm-dd hh:mm:ss

    date_dash = strmid(date_end, 0, 10)      ; yyyy-mm-dd
    time_obs  = strmid(date_end, 11, 8)      ; hh:mm:ss
    date_eod  = date_dash + ' ' + time_obs   ; yyyy-mm-dd hh:mm:ss

    fits_file = strmid(fts_file, 0, 27)	   ; remove '.gz' from file name.

    ;  print, 'date_dash:    ', date_dash
    ;  print, 'doy_str:      ', doy_str
    ;  print, 'fits_file:    ', fits_file
    ;  print

    ; Encode index columns.

    instrume_results = db->query ('SELECT * FROM instrume WHERE instrument=''%s''', $
                                  instrume, fields=fields)
    instrume_num = instrume_results.id
    mg_log, 'instrume:            %s', instrume, name='kcor/dbinsert', /debug
    mg_log, 'instrume_results.id: %s', instrume_results.id, name='kcor/dbinsert', /debug

    quality_results = db->query('SELECT * FROM quality WHERE quality=''%s''', $
                                 quality, fields=fields)
    quality_num = quality_results.id
    mg_log, 'quality:             %s', quality, name='kcor/dbinsert', /debug
    mg_log, 'quality_results.id:  %s', quality_results.id, name='kcor/dbinsert', /debug

    filetype_results = db->query('SELECT * FROM filetype WHERE filetype=''%s''', $
                                 filetype, fields=fields)
    filetype_num = filetype_results.id
    mg_log, 'filetype:            %s', filetype, name='kcor/dbinsert', /debug
    mg_log, 'filetype_results.id: %s', filetype_results.id, name='kcor/dbinsert', /debug

    level_results = db->query('SELECT * FROM level WHERE level=''%s''', level, $
                              fields=fields)
    level_num = level_results.id
    mg_log, 'level:               %s', level, name='kcor/dbinsert', /debug
    mg_log, 'level_results.id:    %s', level_results.id, name='kcor/dbinsert', /debug

    ;--- DB insert command.

    db->execute, 'INSERT INTO kcor_img (file_name, date_obs, date_end, instrument, level, datatype, quality, numsum, exptime, rsun, solar_p0, carr_lat, carr_lon, carr_rot, solar_ra, solardec) VALUES (''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', %d, %f, %f, %f, %f, %f, %f, %f, %f) ', $
                 fits_file, date_img, date_eod, instrume, level_str, datatype, $
                 quality, numsum, exptime, rsun, solar_p0, $
                 carr_lon, carr_lat, carr_rot, solar_ra, solardec, $
                 status=status, error_message=error_message, sql_statement=sql_cmd

    mg_log, '%d, error message: %s', status, error_message, $
            name='kcor/dbinsert', /debug
    mg_log, 'sql_cmd: %s', sql_cmd, name='kcor/dbinsert', /debug

  endwhile

  done:
  obj_destroy, db

  mg_log, '*** end of kcor_img_insert ***', name='kcor/dbinsert', /info
end


; main-level example program

date = '20170204'
run = kcor_run(date, $
               config_filename=filepath('kcor.kolinski.mahi.latest.cfg', $
                                        subdir=['..', '..', 'config'], $
                                        root=mg_src_root()))
kcor_img_insert, date, run=run

end
