; docformat = 'rst'

;+
; Insert values into the MLSO database table: mlso_sgs.
;
; Reads a list of L0 files for a specified date and inserts a row of data into
; 'kcor_sgs'.  TODO: will also need to read from sgs text files.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;   fits_list: in, required, type=array of strings
;     array of L0 FITS files to insert into the database
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
;     filelist = ['20170204_205610_kcor.fts.gz', '20170204_205625_kcor.fts.gz']
;     mlso_sgs_insert, date, filelist, run=run, obsday_index=obsday_index
;
; :Author: 
;   Don Kolinski
;   HAO/NCAR  K-coronagraph
;
; :History:
;   10 March, 2017 - Edits by DJK to work with a filelist and with new sgs database table
;-
pro mlso_sgs_insert, date, fits_list, $
                     run=run, $
                     database=db, $
                     obsday_index=obsday_index
  compile_opt strictarr
  on_error, 2

  if (n_params() ne 2) then begin
    mg_log, 'missing date or filelist parameters', name='kcor/dbinsert', /error
    return
  endif

  ; connect to MLSO database
  db->getProperty, host_name=host
  mg_log, 'using connection to %s', host, name='kcor/rt', /debug

  year    = strmid(date, 0, 4)             ; yyyy
  month   = strmid(date, 4, 2)             ; mm
  day     = strmid(date, 6, 2)             ; dd

  sgs_source = ''                           ; 'k' or 's'  (kcor or sgs)
  
  l0_dir = filepath('level0', subdir=date, root=run->config('processing/raw_basedir'))
  cd, current=start_dir
  cd, l0_dir

  ; step through list of fits files passed in parameter
  nfiles = n_elements(fits_list)

  if (nfiles eq 0) then begin
    mg_log, 'no images in FITS list', name='kcor/rt', /info
    goto, done
  endif

  i = -1
  while (++i lt nfiles) do begin
    fts_file = fits_list[i]

    if (~file_test(fts_file)) then begin
      mg_log, '%s not found', fts_file, name='kcor/rt', /warn
      continue
    endif else begin
      mg_log, 'ingesting %s', fts_file, name='kcor/rt', /info
    endelse

    ; if in this conditional, then the source is KCor
    sgs_source = 'k'

    ; extract desired items from header
    kcor_read_rawdata, fts_file, header=hdu, $
                       repair_routine=run->epoch('repair_routine'), $
                       xshift=run->epoch('xshift_camera'), $
                       start_state=run->epoch('start_state'), $
                       raw_data_prefix=run->epoch('raw_data_prefix')

    date_obs  = sxpar(hdu, 'DATE-OBS', count=qdate_obs)

    ; normalize odd values for date/times
    date_obs = kcor_normalize_datetime(date_obs)

    run.time = date_obs

    if (~run->epoch('use_sgs')) then begin
      mg_log, 'not using SGS from files in this epoch', name='kcor/rt', /warn
      continue
    endif

    sgsdimv_str  = kcor_getsgs(hdu, 'SGSDIMV')
    sgsdims_str  = kcor_getsgs(hdu, 'SGSDIMS')
    sgssumv_str  = kcor_getsgs(hdu, 'SGSSUMV')
    sgsrav_str   = kcor_getsgs(hdu, 'SGSRAV')
    sgsras_str   = kcor_getsgs(hdu, 'SGSRAS')
    sgsrazr_str  = kcor_getsgs(hdu, 'SGSRAZR')
    sgsdecv_str  = kcor_getsgs(hdu, 'SGSDECV')
    sgsdecs_str  = kcor_getsgs(hdu, 'SGSDECS')
    sgsdeczr_str = kcor_getsgs(hdu, 'SGSDECZR')
    sgsscint_str = kcor_getsgs(hdu, 'SGSSCINT')
    sgssums_str  = kcor_getsgs(hdu, 'SGSSUMS')

    sgsloop_str  = kcor_getsgs(hdu, 'SGSLOOP')
		
    ; DB insert command
    db->execute, 'insert into mlso_sgs (date_obs, obs_day, source, sgsdimv, sgsdims, sgssumv, sgsrav, sgsras, sgsrazr, sgsdecv, sgsdecs, sgsdeczr, sgsscint, sgssums, sgsloop) VALUES (''%s'', %d, ''%s'', %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s) ', $
                 date_obs, obsday_index, sgs_source, sgsdimv_str, sgsdims_str, $
                 sgssumv_str, sgsrav_str, sgsras_str, sgsrazr_str, sgsdecv_str, $
                 sgsdecs_str, sgsdeczr_str, sgsscint_str, sgssums_str, sgsloop_str, $
                 status=status, error_message=error_message, sql_statement=sql_cmd
    if (status ne 0L) then begin
      mg_log, 'error inserting to mlso_sgs table', name='kcor/rt', /error
      mg_log, 'status: %d, error message: %s', status, error_message, $
              name='kcor/rt', /error
      mg_log, 'SQL command: %s', sql_cmd, name='kcor/rt', /error
    endif
  endwhile

  done:
  cd, start_dir

  mg_log, 'done', name='kcor/rt', /info
end


; main-level example program

date = '20170204'
filelist = ['20170204_205610_kcor.fts.gz', $
            '20170204_205625_kcor.fts.gz', $
            '20170204_205640_kcor.fts.gz', $
            '20170204_205656_kcor.fts.gz', $
            '20170204_205711_kcor.fts.gz']
run = kcor_run(date, $
               config_filename=filepath('kcor.latest.cfg', $
                                        subdir=['..', '..', 'config'], $
                                        root=mg_src_root()))
mlso_sgs_insert, date, filelist, run=run

end
