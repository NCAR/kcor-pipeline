; NOTE! THIS SCRIPT IS NOT CURRENTLY IN USE.  THE MISSION TABLE IS UPDATED INFREQUENTLY
;   AND BY HAND.


; docformat = 'rst'
;+
; Insert values into the MLSO database table: kcor_mission.
;
; Reads a list of L1 files for a specified date and inserts a row of data into
; 'kcor_mission'.
;
; :Params:
;   date : in, type=string
;     date in the form 'YYYYMMDD'
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;
; :Examples:
;   For example::
;
;     kcor_mission_insert, '20150324'
;
; :Author: 
;   Andrew Stanger
;   HAO/NCAR  K-coronagraph
;
; :History:
;    8 Sep 2015 IDL procedure created.
;             Use /hao/mlsodata1/Data/KCor/raw/yyyymmdd for L1 fits files.
;    15 Sep 2015 Use /hao/acos/year/month/day directory    for L1 fits files.
;-
pro kcor_mission_insert, date, run=run
  compile_opt strictarr
  on_error, 2

  np = n_params() 
  if (np ne 1) then begin
    mg_log, 'missing date parameter', name='kcor/eod', /error
    return
  endif

  ;--------------------------
  ; Connect to MLSO database.
  ;--------------------------

  ; Note: The connect procedure accesses DB connection information in the file
  ;       /home/stanger/.mysqldb. The "config_section" parameter specifies which
  ;       group of data to use.

  db = mgdbmysql()
  db->connect, config_filename=run->config('database/config_filename'), $
               config_section=run->config('database/config_section')

  db->getProperty, host_name=host
  mg_log, 'connected to %s', host, name='kcor/eod', /info

  db->setProperty, database='MLSO'

  ;----------------------------------
  ; Print DB tables in MLSO database.
  ;----------------------------------

  ;print, db, format='(A, /, 4(A-20))'

  ;-------------------------------------------------------------------------------
  ; Delete all pre-existing rows with date_obs = designated date to be processed.
  ;-------------------------------------------------------------------------------

  year    = strmid(date, 0, 4)                   ; yyyy
  month   = strmid(date, 4, 2)                   ; mm
  day     = strmid(date, 6, 2)                   ; dd
  pdate_dash = year + '-' + month + '-' + day + '%'	; yyyy-mm-dd%

  db->execute, 'DELETE FROM kcor_mission WHERE date like ''%s''', pdate_dash, $
               status=status, error_message=error_message, sql_statement=sql_cmd

  mg_log, 'sql_cmd: %s', sql_cmd, name='kcor/eod', /info
  mg_log, 'status: %d, error message: %s', status, error_message, $
          name='kcor/eod', /info

  ;-----------------------
  ; Directory definitions.
  ;-----------------------

  fts_dir = filepath('', subdir=[year, month, day], root=run->config('results/archive_dir'))

  ;----------------
  ; Move to fts_dir.
  ;----------------

  cd, current=start_dir
  cd, fts_dir

  ;------------------------------------------------
  ; Create list of fits files in current directory.
  ;------------------------------------------------

  fits_list = file_search('*kcor_l1.5.fts*', count=nfiles)

  if (nfiles eq 0) then begin
    mg_log, 'no images in list file', name='kcor/eod', /info
    goto, done
  end

  i       = -1
  fts_file = 'img.fts'

  while (++i lt nfiles) do begin
    fts_file = fits_list[i]

    finfo = file_info(fts_file)          ; Get file information.

    ; Read FITS header.

    hdu   = headfits(fts_file, /silent)  ; Read FITS header.

    ; Extract desired items from header.

    bitpix     = sxpar(hdu, 'BITPIX',   count=qbitpix)
    naxis      = sxpar(hdu, 'NAXIS',    count=qnaxis)
    naxis1     = sxpar(hdu, 'NAXIS1',   count=qnaxis1)
    naxis2     = sxpar(hdu, 'NAXIS2',   count=qnaxis2)
    date_obs   = sxpar(hdu, 'DATE-OBS', count=qdate_obs)
    timesys    = sxpar(hdu, 'TIMESYS',  count=qtimesys)
    location   = sxpar(hdu, 'LOCATION', count=qlocation)
    origin     = sxpar(hdu, 'ORIGIN',   count=qorigin)
    telescop   = sxpar(hdu, 'TELESCOP', count=qtelescop)
    instrume   = sxpar(hdu, 'INSTRUME', count=qinstrume)
    object     = sxpar(hdu, 'OBJECT',   count=qobject)
    level      = sxpar(hdu, 'LEVEL',    count=qlevel)
    calfile    = sxpar(hdu, 'CALFILE',  count=qcalfile)
    obsswid    = sxpar(hdu, 'OBSSWID',  count=qobsswid)
    l1swid     = sxpar(hdu, 'L1SWID',   count=ql1swid)
    wcsname    = sxpar(hdu, 'WCSNAME',  count=qwcsname)
    ctype1     = sxpar(hdu, 'CTYPE1',   count=qctype1)
    cdelt1     = sxpar(hdu, 'CDELT1',   count=qcdelt1)
    ctype2     = sxpar(hdu, 'CTYPE2',   count=qctype2)
    cunit1     = sxpar(hdu, 'CUNIT1',   count=qcunit1)
    cunit2     = sxpar(hdu, 'CUNIT2',   count=qcunit2)
    wavelnth   = sxpar(hdu, 'WAVELNTH', count=qwavelnth)
    wavefwhm   = sxpar(hdu, 'WAVEFWHM', count=qwavefwhm)

    ; normalize odd values for date/times
    date_obs = kcor_normalize_datetime(date_obs)

    filetype   = 'fits'
    resolution = cdelt1                   ; arcsec / pixel
    fov_min    = 1018.9 / 960.0           ; largest occulter size.
    fov_max    = (511 * cdelt1) / 960.0   ; outer field-of-view.

    ; Construct variables for database table fields.

    year  = strmid(date_obs, 0, 4)        ; yyyy
    month = strmid(date_obs, 5, 2)        ; mm
    day   = strmid(date_obs, 8, 2)        ; dd

    cal_year  = strmid(calfile, 0, 4)     ; yyyy
    cal_month = strmid(calfile, 4, 2)     ; mm
    cal_day   = strmid(calfile, 6, 2)     ; dd

    ; Determine DOY.

    mday      = [0,31,59,90,120,151,181,212,243,273,304,334]
    mday_leap = [0,31,60,91,121,152,182,213,244,274,305,335] ; leap year 

    if ((fix (year) mod 4) eq 0) then begin
      doy = mday_leap[fix(month) - 1] + fix(day)
    endif else begin
      doy = mday[fix(month) - 1] + fix(day)
    endelse
    doy_str = string(doy, format='(%"%3d")')

    date_dash    = strmid(date_obs, 0, 10)        ; yyyy-mm-dd
    time_obs     = strmid(date_obs, 11, 8)        ; hh:mm:ss
    date_mission = date_dash + ' ' + time_obs     ; yyyy-mm-dd hh:mm:ss

    date_cal  = cal_year + '-' + cal_month + '-' + cal_day
    fits_file = strmid(fts_file, 0, 27)

    ;--- DB insert command.

    db->execute, 'INSERT INTO kcor_mission (date, mlso_url, doi_url, telescope, instrument, location, origin, object, wavelength, wavefwhm, resolution, fov_min, fov_max, bitpix, xdim, ydim) VALUES (''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', %f, %f, %f, %f, %f, %d, %d, %d) ', $
                 date_mission, $
                 run->epoch('mlso_url'), $
                 run->epoch('doi_url'), telescop, instrume, location, $
                 origin, object, wavelnth, wavefwhm, resolution, $
                 fov_min, fov_max, bitpix, naxis1, naxis2, $
                 status=status, error_message=error_message, sql_statement=sql_cmd

    mg_log, '%s: status: %d, error message: %s', status, error_message, $
            name='kcor/eod', /debug
    mg_log, 'sql_cmd: %s', sql_cmd, name='kcor/eod', /debug
    if (i eq 0) then  goto, done
  endwhile

  done:
  obj_destroy, db

  mg_log, '*** end of kcor_mission_insert ***', name='kcor/eod', /info
end
