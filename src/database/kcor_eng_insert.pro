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
;	filelist: in, required, type=array of strings
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;
; :Examples:
;   For example:
;	  date = '20170204'
;     filelist = ['20170204_205610_kcor_l1_nrgf.fts.gz','20170204_205625_kcor_l1.fts.gz','20170204_205640_kcor_l1.fts.gz','20170204_205656_kcor_l1.fts.gz','20170204_205711_kcor_l1.fts.gz']
;     kcor_eng_insert, date, filelist
;
; :Author: 
;   Andrew Stanger
;   HAO/NCAR  K-coronagraph
;
; :History:
;   8 Sep 2015 IDL procedure created.
;              Use /hao/mlsodata1/Data/KCor/raw/yyyymmdd directory.
;   15 Sep 2015 Use /hao/acos/year/month/day directory for L1 fits files.
;   14 Feb 2017 - Edits by DJK to work with a filelist and with new database table
;
;-
pro kcor_eng_insert, date, fits_list, run=run
compile_opt strictarr
on_error, 2

np = n_params() 
if (np ne 2) then begin
	mg_log, 'missing date or filelist parameters', name='kcor', /error
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
mg_log, 'connected to %s...', host, name='kcor', /info

db->setProperty, database='MLSO'

year    = strmid (date, 0, 4)             ; yyyy
month   = strmid (date, 4, 2)             ; mm
day     = strmid (date, 6, 2)             ; dd

; Get observation day index
;TODO: I think we want to call mlso_obsday_insert once in the beginning of each batch
;  and then pass it to each of these insert scripts as another parameter.  For now, 
;  however, I will call that function here:
obs_day_num = mlso_obsday_insert(date, run=run)
;mg_log, 'obs_day_num: %d', obs_day_num, name='kcor', /debug

;-----------------------
; Directory definitions.
;-----------------------

; TODO: Set to processing directory (confer with Mike and Joan)
fts_dir = filepath('', subdir=[year, month, day], root=run.archive_basedir)

;----------------
; Move to fts_dir.
;----------------

cd, current=start_dir
cd, fts_dir

;------------------------------------------------
; Step through list of fits files passed in parameter
;------------------------------------------------

;fits_list = filelist
nfiles = n_elements(fits_list)

if (nfiles eq 0) then begin
	mg_log, 'no images in fits list', name='kcor', /info
	goto, done
endif

i = -1
fts_file = 'img.fts'
while (++i lt nfiles) do begin
	fts_file = fits_list[i]

	;TODO: Don't insert non-pB images
	; Get product type from filename and skip inserting of non-pB;  Parse from header when new producttype keyword is added.
	p = strpos(fts_file, "nrgf")
	if (p ne -1) then begin	
		producttype = 'nrgf'
	endif else begin
		producttype = 'pB'
	endelse
	if (producttype eq 'pB') then begin
		; ----- Extract desired items from header.
		
		hdu = headfits(fts_file, /silent) ; Read FITS header.

		date_obs   = sxpar(hdu, 'DATE-OBS', count=qdate_obs)
		
		rcamfocs   = sxpar(hdu, 'RCAMFOCS', count=qrcamfocs)
		rcamfocs_str = strtrim(rcamfocs, 2)
		if (rcamfocs_str eq 'NaN') then rcamfocs = -99.99
		
		tcamfocs   = sxpar(hdu, 'TCAMFOCS', count=qtcamfocs)
		tcamfocs_str = strtrim(tcamfocs, 2)
		if (tcamfocs_str eq 'NaN') then tcamfocs = -99.99
		
		modltrt    = sxpar(hdu, 'MODLTRT', count=qmodltrt)
		o1focs     = sxpar(hdu, 'O1FOCS', count=q01focs)
		sgsdimv    = sxpar(hdu, 'SGSDIMV', count=qsgsdimv)
		sgsdims    = sxpar(hdu, 'SGSDIMS', count=qsgsdims)
		
		level      = strtrim(sxpar(hdu, 'LEVEL', count=qlevel),2)
		; TODO: Older NRGF headers have 'NRGF' appended to level string, but newer headers
		;   will have another keyword added to header for producttype
		os = strpos(level, "NRGF")  
		if (os ne -1) then begin
			level = strmid(level, 0, os) ; Strip off NRGF from level, if present
		endif	
		
		bunit      = strtrim(sxpar(hdu, 'BUNIT',  count=qbunit),2)
		bzero	   = sxpar(hdu, 'BZERO',  count=qbzero)
		bscale     = sxpar(hdu, 'BSCALE',  count=qbscale)
		rcamxcen   = sxpar(hdu, 'RCAMXCEN',  count=qrcamxcen)
		rcamycen   = sxpar(hdu, 'RCAMYCEN',  count=qrcamycen)
		tcamxcen   = sxpar(hdu, 'TCAMXCEN',  count=qtcamxcen)
		tcamycen   = sxpar(hdu, 'TCAMYCEN',  count=qtcamycen)
		rcam_rad   = sxpar(hdu, 'RCAM_RAD',  count=qrcamrad)
		tcam_rad   = sxpar(hdu, 'TCAM_RAD',  count=qtcamrad)
		cover      = strtrim(sxpar(hdu, 'COVER',  count=qcover),2)
		darkshut   = strtrim(sxpar(hdu, 'DARKSHUT',  count=qdarkshut),2)
		diffuser   = strtrim(sxpar(hdu, 'DIFFUSER',  count=qdarkshut),2)
		calpol     = strtrim(sxpar(hdu, 'CALPOL',  count=qcalpol),2)

	; TODO: get mean_phase1 from pipeline output because it is not in header
	mean_phase1 = 99.99 ; just for testing
	 
		fits_file = file_basename(fts_file, '.gz') ; remove '.gz' from file name.
		
		; Debug prints
		;mg_log, 'fits_file:   %s', fits_file, name='kcor', /debug
		;mg_log, 'date_obs:    %s', date_obs, name='kcor', /debug	
		
		; Get IDs from relational tables.
		
		level_count = db->query('SELECT count(level_id) FROM kcor_level WHERE level=''%s''', $
								 level, fields=fields)
		if (level_count.COUNT_LEVEL_ID_ eq 0) then begin
			; If given level is not in the kcor_level table, set it to 'unknown' and log error
			level = 'unk'
			mg_log, 'level: %s', level, name='kcor', /error
		endif
		level_results = db->query('SELECT * FROM kcor_level WHERE level=''%s''', $
									 level, fields=fields)
		level_num = level_results.level_id	
		;mg_log, 'level_num: %d', level_num, name='kcor', /debug
		
		; ----- DB insert command.
	
		db->execute, 'INSERT INTO kcor_eng (file_name, date_obs, obs_day, rcamfocs, tcamfocs, modltrt, o1focs, kcor_sgsdimv, kcor_sgsdims, level, bunit, bzero, bscale, rcamxcen, rcamycen, tcamxcen, tcamycen, rcam_rad, tcam_rad, mean_phase1, cover, darkshut, diffuser, calpol) VALUES (''%s'', ''%s'', %d, %f, %f, %f, %f, %f, %f, %d, ''%s'', %d, %f, %f, %f, %f, %f, %f, %f, %f, ''%s'', ''%s'', ''%s'', ''%s'') ', $
				   fits_file, date_obs, obs_day_num, rcamfocs, tcamfocs, modltrt, o1focs, $
				   sgsdimv, sgsdims, level_num, bunit, bzero, bscale, $
				   rcamxcen, rcamycen, tcamxcen, tcamycen, rcam_rad, tcam_rad, $
				   mean_phase1, cover, darkshut, diffuser, calpol, $
				   status=status, error_message=error_message, sql_statement=sql_cmd

		mg_log, '%d, error message: %s', status, error_message, $
				name='kcor', /debug
		mg_log, 'sql_cmd: %s', sql_cmd, name='kcor', /debug	
	endif		
endwhile

done:
obj_destroy, db

mg_log, '*** end of kcor_eng_insert ***', name='kcor', /info
end


; main-level example program

date = '20170204'
filelist = ['20170204_205610_kcor_l1_nrgf.fts.gz','20170204_205625_kcor_l1.fts.gz','20170204_205640_kcor_l1.fts.gz','20170204_205656_kcor_l1.fts.gz','20170204_205711_kcor_l1.fts.gz']
run = kcor_run(date, $
               config_filename=filepath('kcor.kolinski.mahi.latest.cfg', $
                                        subdir=['..', '..', 'config'], $
                                        root=mg_src_root()))
kcor_eng_insert, date, filelist, run=run

end