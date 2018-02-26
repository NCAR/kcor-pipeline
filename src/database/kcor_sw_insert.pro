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
pro kcor_sw_insert, date, fits_list, run=run, database=database, log_name=log_name
  compile_opt strictarr
  on_error, 2

  ; connect to MLSO database.

  ; Note: The connect procedure accesses DB connection information in the file
  ;       .mysqldb. The "config_section" parameter specifies
  ;       which group of data to use.

  if (obj_valid(database)) then begin
    db = database

    db->getProperty, host_name=host
    mg_log, 'using connection to %s', host, name=log_name, /debug
  endif else begin
    db = mgdbmysql()
    db->connect, config_filename=run.database_config_filename, $
                 config_section=run.database_config_section

    db->getProperty, host_name=host
    mg_log, 'connected to %s', host, name=log_name, /info
  endelse

  ; change to proper processing directory
  archive_dir = filepath('', subdir=kcor_decompose_date(date), root=run.archive_basedir)

  ; move to archive dir
  cd, current=start_dir
  cd, archive_dir

  ; loop through fits list
  nfiles = n_elements(fits_list)

  if (nfiles eq 0) then begin
    mg_log, 'no images in list file', name=log_name, /info
    goto, done
  endif

  date_format = '(C(CYI, "-", CMOI2.2, "-", CDI2.2, "T", CHI2.2, ":", CMI2.2, ":", CSI2.2))'

  ; get last kcor_sw entry (latest proc_date) to compare to
  latest_sw = kcor_find_latest_sw(run=run, database=database, log_name=log_name)

  i = -1
  fts_file = ''
  while (++i lt nfiles) do begin
    fts_file = fits_list[i]

    ; extract desired items from header
    hdu   = headfits(fts_file, /silent)  ; read FITS header

    date_obs    = sxpar(hdu, 'DATE-OBS', count=qdate_obs)

    ; normalize odd values for date/times
    date_obs = kcor_normalize_datetime(date_obs)
    run.time = date_obs

    dmodswid    = sxpar(hdu, 'DMODSWID', count=qdmodswid)
    distort     = sxpar(hdu, 'DISTORT', count=qdistort)
;TODO: Replace with new header var for processing sw version?
    bunit       = sxpar(hdu, 'BUNIT', count=qbunit)
    bzero       = sxpar(hdu, 'BZERO', count=qbzero)
    bscale      = sxpar(hdu, 'BSCALE', count=qbscale)
;TODO: Replace with new header var for labview sw
    labviewid   = sxpar(hdu, 'OBSSWID', count=qlabviewid)
;TODO: Replace with new header var for socketcam sw
    socketcamid	= sxpar(hdu, 'OBSSWID', count=qsocketcamid)
	
    sw_version     = kcor_find_code_version(revision=sw_revision)
    sky_pol_factor = run->epoch('skypol_factor')
    sky_bias       = run->epoch('skypol_bias')

    ; TODO: update as needed
    if (qbunit eq 0) then bunit = 'quasi-pB'
    if (qbscale eq 0) then bscale = 0.001

    ; TODO: Test for changes from previous db entry
    ; TODO: From 20170315 meeting: We will wait for older data to be completely
    ;       reprocessed to avoid problems caused by trying to update this table
    ;       out of order.

    proc_date = string(julday(), format=date_format)
    file_sw = {date           : date, $             ; from file
               proc_date      : proc_date, $        ; generated
               dmodswid       : dmodswid, $         ; from file
               distort        : distort, $          ; from file
               sw_version     : sw_version, $       ; from KCOR_FIND_CODE_VERSION
               bunit          : bunit, $            ; from file
               bzero          : bscale, $           ; from file
               bscale         : bscale, $           ; from file
               labviewid      : labviewid, $        ; from file
               socketcamid    : socketcamid, $      ; from file
               sw_revision    : sw_revision, $      ; from KCOR_FIND_CODE_VERSION
               sky_pol_factor : sky_pol_factor, $   ; from epochs.cfg
               sky_bias       : sky_bias}           ; from epochs.cfg

    update = kcor_compare_sw(latest_sw, file_sw, log_name=log_name) ne 0
	
    if (update) then begin
      mg_log, 'inserting a new kcor_sw row', name=log_name, /info

      latest_sw = file_sw

      fields = ['date', $
                'proc_date', $
                'dmodswid', $
                'distort', $
                'sw_version', $
                'bunit', $
                'bzero', $
                'bscale', $
                'labviewid', $
                'socketcamid', $
                'sw_revision', $
                'sky_pol_factor', $
                'sky_bias']
      fields_expr = strjoin(fields, ', ')
      db->execute, 'INSERT INTO kcor_sw (%s) VALUES (''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', %f, %f, ''%s'', ''%s'', ''%s'', %f, %f) ', $
                   fields_expr, $
                   date, $
                   proc_date, $        ; generated
                   dmodswid, $
                   distort, $
                   sw_version, $       ; from KCOR_FIND_CODE_VERSION
                   bunit, $
                   bzero, $
                   bscale, $
                   labviewid, $
                   socketcamid, $
                   sw_revision, $      ; from KCOR_FIND_CODE_VERSION
                   sky_pol_factor, $   ; from epochs.cfg
                   sky_bias, $         ; from epochs.cfg
                   status=status, error_message=error_message, sql_statement=sql_cmd
      if (status ne 0L) then begin
        mg_log, '%d, error message: %s', status, error_message, $
                name=log_name, /debug
        mg_log, 'sql_cmd: %s', sql_cmd, name=log_name, /debug
      endif

      ; TODO: Write sw_id (auto-incremented in kcor_sw table) into kcor_eng
      ; table for every entry processed with these software parameters.
      ; Actually, in practice, we will be writing previous sw_id into kcor_eng
      ; for every entry processed with the software parameters between the
      ; newly changed kcor_sw entry and the entry before the previous one.
      ; Hammer out details of this with Mike G and Joan.
    endif
  endwhile

  done:
  if (~obj_valid(database)) then obj_destroy, db
  mg_log, 'done', name=log_name, /info
end


; main-level example program

date = '20180208'
config_filename = filepath('kcor.mgalloy.mahi.latest.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)

cd, current=current_dir
l1_dir = filepath('level1', subdir=date, root=run.raw_basedir)
cd, l1_dir
l1_files = file_search('*l1.fts*', count=n_l1_files)

kcor_sw_insert, date, l1_files, run=run

cd, current_dir

end