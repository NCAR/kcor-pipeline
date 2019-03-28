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
;   filelist: in, required, type=array of strings
;     array of FITS files to insert into the database
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;   obsday_index : in, required, type=integer
;     index into mlso_numfiles database table
;   database : in, optional, type=MGdbMySql object
;     database connection to use
;   mean_phase1 : in, optional, type=fltarr
;     mean_phase1 for each file in `filelist`   
;;
; :Examples:
;   For example::
;
;     date = '20170204'
;     filelist = ['20170204_205610_kcor_l1_nrgf.fts.gz', '20170204_205625_kcor_l1.fts.gz']
;     kcor_eng_insert, date, filelist, run=run, obsday_index=obsday_index
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
pro kcor_eng_insert, date, fits_list, $
                     run=run, $
                     database=database, $
                     obsday_index=obsday_index, $
                     mean_phase1=mean_phase1, $
                     sw_index=sw_index, $
                     hw_ids=hw_ids
  compile_opt strictarr

  if (n_params() ne 2) then begin
    mg_log, 'missing date or filelist parameters', name='kcor/rt', /error
    return
  endif

  ; connect to MLSO database

  ; Note: The connect procedure accesses DB connection information in the file
  ;       .mysqldb. The "config_section" parameter specifies
  ;       which group of data to use.
  if (obj_valid(database)) then begin
    db = database

    db->getProperty, host_name=host
    mg_log, 'using connection to %s', host, name='kcor/rt', /debug
  endif else begin
    db = mgdbmysql()
    db->connect, config_filename=run->config('database/config_filename'), $
                 config_section=run->config('database/config_section')

    db->getProperty, host_name=host
    mg_log, 'connected to %s', host, name='kcor/rt', /info
  endelse

  year    = strmid(date, 0, 4)   ; YYYY
  month   = strmid(date, 4, 2)   ; MM
  day     = strmid(date, 6, 2)   ; DD

  l1_dir = filepath('level1', subdir=date, root=run->config('processing/raw_basedir'))
  cd, current=start_dir 
  cd, l1_dir

  ; step through list of fits files passed in parameter
  nfiles = n_elements(fits_list)
  if (nfiles eq 0) then begin
    mg_log, 'no images in FITS list', name='kcor/rt', /info
    goto, done
  endif

  i = -1
  n_nrgf = 0
  while (++i lt nfiles) do begin
    fts_file = fits_list[i]

    ; no need to look at NRGF files
    is_nrgf = strpos(file_basename(fts_file), 'nrgf') ge 0L
    if (is_nrgf) then begin
      n_nrgf += 1
      continue
    endif
    fts_file += '.gz'

    if (~file_test(fts_file)) then begin
      mg_log, '%s not found', fts_file, name='kcor/rt', /warn
      continue
    endif else begin
      mg_log, 'ingesting %s', fts_file, name='kcor/rt', /info
    endelse

    ; extract desired items from header
    hdu = headfits(fts_file, /silent)

    date_obs     = sxpar(hdu, 'DATE-OBS', count=qdate_obs)

    ; normalize odd values for date/times
    date_obs = kcor_normalize_datetime(date_obs)
    run.time = date_obs

    rcamfocs     = sxpar(hdu, 'RCAMFOCS', count=qrcamfocs)
    rcamfocs_str = strtrim(rcamfocs, 2)
    if (rcamfocs_str eq 'NaN') then rcamfocs = -99.99
		
    tcamfocs     = sxpar(hdu, 'TCAMFOCS', count=qtcamfocs)
    tcamfocs_str = strtrim(tcamfocs, 2)
    if (tcamfocs_str eq 'NaN') then tcamfocs = -99.99
		
    modltrt     = sxpar(hdu, 'MODLTRT', count=qmodltrt)
    o1focs      = sxpar(hdu, 'O1FOCS', count=q01focs)
    if (run->epoch('use_sgs')) then begin
      sgsdimv_str = kcor_getsgs(hdu, 'SGSDIMV')
      sgsdims_str = kcor_getsgs(hdu, 'SGSDIMS')
    endif else begin
      sgsdimv_str = 'NULL'
      sgsdims_str = 'NULL'
    endelse
		
    level       = strtrim(sxpar(hdu, 'LEVEL', count=qlevel), 2)

    ; TODO: Older NRGF headers have 'NRGF' appended to level string, but newer headers
    ;  will have another keyword added to header for producttype
    os = strpos(level, 'NRGF')  
    if (os ne -1) then begin
      level = strmid(level, 0, os)   ; strip off NRGF from level, if present
    endif	
		
    bunit       = strtrim(sxpar(hdu, 'BUNIT',    count=qbunit), 2)
    bzero       =         sxpar(hdu, 'BZERO',    count=qbzero)
    bscale      =         sxpar(hdu, 'BSCALE',   count=qbscale)
    rcamxcen    =         sxpar(hdu, 'RCAMXCEN', count=qrcamxcen)
    rcamycen    =         sxpar(hdu, 'RCAMYCEN', count=qrcamycen)
    tcamxcen    =         sxpar(hdu, 'TCAMXCEN', count=qtcamxcen)
    tcamycen    =         sxpar(hdu, 'TCAMYCEN', count=qtcamycen)
    rcam_rad    =         sxpar(hdu, 'RCAM_RAD', count=qrcamrad)
    tcam_rad    =         sxpar(hdu, 'TCAM_RAD', count=qtcamrad)
    cover       = strtrim(sxpar(hdu, 'COVER',    count=qcover), 2)
    darkshut    = strtrim(sxpar(hdu, 'DARKSHUT', count=qdarkshut), 2)
    diffuser    = strtrim(sxpar(hdu, 'DIFFUSER', count=qdarkshut), 2)
    calpol      = strtrim(sxpar(hdu, 'CALPOL',   count=qcalpol), 2)

    distort     = sxpar(hdu, 'DISTORT', count=qdistort)
    labviewid   = sxpar(hdu, 'OBSSWID', count=qlabviewid)
    socketcamid = sxpar(hdu, 'SOCKETCA', count=qsocketcamid)


    ; check for out of bounds values
    if (strpos(tcamxcen, '*') ne -1) then tcamxcen = 'NULL'
    if (strpos(tcamycen, '*') ne -1) then tcamycen = 'NULL'

    fits_file = file_basename(fts_file, '.gz') ; remove '.gz' from file name.
		
    ; get IDs from relational tables
		
    level_count = db->query('SELECT count(level_id) FROM kcor_level WHERE level=''%s''', $
                            level, fields=fields)
    if (level_count.count_level_id_ eq 0) then begin
      ; if given level is not in the kcor_level table, set it to 'unknown' and
      ; log error
      level = 'unk'
      mg_log, 'level: %s', level, name='kcor/rt', /error
    endif
    level_results = db->query('SELECT * FROM kcor_level WHERE level=''%s''', $
                              level, fields=fields)
    level_num = level_results.level_id	
		
    ; DB insert command
    db->execute, 'INSERT INTO kcor_eng (file_name, date_obs, obs_day, rcamfocs, tcamfocs, modltrt, o1focs, kcor_sgsdimv, kcor_sgsdims, level, bunit, bzero, bscale, rcamxcen, rcamycen, tcamxcen, tcamycen, rcam_rad, tcam_rad, mean_phase1, cover, darkshut, diffuser, calpol, distort, labviewid, socketcamid, kcor_sw_id, kcor_hw_id) VALUES (''%s'', ''%s'', %d, %s, %s, %s, %s, %s, %s, %d, ''%s'', %d, %f, %f, %f, %f, %f, %f, %f, %f, ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', %d, %d) ', $
                 fits_file, date_obs, obsday_index, kcor_fitsfloat2db(rcamfocs), $
                 kcor_fitsfloat2db(tcamfocs), $
                 kcor_fitsfloat2db(modltrt), kcor_fitsfloat2db(o1focs), $
                 sgsdimv_str, sgsdims_str, level_num, bunit, bzero, $
                 kcor_fitsfloat2db(bscale), $
                 kcor_fitsfloat2db(rcamxcen), $
                 kcor_fitsfloat2db(rcamycen), $
                 kcor_fitsfloat2db(tcamxcen), $
                 kcor_fitsfloat2db(tcamycen), $
                 kcor_fitsfloat2db(rcam_rad), $
                 kcor_fitsfloat2db(tcam_rad), $
                 kcor_fitsfloat2db(mean_phase1[i - n_nrgf]), $
                 cover, darkshut, diffuser, calpol, $
                 distort, labviewid, socketcamid, $
                 sw_index, $
                 hw_ids[i], $
                 status=status, error_message=error_message, sql_statement=sql_cmd
    if (status ne 0L) then begin
      mg_log, 'error inserting into kcor_eng table', name='kcor/rt', /error
      mg_log, 'status: %d, error message: %s', status, error_message, $
              name='kcor/rt', /error
      mg_log, 'SQL command: %s', sql_cmd, name='kcor/rt', /error
    endif
  endwhile

  done:
  if (~obj_valid(database)) then obj_destroy, db
  cd, start_dir

  mg_log, 'done', name='kcor/rt', /info
end


; main-level example program

;date = '20170204'
date = '20130930'
;filelist = ['20170204_205610_kcor_l1_nrgf.fts.gz','20170204_205625_kcor_l1.fts.gz','20170204_205640_kcor_l1.fts.gz','20170204_205656_kcor_l1.fts.gz','20170204_205711_kcor_l1.fts.gz']
filelist = ['20130930_202422_kcor_l1.5.fts']
run = kcor_run(date, $
               config_filename=filepath('kcor.mgalloy.mahi.latest.cfg', $
                                        subdir=['..', '..', 'config'], $
                                        root=mg_src_root()))

obsday_index = mlso_obsday_insert(date, run=run, database=db)

kcor_eng_insert, date, filelist, run=run, database=db, mean_phase1=[1.0], obsday_index=obsday_index

obj_destroy, db

end
