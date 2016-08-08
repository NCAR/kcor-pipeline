; docformat = 'rst'

;+
;-------------------------------------------------------------------------------
; kcor_img_insert.pro
;
; Utility to insert values into the MLSO database table: kcor_img.
;-------------------------------------------------------------------------------
; Reads a list of L1 files for a specified date & inserts a row of data into
; 'kcor_img'.
;-------------------------------------------------------------------------------
; :Params:
;   date ; in, type=string  'yyyymmdd'
;
; :Examples: 
;   kcor_img_insert, '20150324', 'okligz.ls'
;-------------------------------------------------------------------------------
; :Author: 
;   Andrew Stanger
;   HAO/NCAR  K-coronagraph
;
; :History:
; 11 Sep 2015 IDL procedure created.  
;             Use /hao/mlsodata1/Data/raw/yyyymmdd/level1 directory.
; 14 Sep 2015 Use /hao/acos/year/month/day directory.
; 28 Sep 2015 Add date_end field.
;
; :todo:
; Get image quality to fill "quality" field in db.
; Add field for raw occulter center.
; Add field for sky polarization coefficients
; Add field for modulation matrix coefficients (at 3 pixels).
;-------------------------------------------------------------------------------
;-

pro kcor_img_insert, date

compile_opt strictarr
on_error, 2

np = n_params () 
if (np NE 1) then $
begin ;{
  print, "kcor_img_insert, 'yyyymmdd'"
  return
end   ;}

;--------------------------
; Connect to MLSO database.
;--------------------------

; Note: The connect procedure accesses DB connection information
;       in the file: "/home/stanger/.mysqldb".
;       The "config_section" parameter specifies which group of data to use.

db = mgdbmysql ()
db->connect, config_filename='/home/stanger/.mysqldb', $
             config_section='stanger@databases

db->getProperty, host_name=host
print, host, format='(%"connected to %s...\n")'

db->setProperty, database='MLSO'

;----------------------------------
; Print DB tables in MLSO database.
;----------------------------------

print
print, db, format='(A, /, 4(A-20))'
print

;-------------------------------------------------------------------------------
; Delete all pre-existing rows with date_obs = designated date to be processed.
;-------------------------------------------------------------------------------

year    = strmid (date, 0, 4)	; yyyy
month   = strmid (date, 4, 2)	; mm
day     = strmid (date, 6, 2)	; dd
odate_dash = year + '-' + month + '-' + day + '%'

db->execute, 'DELETE FROM kcor_img WHERE date_obs like ''%s''', odate_dash, status=status, error_message=error_message, sql_statement=sql_cmd
print
print, 'sql_cmd: ', sql_cmd
print, 'status, error: ', status, '   ', error_message
print

;-----------------------
; Directory definitions.
;-----------------------

fts_dir  = '/hao/acos/' + year + '/' + month + '/' + day
log_dir  = '/hao/acos/kcor/db/'

log_file = 'kcor_img_insert.log'
log_path = log_dir + log_file

;---------------
; Open log file.
;---------------

get_lun, LOG
close,   LOG
openw,   LOG, log_path

;----------------
; Move to fts_dir.
;----------------

cd, current=start_dir
cd, fts_dir

;------------------------------------------------
; Create list of fits files in current directory.
;------------------------------------------------

fits_list = FILE_SEARCH ('*kcor_l1.fts*', count=nfiles)

if (nfiles EQ 0) then $
begin ;{
  print, 'No images in list file. '
  goto, DONE
end   ;}

;-------------------------------------------------------------------------------
; File loop:
;-------------------------------------------------------------------------------

i       = -1
fts_file = 'img.fts'

while (++i LT nfiles) do $
begin ;{
  fts_file = fits_list [i]

  finfo = FILE_INFO (fts_file)		; Get file information.

  ;--- Read FITS header.

  hdu   = headfits (fts_file, /SILENT)	; Read FITS header.

  datatype = 'unknown'
  instrume = 'missing_keyword'

  ;--- Extract desired items from header.

  date_obs   = sxpar (hdu, 'DATE-OBS', count=qdate_obs)
  date_end   = sxpar (hdu, 'DATE-END', count=qdate_end)
  telescop   = sxpar (hdu, 'TELESCOP', count=qtelescop)
  instrume   = sxpar (hdu, 'INSTRUME', count=qinstrume)
  datatype   = sxpar (hdu, 'DATATYPE', count=qdatatype)
  level      = sxpar (hdu, 'LEVEL',    count=qlevel)
  exptime    = sxpar (hdu, 'EXPTIME',  count=qexptime)
  numsum     = sxpar (hdu, 'NUMSUM',   count=qnumsum)
  rsun       = sxpar (hdu, 'RSUN',     count=qrsun)
  solar_p0   = sxpar (hdu, 'SOLAR_P0', count=qsolar_p0)
  carr_lat   = sxpar (hdu, 'CRLT_OBS', count=qcrlt_obs)
  carr_lon   = sxpar (hdu, 'CRLN_OBS', count=qcrln_obs)
  carr_rot   = sxpar (hdu, 'CAR_ROT',  count=car_rot)
  solar_ra   = sxpar (hdu, 'SOLAR_RA', count=qsolar_ra)
  solardec   = sxpar (hdu, 'SOLARDEC', count=qsolardec)

  level_str = strtrim (string (level), 2)
  quality    = 'u'
  filetype   = 'fits'

  print, 'date_obs: ', date_obs
  print, 'date_end: ', date_end
  print, 'telescop: ', telescop
  print, 'instrume: ', instrume
  print, 'datatype: ', datatype
  print, 'level:    ', level
  print, 'exptime:  ', exptime
  print, 'numsum:   ', numsum
  print, 'rsun:     ', rsun
  print, 'solar_p0: ', solar_p0
  print, 'carr_lat: ', carr_lat
  print, 'carr_lon: ', carr_lon
  print, 'carr_rot: ', carr_rot
  print, 'solar_ra: ', solar_ra
  print, 'solardec: ', solardec

  if (qdatatype EQ 0) then $
  begin
    print, 'qdatatype: ', qdatatype
    datatype = 'unknown'
  end

  if (qinstrume EQ 0) then $
  begin
    print, 'qinstrume: ', qinstrume
    instrume = telescop
  end

  ;--- Construct variables for database table fields.

  year  = strmid (date_obs, 0, 4)	; yyyy
  month = strmid (date_obs, 5, 2)	; mm
  day   = strmid (date_obs, 8, 2)	; dd

;  cal_year  = strmid (calfile, 0, 4)	; yyyy
;  cal_month = strmid (calfile, 4, 2)	; mm
;  cal_day   = strmid (calfile, 6, 2)	; dd

   ;--- Determine DOY.

  mday      = [0,31,59,90,120,151,181,212,243,273,304,334]
  mday_leap = [0,31,60,91,121,152,182,213,244,274,305,335] ;leap year 

  IF ((fix (year) mod 4) EQ 0) THEN $
  doy = mday_leap [fix (month) - 1] + fix (day) $
  ELSE $
  doy = mday [fix (month) - 1] + fix (day)
  doy_str = string (doy, format='(%"%3d")')

  date_dash = strmid (date_obs, 0, 10)		; yyyy-mm-dd
  time_obs  = strmid (date_obs, 11, 8)		; hh:mm:ss
  date_img  = date_dash + ' ' + time_obs	; yyyy-mm-dd hh:mm:ss

  date_dash = strmid (date_end, 0, 10)		; yyyy-mm-dd
  time_obs  = strmid (date_end, 11, 8)		; hh:mm:ss
  date_eod  = date_dash + ' ' + time_obs	; yyyy-mm-dd hh:mm:ss

  fits_file = strmid (fts_file, 0, 27)		; remove '.gz' from file name.

;  print, 'date_dash:    ', date_dash
;  print, 'doy_str:      ', doy_str
;  print, 'fits_file:    ', fits_file
;  print

;--- Encode index columns.

  instrume_results = db->query ('SELECT * FROM instrume WHERE instrument=''%s''', instrume, fields=fields)
  instrume_num = instrume_results.id
  print, 'instrume:            ', instrume
  print, 'instrume_results.id: ', instrume_results.id

  quality_results = db->query ('SELECT * FROM quality WHERE quality=''%s''', quality, fields=fields)
  quality_num = quality_results.id
  print, 'quality:             ', quality
  print, 'quality_results.id:  ', quality_results.id

  filetype_results = db->query ('SELECT * FROM filetype WHERE filetype=''%s''', filetype, fields=fields)
  filetype_num = filetype_results.id
  print, 'filetype:            ', filetype
  print, 'filetype_results.id: ', filetype_results.id

  level_results = db->query ('SELECT * FROM level WHERE level=''%s''', level, fields=fields)
  level_num = level_results.id
  print, 'level:               ', level
  print, 'level_results.id:    ', level_results.id

;--- DB insert command.

  db->execute, 'INSERT INTO kcor_img (file_name, date_obs, date_end, instrument, level, datatype, quality, numsum, exptime, rsun, solar_p0, carr_lat, carr_lon, carr_rot, solar_ra, solardec) VALUES (''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', %d, %f, %f, %f, %f, %f, %f, %f, %f) ', fits_file, date_img, date_eod, instrume, level_str, datatype, quality, numsum, exptime, rsun, solar_p0, carr_lon, carr_lat, carr_rot, solar_ra, solardec, status=status, error_message=error_message, sql_statement=sql_cmd

  print,       fits_file, '  status: ', strtrim (string (status), 2), $
                          '  error_message: ', error_message
  printf, LOG, fits_file, '  status: ', strtrim (string (status), 2), $
                          '  error_message: ', error_message
  print,       sql_cmd
  printf, LOG, sql_cmd
  print

;  if (i EQ 3) then  goto, DONE
end   ;}
;-------------------------------------------------------------------------------
; End of file loop.
;-------------------------------------------------------------------------------

DONE: $

obj_destroy, db

print,       '*** end of kcor_img_insert ***'
printf, LOG, '*** end of kcor_img_insert ***'
close,  LOG
free_lun, LOG

end
