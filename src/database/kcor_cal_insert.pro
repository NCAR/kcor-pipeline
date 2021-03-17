; docformat = 'rst'

;+
; Utility to insert values into the MLSO database table: kcor_cal.
;
; Reads a list of L0 cal files for a specified date and inserts a row of data
; into 'kcor_cal' table. As of 20170216, the setup is to pass this script an
; array of cal filename, and the script will look for them in the level0
; directory.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;   filelist: in, required, type=array of strings
;     array of FITS files to insert into the database
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;   obsday_index : in, required, type=integer
;     index into mlso_numfiles database table
;   database : in, optional, type=KCordbMySql object
;     database connection to use
;
; :Examples:
;   For example::
;
;     date = '20170204'
;     filelist = ['20170214_190402_kcor.fts.gz', '20170214_190417_kcor.fts.gz']
;     kcor_cal_insert, date, filelist, run=run, obsday_index=obsday_index
;
; :Author: 
;   Don Kolinski
;   HAO/NCAR  K-coronagraph
;
; :History:
;   20170216 - First version, with all cal fields from spreadsheet plan
;-
pro kcor_cal_insert, date, fits_list, quality, $
                     catalog_dir=catalog_dir, $
                     run=run, $
                     database=db, $
                     obsday_index=obsday_index
  compile_opt strictarr
  on_error, 2

  ; connect to MLSO database
  db->getProperty, host_name=host
  mg_log, 'using connection to %s', host, name='kcor/eod', /debug

  l0_dir = filepath('level0', subdir=date, root=run->config('processing/raw_basedir'))
  _catalog_dir = n_elements(catalog_dir) eq 0L ? l0_dir : catalog_dir

  cd, current=start_dir
  cd, _catalog_dir

  ; step through list of fits files passed in parameter
  nfiles = n_elements(fits_list)
  if (nfiles eq 0) then begin
    mg_log, 'no images in list file', name='kcor/eod', /info
    goto, done
  endif

  i = -1
  while (++i lt nfiles) do begin
    fts_file = fits_list[i]

    ; allow compressed or uncompressed files to be passed in
    if (~file_test(fts_file)) then fts_file += '.gz'

    if (~file_test(fts_file)) then begin
      mg_log, '%s not found', fts_file, name='kcor/eod', /warn
      continue
    endif else begin
      mg_log, 'db inserting %s', fts_file, name='kcor/eod', /info
    endelse

    kcor_read_rawdata, fts_file, header=hdu, $
                       repair_routine=run->epoch('repair_routine'), $
                       xshift=run->epoch('xshift_camera'), $
                       start_state=run->epoch('start_state'), $
                       raw_data_prefix=run->epoch('raw_data_prefix'), $
                       datatype=run->epoch('raw_datatype')
	
    date_obs    = sxpar(hdu, 'DATE-OBS', count=qdate_obs)
    date_end    = sxpar(hdu, 'DATE-END', count=qdate_end)

    ; normalize odd values for date/times, particularly "60" as minute value in
    ; DATE-END
    date_obs = kcor_normalize_datetime(date_obs, error=error)
    date_end = kcor_normalize_datetime(date_end, error=error)
    if (error ne 0L) then begin
      date_end = kcor_normalize_datetime(date_obs, error=error, /add_15)
    endif
    run.time = date_obs

    level       = strtrim(sxpar(hdu, 'LEVEL', count=qlevel), 2)
    ; TODO: Older NRGF headers have 'NRGF' appended to level string, but newer headers
    ;   will have another keyword added to header for producttype
    os = strpos(level, 'NRGF')
    if (os ne -1) then begin
      level = strmid(level, 0, os)
    endif	

    numsum      =         sxpar(hdu, 'NUMSUM',   count=qnumsum)
    exptime     =         sxpar(hdu, 'EXPTIME',  count=qexptime)
    if (~run->epoch('use_exptime')) then exptime = run->epoch('exptime')

    cover       = strtrim(sxpar(hdu, 'COVER',    count=qcover), 2)
    darkshut    = strtrim(sxpar(hdu, 'DARKSHUT', count=qdarkshut), 2)
    diffuser    = strtrim(sxpar(hdu, 'DIFFUSER', count=qdiffuser), 2)
    calpol      = strtrim(sxpar(hdu, 'CALPOL',   count=qcalpol), 2)
    calpang     =         sxpar(hdu, 'CALPANG',  count=qcalpang)

    kcor_read_rawdata, fts_file, image=image, $
                       repair_routine=run->epoch('repair_routine'), $
                       xshift=run->epoch('xshift_camera'), $
                       start_state=run->epoch('start_state'), $
                       raw_data_prefix=run->epoch('raw_data_prefix'), $
                       datatype=run->epoch('raw_datatype')
    mean_int_img0 = mean(image[*, *, 0, 0])
    mean_int_img1 = mean(image[*, *, 1, 0])
    mean_int_img2 = mean(image[*, *, 2, 0])
    mean_int_img3 = mean(image[*, *, 3, 0])
    mean_int_img4 = mean(image[*, *, 0, 1])
    mean_int_img5 = mean(image[*, *, 1, 1])
    mean_int_img6 = mean(image[*, *, 2, 1])
    mean_int_img7 = mean(image[*, *, 3, 1])
	
    rcamid   = strtrim(sxpar(hdu, 'RCAMID', count=qrcamid), 2)
    tcamid   = strtrim(sxpar(hdu, 'TCAMID', count=qtcamid), 2)
    rcamlut  = strtrim(sxpar(hdu, 'RCAMLUT', count=qrcamlut), 2)
    tcamlut  = strtrim(sxpar(hdu, 'TCAMLUT', count=qtcamlut), 2)
    rcamfocs =         sxpar(hdu, 'RCAMFOCS', count=qrcamfocs)
    tcamfocs =         sxpar(hdu, 'TCAMFOCS', count=qtcamfocs)
    ;TODO: Deal with NaN (where else can we expect it?)
    if (strtrim(rcamfocs, 2) eq 'NaN') then begin
      rcamfocs = -999.990
    endif
    if (strtrim(tcamfocs, 2) eq 'NaN') then begin
      tcamfocs = -999.990
    endif
    modltrid    = strtrim(sxpar(hdu, 'MODLTRID', count=qmodltrid), 2)
    modltrt     =         sxpar(hdu, 'MODLTRT',  count=qmodltrt)

    if (run->epoch('use_occulter_id')) then begin
      occltrid = strtrim(sxpar(hdu, 'OCCLTRID', count=qoccltrid), 2)
    endif else begin
      occltrid = run->epoch('occulter_id')
    endelse

    o1id        = strtrim(sxpar(hdu, 'O1ID',     count=qo1id),2)
    o1focs      =         sxpar(hdu, 'O1FOCS',   count=qo1focs)
    calpolid    = strtrim(sxpar(hdu, 'CALPOLID', count=qcalpolid), 2)
    diffsrid    = strtrim(sxpar(hdu, 'DIFFSRID', count=qdiffsrid), 2)
    filterid    = strtrim(sxpar(hdu, 'FILTERID', count=qfilterid), 2)
    if (run->epoch('use_sgs')) then begin
      sgsdimv_str = kcor_getsgs(hdu, 'SGSDIMV')
      sgsdims_str = kcor_getsgs(hdu, 'SGSDIMS')
    endif else begin
      sgsdimv_str = 'NULL'
      sgsdims_str = 'NULL'
    endelse

    fits_file = file_basename(fts_file, '.gz') ; remove '.gz' from file name
	
    ; get IDs from relational tables
    level_count = db->query('select count(level_id) from kcor_level where level=''%s''', $
                            level, fields=fields, status=status)
    if (status ne 0L) then goto, done
    if (level_count.count_level_id_ eq 0) then begin
      ; If given level is not in the kcor_level table, set it to 'unknown' and log error
      level = 'unk'
      mg_log, 'level: %s', level, name='kcor/eod', /error
    endif
    level_results = db->query('select * from kcor_level where level=''%s''', $
                              level, fields=fields, status=status)
    if (status ne 0L) then goto, done
    level_num = level_results.level_id	
    
    db->execute, 'insert into kcor_cal (file_name, date_obs, date_end, obs_day, level, quality, numsum, exptime, cover, darkshut, diffuser, calpol, calpang, mean_int_img0, mean_int_img1, mean_int_img2, mean_int_img3, mean_int_img4, mean_int_img5, mean_int_img6, mean_int_img7, rcamid, tcamid, rcamlut, tcamlut, rcamfocs, tcamfocs, modltrid, modltrt, occltrid, o1id, o1focs, calpolid, diffsrid, filterid, kcor_sgsdimv, kcor_sgsdims) values (''%s'', ''%s'', ''%s'', %d, %d, %d, %d, %f, ''%s'', ''%s'', ''%s'', ''%s'', %f, %f, %f, %f, %f, %f, %f, %f, %f, ''%s'', ''%s'', ''%s'', ''%s'', %f, %f, ''%s'', %f, ''%s'', ''%s'', %f, ''%s'', ''%s'', ''%s'', %s, %s) ', $
                 fits_file, date_obs, date_end, obsday_index, level_num, quality[i], $
                 numsum, exptime, cover, darkshut, diffuser, calpol, calpang, $
                 mean_int_img0, mean_int_img1, mean_int_img2, mean_int_img3, $
                 mean_int_img4, mean_int_img5, mean_int_img6, mean_int_img7, $
                 rcamid, tcamid, rcamlut, tcamlut, rcamfocs, tcamfocs, $
                 modltrid, modltrt, occltrid, o1id, o1focs, calpolid, $
                 diffsrid, filterid, sgsdimv_str, sgsdims_str, $
                 status=status, $
                 error_message=error_message, $
                 sql_statement=sql_cmd
    if (status ne 0L) then continue
  endwhile

  done:
  cd, start_dir

  mg_log, 'done', name='kcor/eod', /info
end


; main-level example program

date = '20170318'
filelist = ['20170318_205523_kcor.fts.gz','20170318_205538_kcor.fts.gz','20170318_205609_kcor.fts.gz']
run = kcor_run(date, $
               config_filename=filepath('kcor.kolinski.mahi.latest.cfg', $
                                        subdir=['..', '..', 'config'], $
                                        root=mg_src_root()))
kcor_cal_insert, date, filelist, run=run

end