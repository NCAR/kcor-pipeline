; docformat = 'rst'

;+
; Utility to insert values into the MLSO database table: kcor_cal.
;
; Reads a list of L0 cal files for a specified date and inserts a row of data into
; 'kcor_cal'.  As of 20170216, the setup is to pass this script an array of cal filename,
; and the script will look for them in /hao/mlsodata1/Data/KCor/raw/yyyymmdd/level0, however 
; it could easily be edited to read in the list of cal files in:
;  /hao/mlsodata1/Data/KCor/raw/yyyymmdd/q/cal.ls
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;	filelist: in, required, type=array of strings
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;
; :Examples:
;   For example::
;	  date = '20170204'
;     filelist = ['20170214_190402_kcor.fts.gz','20170214_190417_kcor.fts.gz','20170214_190548_kcor.fts.gz','20170214_190604_kcor.fts','20170214_190619_kcor.fts']
;     kcor_cal_insert, date, filelist;
;
; :Author: 
;   Don Kolinski
;   HAO/NCAR  K-coronagraph
;
; :History:
;   20170216 - First version
;-
pro kcor_cal_insert, date, fits_list, run=run
compile_opt strictarr
on_error, 2

np = n_params() 
if (np ne 2) then begin
	print, 'missing date or filelist parameters'
	mg_log, 'missing date or filelist parameters', name='kcor/dbinsert', /error
	return
endif

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

;-------------------------------------------------------------------------------
; Delete all pre-existing rows with date_obs = designated date to be processed.
;-------------------------------------------------------------------------------

year    = strmid(date, 0, 4)	; yyyy
month   = strmid(date, 4, 2)	; mm
day     = strmid(date, 6, 2)	; dd
odate_dash = year + '-' + month + '-' + day + '%'

; TODO: This DELETE statement will need to be removed from this script.  In the new
;   pipeline, kcor data will be processed and added to the database in realtime through 
;   the day, so we don't want to delete previous entries.  However, the statement will 
;   likely be used in an 'update_database' script later. Be sure to note date change to next
;   day. 
;  db->execute, 'DELETE FROM kcor_cal WHERE date_obs like ''%s''', odate_dash, $
;               status=status, error_message=error_message, sql_statement=sql_cmd
;  mg_log, 'sql_cmd: %s', sql_cmd, name='kcor/dbinsert', /info
;  mg_log, 'status: %d, error message: %s', status, error_message, $
;          name='kcor/dbinsert', /info

;-----------------------
; Directory definitions.
;-----------------------

; TODO: Set to cal file directory (confer with Mike and Joan)
fts_dir = filepath('level0', subdir=date, root=run.raw_basedir)
mg_log, 'fts_dir: %s', fts_dir, name='kcor/dbinsert', /info

;----------------
; Move to fts_dir.
;----------------

cd, current=start_dir
cd, fts_dir


;------------------------------------------------
; Step through list of fits files passed in parameter
;------------------------------------------------
nfiles = n_elements(fits_list)

if (nfiles eq 0) then begin
	print, 'no images in fits_list'
	mg_log, 'No images in list file', name='kcor/dbinsert', /info
	goto, done
endif

i = -1
fts_file = 'img.fts'
while (++i lt nfiles) do begin
	fts_file = fits_list[i]
	finfo = file_info(fts_file)         ; Get file information.

	;----- Extract desired items from header.

	hdu   = headfits(fts_file, /silent) ; Read FITS header.
	
	date_obs	= sxpar(hdu, 'DATE-OBS', count=qdate_obs)
	date_end	= sxpar(hdu, 'DATE-END', count=qdate_end)
	
	level		= strtrim(sxpar(hdu, 'LEVEL', count=qlevel), 2)
	; TODO: Older NRGF headers have 'NRGF' appended to level string, but newer headers
	;   will have another keyword added to header for producttype
	os = strpos(level, "NRGF")  
	if (os ne -1) then begin
		level = strmid(level, 0, os)
	endif	
	
	numsum		= sxpar(hdu, 'NUMSUM',   count=qnumsum)
	exptime		= sxpar(hdu, 'EXPTIME',  count=qexptime)
	cover		= strtrim(sxpar(hdu, 'COVER',    count=qcover),2)
	darkshut	= strtrim(sxpar(hdu, 'DARKSHUT', count=qdarkshut),2)
	diffuser	= strtrim(sxpar(hdu, 'DIFFUSER', count=qdiffuser),2)
	calpol		= strtrim(sxpar(hdu, 'CALPOL',   count=qcalpol),2)
	calpang		= sxpar(hdu, 'CALPANG',  count=qcalpang)

;TODO: Get values for these quantities from pipeline output (test values set for now)
mean_int_img0 = 99.99
mean_int_img1 = 99.99
mean_int_img2 = 99.99
mean_int_img3 = 99.99
mean_int_img4 = 99.99
mean_int_img5 = 99.99
mean_int_img6 = 99.99
mean_int_img7 = 99.99
	
	rcamid		= strtrim(sxpar(hdu, 'RCAMID', count=qrcamid),2)
	tcamid		= strtrim(sxpar(hdu, 'TCAMID', count=qtcamid),2)
	rcamlut		= strtrim(sxpar(hdu, 'RCAMLUT', count=qrcamlut),2)
	tcamlut		= strtrim(sxpar(hdu, 'TCAMLUT', count=qtcamlut),2)
	rcamxcen	= sxpar(hdu, 'RCAMXCEN', count=qrcamxcen)
	rcamycen	= sxpar(hdu, 'RCAMYCEN', count=qrcamycen)
	tcamxcen	= sxpar(hdu, 'TCAMXCEN', count=qtcamxcen)
	tcamycen	= sxpar(hdu, 'TCAMYCEN', count=qtcamycen)
	rcam_rad	= sxpar(hdu, 'RCAM_RAD', count=qrcam_rad)
	tcam_rad	= sxpar(hdu, 'TCAM_RAD', count=qtcam_rad)
	rcamfocs	= sxpar(hdu, 'RCAMFOCS', count=qrcamfocs)
	tcamfocs	= sxpar(hdu, 'TCAMFOCS', count=qtcamfocs)
	modltrid	= strtrim(sxpar(hdu, 'MODLTRID', count=qmodltrid),2)
	modltrt		= sxpar(hdu, 'MODLTRT', count=qmodltrt)
	occltrid	= strtrim(sxpar(hdu, 'OCCLTRID', count=qoccltrid),2)
	o1id		= strtrim(sxpar(hdu, 'O1ID', count=qo1id),2)
	o1focs		= sxpar(hdu, 'O1FOCS', count=qo1focs)
	calpolid	= strtrim(sxpar(hdu, 'CALPOLID', count=qcalpolid),2)
	diffsrid	= strtrim(sxpar(hdu, 'DIFFSRID', count=qdiffsrid),2)
	filterid	= strtrim(sxpar(hdu, 'FILTERID', count=qfilterid),2)
	sgsdimv 	= sxpar(hdu, 'SGSDIMV', count=qkcor_sgsdimv)
	sgsdims 	= sxpar(hdu, 'SGSDIMS', count=qkcor_sgsdims)

	fits_file = file_basename(fts_file, '.gz') ; remove '.gz' from file name.

	mg_log, 'date_obs: %s', date_obs, name='kcor/dbinsert', /debug
	mg_log, 'date_end: %s', date_end, name='kcor/dbinsert', /debug
	mg_log, 'level:    %s', level, name='kcor/dbinsert', /debug
	mg_log, 'exptime:  %s', exptime, name='kcor/dbinsert', /debug
	mg_log, 'numsum:   %s', numsum, name='kcor/dbinsert', /debug
	mg_log, 'cover:    %s', cover, name='kcor/dbinsert', /debug
	mg_log, 'darkshut: %s', darkshut, name='kcor/dbinsert', /debug
	mg_log, 'diffuser: %s', diffuser, name='kcor/dbinsert', /debug
	mg_log, 'calpol:   %s', calpol, name='kcor/dbinsert', /debug
	mg_log, 'calplang: %s', calpang, name='kcor/dbinsert', /debug
	
	; Get IDs from relational tables.
	
	level_results = db->query('SELECT * FROM kcor_level WHERE level=''%s''', $
							   level, fields=fields)
	level_num = level_results.level_id
	mg_log, 'level_num:    %d', level_num, name='kcor/dbinsert', /debug

	; DB insert command.

;TODO: Remove _test from table name
	db->execute, 'INSERT INTO kcor_cal_test (file_name, date_obs, date_end, level, numsum, exptime, cover, darkshut, diffuser, calpol, calpang, mean_int_img0, mean_int_img1, mean_int_img2, mean_int_img3, mean_int_img4, mean_int_img5, mean_int_img6, mean_int_img7, rcamid, tcamid, rcamlut, tcamlut, rcamxcen, rcamycen, tcamxcen, tcamycen, rcam_rad, tcam_rad, rcamfocs, tcamfocs, modltrid, modltrt, occltrid, o1id, o1focs, calpolid, diffsrid, filterid, kcor_sgsdimv, kcor_sgsdims) VALUES (''%s'', ''%s'', ''%s'', %d, %d, %f, ''%s'', ''%s'', ''%s'', ''%s'', %f, %f, %f, %f, %f, %f, %f, %f, %f, ''%s'', ''%s'', ''%s'', ''%s'', %f, %f, %f, %f, %f, %f, %f, %f, ''%s'', %f, ''%s'', ''%s'', %f, ''%s'', ''%s'', ''%s'', %f, %f) ', $
				 fits_file, date_obs, date_end, level_num, numsum, $
				 exptime, cover, darkshut, diffuser, calpol, calpang, $
				 mean_int_img0, mean_int_img1, mean_int_img2, mean_int_img3, mean_int_img4, $
				 mean_int_img5, mean_int_img6, mean_int_img7, rcamid, tcamid, rcamlut, tcamlut, $
				 rcamxcen, rcamycen, tcamxcen, tcamycen, rcam_rad, tcam_rad, rcamfocs, tcamfocs, $
				 modltrid, modltrt, occltrid, o1id, o1focs, calpolid, diffsrid, filterid, sgsdimv, sgsdims, $
				 status=status, $
				 error_message=error_message, $
				 sql_statement=sql_cmd

	mg_log, '%d, error message: %s', status, error_message, $
            name='kcor/dbinsert', /debug
    mg_log, 'sql_cmd: %s', sql_cmd, name='kcor/dbinsert', /debug
endwhile

done:
obj_destroy, db

mg_log, '*** end of kcor_cal_insert ***', name='kcor/dbinsert', /info
end

; main-level example program

date = '20170214'
filelist = ['20170214_190402_kcor.fts.gz','20170214_190417_kcor.fts.gz','20170214_190548_kcor.fts.gz','20170214_190604_kcor.fts','20170214_190619_kcor.fts']
run = kcor_run(date, $
               config_filename=filepath('kcor.kolinski.mahi.latest.cfg', $
                                        subdir=['..', '..', 'config'], $
                                        root=mg_src_root()))
kcor_cal_insert, date, filelist, run=run

end