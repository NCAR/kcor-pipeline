; docformat = 'rst'

;+
;-------------------------------------------------------------------------------
; kcor_cal_insert.pro
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
; 28 Sep 2015 IDL procedure created.  
;             Use /hao/mlsodata1/Data/raw/yyyymmdd/level1 directory.
;-------------------------------------------------------------------------------
;-

pro kcor_cal_insert, date

compile_opt strictarr
on_error, 2

np = n_params () 
if (np NE 1) then $
begin ;{
  print, "kcor_cal_insert, 'yyyymmdd'"
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

db->execute, 'DELETE FROM kcor_cal WHERE date_obs like ''%s''', odate_dash, status=status, error_message=error_message, sql_statement=sql_cmd
print
print, 'sql_cmd: ', sql_cmd
print, 'status, error: ', status, '   ', error_message
print

;-----------------------
; Directory definitions.
;-----------------------

raw_dir = '/hao/mlsodata1/Data/KCor/raw/'
fts_dir = raw_dir + date + '/level0'
;fts_dir = '/hao/acos/' + year + '/' + month + '/' + day
log_dir = '/hao/acos/kcor/db/'

log_file = 'kcor_cal_insert.log'
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

fits_list = FILE_SEARCH ('*kcor.fts*', count=nfiles)

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
print, 'nfiles: ', nfiles

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
  cover      = sxpar (hdu, 'COVER',    count=qcover)
  darkshut   = sxpar (hdu, 'DARKSHUT', count=qdarkshut)
  diffuser   = sxpar (hdu, 'DIFFUSER', count=qdiffuser)
  calpol     = sxpar (hdu, 'CALPOL',   count=qcalpol)
  calpang    = sxpar (hdu, 'CALPANG',  count=qcalpang)

;  print, 'i, fts_file, datatype: ', i, ' ', fts_file, ' ', datatype
  datatype_str = strtrim (datatype, 2)
  if (datatype_str NE 'calibration') then continue   ; only process cal images.

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
  print, 'cover:    ', cover
  print, 'darkshut: ', darkshut
  print, 'diffuser: ', diffuser
  print, 'calpol:   ', calpol
  print, 'calplang: ', calpang

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

  print, 'date_img: ', date_img
  print, 'date_eod: ', date_eod

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

  db->execute, 'INSERT INTO kcor_cal (file_name, date_obs, date_end, instrument, level, numsum, exptime, cover, darkshut, diffuser, calpol, calpang) VALUES (''%s'', ''%s'', ''%s'', ''%s'', ''%s'', %d, %f, ''%s'', ''%s'', ''%s'', ''%s'', %f) ', fits_file, date_img, date_eod, instrume, level_str, numsum, exptime, cover, darkshut, diffuser, calpol, calpang, status=status, error_message=error_message, sql_statement=sql_cmd

  print,       fits_file, '  status: ', strtrim (string (status), 2), $
                          '  error_message: ', error_message
  printf, LOG, fits_file, '  status: ', strtrim (string (status), 2), $
                          '  error_message: ', error_message
;  print,       sql_cmd
  printf, LOG, sql_cmd
  print

;  if (i EQ 3) then  goto, DONE
end   ;}
;-------------------------------------------------------------------------------
; End of file loop.
;-------------------------------------------------------------------------------

DONE: $

obj_destroy, db

print,       '*** end of kcor_cal_insert ***'
printf, LOG, '*** end of kcor_cal_insert ***'
close,  LOG
free_lun, LOG

end
