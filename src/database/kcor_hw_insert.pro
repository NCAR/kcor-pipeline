; docformat = 'rst'

;+
; Insert values into the MLSO database table: kcor_hw.
;
; Reads a list of L2 files for a specified date and inserts a row of data into
; 'kcor_hw' if any of the monitored fields changed from the previous db entry.
; This script will check the database against the current data to decide whether
; a new line should be added
;
; :Params:
;   date : in, type=string
;     date in the form 'YYYYMMDD'
;   fits_list: in, required, type=array of strings
;     level 2 FITS filenames
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;   hw_ids : out, optional, type=lonarr
;     set to a named variable to retrieve the hw_id's of the list of files
;
; :Examples:
;   For example::
;
;     date = '20170204'
;     filelist = ['20170214_190402_kcor.fts.gz', $
;                 '20170214_190417_kcor.fts.gz', $
;                 '20170214_190548_kcor.fts.gz', $
;                 '20170214_190604_kcor.fts', $
;                 '20170214_190619_kcor.fts']
;     kcor_hw_insert, date, filelist
;-
pro kcor_hw_insert, date, fits_list, run=run, database=db, log_name=log_name, $
                    hw_ids=hw_ids
  compile_opt strictarr
  on_error, 2

  ; connect to MLSO database.
  db->getProperty, host_name=host
  mg_log, 'using connection to %s', host, name=log_name, /debug

  ; move to archive dir
  cd, current=start_dir
  raw_dir = filepath('', subdir=date, root=run->config('processing/raw_basedir'))
  l2_dir = filepath('level2', root=raw_dir)
  cd, l2_dir

  ; loop through FITS list
  nfiles = n_elements(fits_list)

  if (nfiles eq 0) then begin
    mg_log, 'no images in list file', name=log_name, /info
    goto, done
  endif

  hw_ids = lonarr(nfiles)

  date_format = '(C(CYI, "-", CMOI2.2, "-", CDI2.2, "T", CHI2.2, ":", CMI2.2, ":", CSI2.2))'

  ; get last kcor_hw entry (latest proc_date) to compare to
  latest_hw = kcor_find_latest_row(run=run, database=db, $
                                   log_name=log_name, error=error)

  if (error ne 0L) then begin
    mg_log, 'skipping inserting kcor_hw row', name=log_name, /warn
    goto, done
  endif

  if (n_elements(latest_hw) eq 0L) then begin
    mg_log, 'first hw entry, no existing entries', $
            name=log_name, /debug
  endif else begin
    mg_log, 'latest hw entry from %s (id=%d)', latest_hw.date, latest_hw.hw_id, $
            name=log_name, /debug
  endelse

  i = -1
  fts_file = ''
  while (++i lt nfiles) do begin
    fts_file = fits_list[i]
    if (~file_test(fts_file)) then fts_file += '.gz'
    if (~file_test(fts_file)) then begin
      mg_log, 'cannot find %s', fts_file, name=log_name, /warn
      continue
    endif

    mg_log, 'checking %s', file_basename(fts_file), name=log_name, /debug

    ; extract desired items from header
    hdu   = headfits(fts_file, /silent, errmsg=errmsg)  ; read FITS header
    if (errmsg ne '') then begin
      mg_log, 'error reading %, skipping', fts_file, name=log_name, /error
      continue
    endif

    date_obs    = sxpar(hdu, 'DATE-OBS', count=qdate_obs)

    ; normalize odd values for date/times
    date_obs = kcor_normalize_datetime(date_obs)
    run.time = date_obs

    diffsrid    = sxpar(hdu, 'DIFFSRID', count=n_diffsrid)
    bopal       = sxpar(hdu, 'BOPAL',    count=n_bopal)
    rcamid      = sxpar(hdu, 'RCAMID',   count=n_rcamid)
    tcamid      = sxpar(hdu, 'TCAMID',   count=n_tcamid)
    rcamlut     = sxpar(hdu, 'RCAMLUT',  count=n_rcamlut)
    tcamlut     = sxpar(hdu, 'TCAMLUT',  count=n_tcamlut)
    modltrid    = sxpar(hdu, 'MODLTRID', count=n_modltrid)
    o1id        = sxpar(hdu, 'O1ID',     count=n_o1id)

    if (run->epoch('use_occulter_id')) then begin
      occltrid = sxpar(hdu, 'OCCLTRID', count=n_occltrid)
    endif else begin
      occltrid = run->epoch('occulter_id')
    endelse

    filterid    = sxpar(hdu, 'FILTERID', count=n_filterid)
    calpolid    = sxpar(hdu, 'CALPOLID', count=n_calpolid)

    ; TODO: Test for changes from previous db entry
    ; TODO: From 20170315 meeting: We will wait for older data to be completely
    ;       reprocessed to avoid problems caused by trying to update this table
    ;       out of order.

    proc_date = string(julday(), format=date_format)
    file_hw = {hw_id          : 0L, $               ; fill in later
               date           : date_obs, $         ; from file
               proc_date      : proc_date, $        ; generated
               diffsrid       : strtrim(diffsrid, 2), $
               bopal          : float(bopal), $
               rcamid         : strtrim(rcamid, 2), $
               tcamid         : strtrim(tcamid, 2), $
               rcamlut        : strtrim(rcamlut, 2), $
               tcamlut        : strtrim(tcamlut, 2), $
               modltrid       : strtrim(modltrid, 2), $
               o1id           : strtrim(o1id, 2), $
               occltrid       : strtrim(occltrid, 2), $
               filterid       : strtrim(filterid, 2), $
               calpolid       : strtrim(calpolid, 2)}

    compare_fields = ['diffsrid', $
                      'bopal', $
                      'rcamid', $
                      'tcamid', $
                      'rcamlut', $
                      'tcamlut', $
                      'modltrid', $
                      'o1id', $
                      'occltrid', $
                      'filterid', $
                      'calpolid']
    update = kcor_compare_rows(latest_hw, file_hw, $
                               compare_fields=compare_fields, $
                               log_name=log_name) ne 0
	
    if (update) then begin
      mg_log, 'inserting a new kcor_hw row', name=log_name, /info

      fields = ['date', $
                'proc_date', $
                compare_fields]
      fields_expr = strjoin(fields, ', ')
      db->execute, 'insert into kcor_hw (%s) values (''%s'', ''%s'', ''%s'', %11.7f, ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'') ', $
                   fields_expr, $
                   date_obs, $
                   proc_date, $        ; generated
                   diffsrid, $
                   bopal, $
                   rcamid, $
                   tcamid, $
                   rcamlut, $
                   tcamlut, $
                   modltrid, $
                   o1id, $
                   occltrid, $
                   filterid, $
                   calpolid, $
                   status=status
      if (status ne 0L) then continue

      hw = db->query('select last_insert_id()', status=status)
      if (status ne 0L) then continue
      hw_ids[i] = hw.last_insert_id__

      file_hw.hw_id = hw_ids[i]
      latest_hw = file_hw
    endif else begin
      hw_ids[i] = latest_hw.hw_id
    endelse
  endwhile

  done:
  cd, start_dir
  mg_log, 'done', name=log_name, /info
end


; main-level example program

date = '20180208'
config_filename = filepath('kcor.mgalloy.mahi.latest.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)

latest_hw = kcor_find_latest_row(run=run, database=database, log_name=log_name)
help, latest_hw

cd, current=current_dir
l2_dir = filepath('level2', subdir=date, root=run->config('processing/raw_basedir'))
cd, l2_dir
l2_files = file_search('*l2.fts*', count=n_l2_files)

;kcor_hw_insert, date, l2_files, run=run

cd, current_dir

end