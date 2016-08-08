; docformat = 'rst'

;+
;-------------------------------------------------------------------------------
; kcor_eng_insert.pro
;
; Insert values into the MLSO database table: kcor_eng.
;-------------------------------------------------------------------------------
; Reads a list of L1 files for a specified date & inserts a row of data into
; 'kcor_eng'.
;-------------------------------------------------------------------------------
; :Params:
;   date ; in, type=string  'yyyymmdd'
;
; :Examples: 
;   kcor_eng_insert, '20150324'
;-------------------------------------------------------------------------------
; :Author: 
;   Andrew Stanger
;   HAO/NCAR  K-coronagraph
;
; :History:
;  8 Sep 2015 IDL procedure created.
;             Use /hao/mlsodata1/Data/KCor/raw/yyyymmdd directory.
; 15 Sep 2015 Use /hao/acos/year/month/day directory for L1 fits files.
;-------------------------------------------------------------------------------
;-

pro kcor_eng_insert, date, list

compile_opt strictarr
on_error, 2

np = n_params () 
if (np NE 1) then $
begin ;{
  print, "kcor_eng_insert, 'yyyymmdd'"
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
; Delete all pre-existing rows with date = designated date to be processed.
;-------------------------------------------------------------------------------

year    = strmid (date, 0, 4)	; yyyy
month   = strmid (date, 4, 2)	; mm
day     = strmid (date, 6, 2)	; dd
pdate_dash = year + '-' + month + '-' + day	; 'yyyy-mm-dd%'
pdate_wild = pdate_dash + "%"

db->execute, 'DELETE FROM kcor_eng WHERE date like ''%s''', pdate_wild, status=status, error_message=error_message, sql_statement=sql_cmd

print
print, 'sql_cmd: ', sql_cmd
print, 'status, error: ', status, '   ', error_message
print

;--- Delete table & reset auto-increment value to 1.

;db->execute, 'TRUNCATE TABLE kcor_eng', status=status, error_message=error_message, sql_statement=sql_cmd

;--- Set auto-increment value to 1.

;db->execute, 'ALTER TABLE kcor_eng AUTO_INCREMENT = 1'

print
print, 'sql_cmd: ', sql_cmd
print, 'status, error: ', status, '   ', error_message
print

;-----------------------
; Directory definitions.
;-----------------------

fts_dir  = '/hao/acos/' + year + '/' + month + '/' + day
log_dir  = '/hao/acos/kcor/db/'

log_file = 'kcor_eng_insert.log'
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

  hdu = headfits (fts_file, /SILENT)

  ;--- Extract desired items from header.

  date_obs   = sxpar (hdu, 'DATE-OBS', count=qdate_obs)
  rcamfocs   = sxpar (hdu, 'RCAMFOCS', count=qrcamfocs)
  tcamfocs   = sxpar (hdu, 'TCAMFOCS', count=qtcamfocs)
  modltrt    = sxpar (hdu, 'MODLTRT',  count=qmodltrt)
  o1focs     = sxpar (hdu, 'O1FOCS',   count=q01focs)
  sgsdimv    = sxpar (hdu, 'SGSDIMV',  count=qsgsdimv)
  sgsdims    = sxpar (hdu, 'SGSDIMS',  count=qsgsdims)
  sgssumv    = sxpar (hdu, 'SGSSUMV',  count=qsgssumv)
  sgsrav     = sxpar (hdu, 'SGSRAV',   count=qsgsrav)
  sgsras     = sxpar (hdu, 'SGSRAS',   count=qsgsras)
  sgsrazr    = sxpar (hdu, 'SGSRAZR',  count=qsgsrazr)
  sgsdecv    = sxpar (hdu, 'SGSDECV',  count=qsgsdecv)
  sgsdecs    = sxpar (hdu, 'SGSDECS',  count=qsgsdecs)
  sgsdeczr   = sxpar (hdu, 'SGSDECZR', count=qsgsdeczr)
  sgsscint   = sxpar (hdu, 'SGSSCINT', count=qsgsscint)
  sgssums    = sxpar (hdu, 'SGSSUMS',  count=qsgssums)

  rcamfocs_str = strtrim (string (rcamfocs), 2)
  tcamfocs_str = strtrim (string (tcamfocs), 2)
  print, 'rcamfocs, tcamfocs: ', rcamfocs, tcamfocs
;  if (rcamfocs_str EQ 'NaN') then print, 'rcamfocs: Not a Number'
;  if (tcamfocs_str EQ 'NaN') then print, 'tcamfocs: Not a Number' 
  if (rcamfocs_str EQ 'NaN') then rcamfocs = -99.99
  if (tcamfocs_str EQ 'NaN') then tcamfocs = -99.99

  ;--- Construct variables for database table fields.

  year  = strmid (date_obs, 0, 4)	; yyyy
  month = strmid (date_obs, 5, 2)	; mm
  day   = strmid (date_obs, 8, 2)	; dd

   ;--- Determine DOY.

  mday      = [0,31,59,90,120,151,181,212,243,273,304,334]
  mday_leap = [0,31,60,91,121,152,182,213,244,274,305,335] ;leap year 

  IF ((fix (year) mod 4) EQ 0) THEN $
  doy = mday_leap [fix (month) - 1] + fix (day) $
  ELSE $
  doy = mday [fix (month) - 1] + fix (day)
  doy_str = string (doy, format='(%"%3d")')

  date_dash    = strmid (date_obs, 0, 10)	; yyyy-mm-dd
  time_obs     = strmid (date_obs, 11, 8)	; hh:mm:ss
  date_eng     = date_dash + ' ' + time_obs	; yyyy-mm-dd hh:mm:ss
  fits_file    = strmid (fts_file, 0, 27)	; remove '.gz' from file name.

;--- DB insert command.

  db->execute, 'INSERT INTO kcor_eng (file_name, date, rcamfocs, tcamfocs, modltrt, o1focs, sgsdimv, sgsdims, sgssumv, sgsrav, sgsras, sgsrazr, sgsdecv, sgsdecs, sgsdeczr, sgsscint, sgssums) VALUES (''%s'', ''%s'', %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f) ', fits_file, date_eng, rcamfocs, tcamfocs, modltrt, o1focs, sgsdimv, sgsdims, sgssumv, sgsrav, sgsras, sgsrazr, sgsdecv, sgsdecs, sgsdeczr, sgsscint, sgssums, status=status, error_message=error_message, sql_statement=sql_cmd

  print,       fits_file, '  status: ', strtrim (string (status), 2), $
                          '  error_message: ', error_message
  printf, LOG, fits_file, '  status: ', strtrim (string (status), 2), $
                          '  error_message: ', error_message
  print,       sql_cmd
  printf, LOG, sql_cmd
  print

;  if (i EQ 2) then  goto, DONE
end   ;}
;-------------------------------------------------------------------------------
; End of file loop.
;-------------------------------------------------------------------------------

DONE: $

obj_destroy, db

print,       '*** end of kcor_eng_insert ***'
printf, LOG, '*** end of kcor_eng_insert ***'
close,  LOG
free_lun, LOG

end
