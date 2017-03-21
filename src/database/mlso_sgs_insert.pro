; docformat = 'rst'

;+
; Insert values into the MLSO database table: mlso_sgs.
;
; Reads a list of L1 files for a specified date and inserts a row of data into
; 'kcor_sgs'.  TODO: will also need to read from sgs text files.
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
;     mlso_sgs_insert, date, filelist
;
; :Author: 
;   Don Kolinski
;   HAO/NCAR  K-coronagraph
;
; :History:
;   10 March, 2017 - Edits by DJK to work with a filelist and with new sgs database table
;
;-
pro mlso_sgs_insert, date, fits_list, run=run
compile_opt strictarr
on_error, 2

np = n_params() 
if (np ne 2) then begin
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

year    = strmid (date, 0, 4)             ; yyyy
month   = strmid (date, 4, 2)             ; mm
day     = strmid (date, 6, 2)             ; dd
sgs_source = ''							  ; 'k' or 's'  (kcor or sgs)
  
; Get observation day index
;TODO: I think we want to call mlso_obsday_insert once in the beginning of each batch
;  and then pass it to each of these insert scripts as another parameter.  For now, 
;  however, I will call that function here:
obs_day_num = mlso_obsday_insert(date, run=run)
;mg_log, 'obs_day_num: %d', obs_day_num, name='kcor/dbinsert', /debug
  
  
;-----------------------
; Directory definitions.
;-----------------------

;TODO: We may also want to pass sgs text files within fits_list, so need
;  to test and parse accordingly.

; TODO: Set to relevant directory (confer with Mike and Joan)
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
	mg_log, 'no images in fits list', name='kcor/dbinsert', /info
	goto, done
endif

i = -1
fts_file = 'img.fts'
while (++i lt nfiles) do begin
	fts_file = fits_list[i]

	;TODO: Don't insert non-pB images?  Seems like we wouldn't need the sgs values from a NRGF image.
	; Get product type from filename and skip inserting of non-pB;  Parse from header when new producttype keyword is added.
	p = strpos(fts_file, "nrgf")
	if (p ne -1) then begin	
		producttype = 'nrgf'
	endif else begin
		producttype = 'pB'
	endelse

	if (producttype eq 'pB') then begin
		; If in this conditional, then the source is kcor
		sgs_source = 'k'

		; ----- Extract desired items from header.		
		hdu = headfits(fts_file, /silent) ; Read FITS header.

		date_obs	= sxpar(hdu, 'DATE-OBS', count=qdate_obs)
		sgsdimv		= sxpar(hdu, 'SGSDIMV', count=qsgsdimv)
		sgsdims		= sxpar(hdu, 'SGSDIMS', count=qsgsdims)
		sgssumv		= sxpar(hdu, 'SGSSUMV', count=qsgssumv)
		sgsrav		= sxpar(hdu, 'SGSRAV', count=qsgsrav)
		sgsras		= sxpar(hdu, 'SGSRAS', count=qsgsras)
		sgsrazr		= sxpar(hdu, 'SGSRAZR', count=qsgsrazr)
		sgsdecv		= sxpar(hdu, 'SGSDECV', count=qsgsdecv)
		sgsdecs		= sxpar(hdu, 'SGSDECS', count=qsgsdecs)
		sgsdeczr	= sxpar(hdu, 'SGSDECZR', count=qsgsdeczr)
		sgsscint	= sxpar(hdu, 'SGSSCINT', count=qsgsscint)
		sgssums		= sxpar(hdu, 'SGSSUMS', count=qsgssums)
		sgsloop		= sxpar(hdu, 'SGSLOOP', count=qsgsloop)
		

		;fits_file = file_basename(fts_file, '.gz') ; remove '.gz' from file name.
		
		; Debug prints
		;mg_log, 'date_obs:    %s', date_obs, name='kcor/dbinsert', /debug	
		

		; ----- DB insert command.
	
		db->execute, 'INSERT INTO mlso_sgs (date_obs, obs_day, source, sgsdimv, sgsdims, sgssumv, sgsrav, sgsras, sgsrazr, sgsdecv, sgsdecs, sgsdeczr, sgsscint, sgssums, sgsloop) VALUES (''%s'', %d, ''%s'', %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %d) ', $
				   date_obs, obs_day_num, sgs_source, sgsdimv, sgsdims, sgssumv, sgsrav, sgsras, sgsrazr, sgsdecv, sgsdecs, sgsdeczr, sgsscint, sgssums, sgsloop, $
				   status=status, error_message=error_message, sql_statement=sql_cmd

		mg_log, '%d, error message: %s', status, error_message, $
				name='kcor/dbinsert', /debug
		mg_log, 'sql_cmd: %s', sql_cmd, name='kcor/dbinsert', /debug	
	endif		
endwhile

done:
obj_destroy, db

mg_log, '*** end of mlso_sgs_insert ***', name='kcor/dbinsert', /info
end


; main-level example program

date = '20170204'
filelist = ['20170204_205610_kcor_l1_nrgf.fts.gz','20170204_205625_kcor_l1.fts.gz','20170204_205640_kcor_l1.fts.gz','20170204_205656_kcor_l1.fts.gz','20170204_205711_kcor_l1.fts.gz']
run = kcor_run(date, $
               config_filename=filepath('kcor.kolinski.mahi.latest.cfg', $
                                        subdir=['..', '..', 'config'], $
                                        root=mg_src_root()))
mlso_sgs_insert, date, filelist, run=run

end