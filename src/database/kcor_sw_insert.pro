; docformat = 'rst'

;+
; Insert values into the MLSO database table: kcor_sw.
;
; Reads a list of L1 files for a specified date and inserts a row of data into
; 'kcor_sw' if any of the monitored fields changed from the previous db entry.  This
; script will check the database against the current data to decide whether a new line 
; should be added
;
; :Params:
;   date : in, type=string
;     date in the form 'YYYYMMDD'
;	filelist: in, required, type=array of strings
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;
; :Examples:
;	  date = '20170204'
;     filelist = ['20170214_190402_kcor.fts.gz','20170214_190417_kcor.fts.gz','20170214_190548_kcor.fts.gz','20170214_190604_kcor.fts','20170214_190619_kcor.fts']
;     kcor_sw_insert, date, filelist;
;
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
;   15 Mar 2017 Edits by D Kolinski to align inserts with kcor_sw db table and to
;                 check for changes in field values compared to previous database entries to
;                 determine whether a new entry is needed.
;-
pro kcor_sw_insert, date, run=run
compile_opt strictarr
on_error, 2

np = n_params() 
if (np ne 2) then begin
print, 'missing date or filelist parameters'
mg_log, 'missing date or filelist parameter', name='kcor/dbinsert', /error
return
end

;--------------------------
; Connect to MLSO database.
;--------------------------

; Note: The connect procedure accesses DB connection information in the file
;       .mysqldb. The "config_section" parameter specifies
;       which group of data to use.

db = mgdbmysql()
db->connect, config_filename=run.database_config_filename, $
		   config_section=run.database_config_section

db->getProperty, host_name=host
mg_log, 'connected to %s...', host, name='kcor/dbinsert', /info

db->setProperty, database='MLSO'


;-----------------------
; Directory definitions.
;-----------------------

year    = strmid(date, 0, 4)	; yyyy
month   = strmid(date, 4, 2)	; mm
day     = strmid(date, 6, 2)	; dd

;TODO: Change to proper processing directory
fts_dir = filepath('', subdir=[year, month, day], root=run.archive_dir)

;----------------
; Move to fts_dir.
;----------------

cd, current=start_dir
cd, fts_dir

;------------------------------------------------
; Loop through fits list
;------------------------------------------------
nfiles = n_elements(fits_list)

if (nfiles eq 0) then begin
	print, 'no images in fits_list'
	mg_log, 'no images in list file', name='kcor/dbinsert', /info
	goto, done
endif

i = -1
fts_file = 'img.fts'
while (++i lt nfiles) do begin
	fts_file = fits_list[i]
	finfo = file_info(fts_file)          ; Get file information.

	; Extract desired items from header.
	
	hdu   = headfits(fts_file, /silent)  ; Read FITS header.  

	date_obs		= sxpar(hdu, 'DATE-OBS', count=qdate_obs)
	dmodswid		= sxpar(hdu, 'DMODSWID', count=qdmodswid)
	distort			= sxpar(hdu, 'DISTORT', count=qdistort)
	l1swid			= sxpar(hdu, 'DPSWID', count=ql1swid)
	datel1			= sxpar(hdu, 'DATE_DP', count=qdatel1)
	l2swid			= sxpar(hdu, '', count=ql2swid)         ; ?
	datel2			= sxpar(hdu, '', count=qdatel2)         ; ?
	bunit			= sxpar(hdu, 'BUNIT', count=qbunit)
	bzero			= sxpar(hdu, 'BZERO', count=qbzero)
	bscale			= sxpar(hdu, 'BSCALE', count=qbscale)
	labviewid		= sxpar(hdu, '', count=qlabviewid)      ; ? OBSSWID?
	socketcamid		= sxpar(hdu, '', count=qsocketcamid)    ; ? 
	sgsswid			= sxpar(hdu, '', count=qsgsswid)        ; put in sgs table?
	
	sky_pol_factor	= sxpar(hdu, '', count=q)               ; from pipeline
	sky_bias		= sxpar(hdu, '', count=q)               ; from pipeline

	if (qbunit eq 0) then begin
	  bunit = 'quasi-pB'
	endif

	if (qbscale eq 0) then begin
	  bscale = 0.001
	endif

	
	;--- DB insert command.

	;TODO: Remove _test from table names
	db->execute, 'INSERT INTO kcor_sw_test (date, dmodswid, distort, l1swid, datel1, l2swid, datel2, bunit, bzero, bscale, labviewid, socketcamid, sgsswid, sky_pol_factor, sky_bias) VALUES (''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', %f, %f, ''%s'', ''%s'', ''%s'', %f, %f) ', $
			   date_obs, dmodswid, distort, l1swid, datel1, l2swid, datel2, bunit, bzero, bscale, labviewid, socketcamid, sgsswid, sky_pol_factor, sky_bias, $
			   status=status, error_message=error_message, sql_statement=sql_cmd

	mg_log, '%s: status: %d, error message: %s', status, error_message, $
			name='kcor/dbinsert', /debug
	mg_log, 'sql_cmd: %s', sql_cmd, name='kcor/dbinsert', /debug

	if (i eq 0) then goto, done	  ; Process only first fits file in list
endwhile

done:
obj_destroy, db

mg_log, '*** end of kcor_sw_insert ***', name='kcor/dbinsert', /info
end

; main-level example program

date = '20170214'
filelist = ['20170214_190402_kcor.fts.gz','20170214_190417_kcor.fts.gz','20170214_190548_kcor.fts.gz','20170214_190604_kcor.fts.gz','20170214_190619_kcor.fts.gz']
run = kcor_run(date, $
		   config_filename=filepath('kcor.kolinski.mahi.latest.cfg', $
									subdir=['..', '..', 'config'], $
									root=mg_src_root()))
kcor_sw_insert, date, filelist, run=run

end