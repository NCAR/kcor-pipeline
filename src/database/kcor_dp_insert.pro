; docformat = 'rst'

;+
; Insert values into the MLSO database table: kcor_dp.
;
; Reads a list of L1 files for a specified date & inserts a row of data into
; 'kcor_dp'.
;
; :Params:
;   date ; in, type=string  'yyyymmdd'
;
; :Examples: 
;   kcor_dp_insert, '20150324', 'okligz.ls'
;
; :Author: 
;   Andrew Stanger
;   HAO/NCAR  K-coronagraph
;
; :History:
;   11 Sep 2015 IDL procedure created.
;               Use /hao/mlsodata1/Data/KCor/raw/yyyymmdd for L1 fits files.
;   15 Sep 2015 Use /hao/acos/year/month/day directory    for L1 fits files.
;   28 Sep 2015 Remove bitpix, xdim, ydim fields.
;-
pro kcor_dp_insert, date
  compile_opt strictarr
  on_error, 2

  np = n_params() 
  if (np ne 1) then begin
    mg_log, 'missing date parameter', name='kcor', /error
    return
  end

  ;--------------------------
  ; Connect to MLSO database.
  ;--------------------------

  ; Note: The connect procedure accesses DB connection information in the file
  ;       /home/stanger/.mysqldb. The "config_section" parameter specifies
  ;       which group of data to use.

  db = mgdbmysql()
  db->connect, config_filename='/home/stanger/.mysqldb', $
               config_section='stanger@databases'

  db->getProperty, host_name=host
  mg_log, 'connected to %s...', host, name='kcor', /info

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
  pdate_dash = year + '-' + month + '-' + day + '%'	; 'yyyy-mm-dd%'

  db->execute, 'DELETE FROM kcor_dp WHERE date_obs like ''%s''', pdate_dash, $
               status=status, error_message=error_message, sql_statement=sql_cmd
  mg_log, 'sql_cmd: %s', sql_cmd, name='kcor', /info
  mg_log, 'status: %d, error message: %s', status, error_message, $
          name='kcor', /info

  ;-----------------------
  ; Directory definitions.
  ;-----------------------

  fts_dir  = '/hao/acos/' + year + '/' + month + '/' + day
  log_dir  = '/hao/acos/kcor/db/'

  log_file = 'kcor_dp_insert.log'
  log_path = log_dir + log_file

  ;----------------
  ; Move to fts_dir.
  ;----------------

  cd, current=start_dir
  cd, fts_dir

  ;------------------------------------------------
  ; Create list of fits files in current directory.
  ;------------------------------------------------

  fits_list = file_search('*kcor_l1.fts*', count=nfiles)

  if (nfiles EQ 0) then begin
    mg_log, 'No images in list file', name='kcor', /info
    goto, done
  end

  i        = -1
  fts_file = 'img.fts'

  while (++i lt nfiles) do begin
    fts_file = fits_list[i]

    finfo = file_info(fts_file)          ; Get file information.

    ; Read FITS header.

    hdu   = headfits(fts_file, /silent)  ; Read FITS header.

    ; Extract desired items from header.

    date_obs   = sxpar(hdu, 'DATE-OBS', count=qdate_obs)
    bitpix     = sxpar(hdu, 'BITPIX',   count=qbitpix)
    xdim       = sxpar(hdu, 'NAXIS1',   count=qnaxis1)
    ydim       = sxpar(hdu, 'NAXIS2',   count=qnaxis2)
    calfile    = sxpar(hdu, 'CALFILE',  count=qcalfile)
    distort    = sxpar(hdu, 'DISTORT',  count=qdistort)
    dpswid     = sxpar(hdu, 'L1SWID',   count=ql1swid)
    dmodswid   = sxpar(hdu, 'DMODSWID', count=qdmodswid)
    obsswid    = sxpar(hdu, 'OBSSWID',  count=qobsswid)
    bzero      = sxpar(hdu, 'BZERO',    count=qbzero)
    bscale     = sxpar(hdu, 'BSCALE',   count=qbscale)
    bunit      = sxpar(hdu, 'BUNIT',    count=qbunit)
    resolution = sxpar(hdu, 'CDELT1',   count=qcdelt1)

    obsswid    = strtrim (obsswid,  2)	; Remove leading/trailing blanks

    mg_log, 'xdim: %d, ydim: %d', xdim, ydim, name='kcor', /debug

    if (qbunit eq 0) then begin
      bunit = 'quasi-pB'
    endif

    if (qbscale eq 0) then begin
      bscale = 0.001
    endif

    ; Construct variables for database table fields.

    year  = strmid (date_obs, 0, 4)	; yyyy
    month = strmid (date_obs, 5, 2)	; mm
    day   = strmid (date_obs, 8, 2)	; dd

    cal_year  = strmid (calfile, 0, 4)	; yyyy
    cal_month = strmid (calfile, 4, 2)	; mm
    cal_day   = strmid (calfile, 6, 2)	; dd

    ; Determine DOY.

    mday      = [0,31,59,90,120,151,181,212,243,273,304,334]
    mday_leap = [0,31,60,91,121,152,182,213,244,274,305,335] ; leap year

    if ((fix(year) mod 4) eq 0) then begin
      doy = mday_leap[fix(month) - 1] + fix(day)
    endif else begin
      doy = mday[fix(month) - 1] + fix(day)
    endelse
    doy_str = string(doy, format='(%"%3d")')

    date_dash = strmid(date_obs, 0, 10)                  ; yyyy-mm-dd
    time_obs  = strmid(date_obs, 11, 8)                  ; hh:mm:ss
    date_dp   = date_dash + ' ' + time_obs               ; yyyy-mm-dd hh:mm:ss
    date_cal  = cal_year + '-' + cal_month + '-' + cal_day    ; yyyy-mm-dd
    fits_file = strmid(fts_file, 0, 27)                      ; remove '.gz' from file name.

  ;--- DB insert command.

  db->execute, 'INSERT INTO kcor_dp (date, dmodswid, calfile, distort, dpswid, bunit, bzero, bscale) VALUES (''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', %f, %f) ', $
               date_dp, dmodswid, calfile, distort, dpswid, $
               bunit, bzero, bscale, $
               status=status, error_message=error_message, sql_statement=sql_cmd

    mg_log, '%s: status: %d, error message: %s', status, error_message, $
            name='kcor', /debug
    mg_log, 'sql_cmd: %s', sql_cmd, name='kcor', /debug

    if (i eq 0) then goto, done	  ; Process only first fits file in list
  endwhile

  done:
  obj_destroy, db

  mg_log, '*** end of kcor_dp_insert ***', name='kcor', /info
end
