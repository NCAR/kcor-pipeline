; docformat = 'rst'

;+
; Utility to insert values into the MLSO database table: kcor_img.
;
; Reads a list of L2 files for a specified date and inserts a row of data into
; 'kcor_img'.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;   fits_list : in, required, type=strarr
;     array of FITS files to insert into the database
;
; :Keywords:
;   level2 : in, optional, type=boolean
;     set to indicate that the `fits_list` files are L2 files
;   run : in, required, type=object
;     `kcor_run` object
;   obsday_index : in, required, type=integer
;     index into mlso_numfiles database table
;   database : in, optional, type=KCordbMySql object
;     database connection to use
;   log_name : in, required, type=string
;     log name to use for logging, i.e., "kcor/rt", "kcor/eod", etc.
;
; :Examples:
;   For example::
;
;     date = '20170204'
;     filelist = ['20170204_205610_kcor_l2_nrgf.fts.gz', '20170204_205625_kcor_l2.fts.gz']
;     kcor_img_insert, date, filelist, run=run, obsday_index=obsday_index
;
;   See the main-level program in this file for a detailed example.
;
; :Author: 
;   Andrew Stanger
;   HAO/NCAR  K-coronagraph
;   Major edits beyond creation: Don Kolinski
;
; :History:
;   11 Sep 2015 IDL procedure created.  
;               Use /hao/mlsodata1/Data/raw/yyyymmdd/level1 directory.
;   14 Sep 2015 Use /hao/acos/year/month/day directory.
;   28 Sep 2015 Add date_end field.
;    7 Feb 2017 DJK - Starting to edit for new table fields and noting new
;               changes to come (search for TODO)
;-
pro kcor_img_insert, date, fits_list, $
                     level2=level2, $
                     run=run, $
                     database=db, $
                     obsday_index=obsday_index, $
                     log_name=log_name, $
                     hw_ids=hw_ids
  compile_opt strictarr
  on_error, 2

  if (keyword_set(level2)) then begin
    kcor_hw_insert, date, fits_list, run=run, database=db, log_name=log_name, $
                    hw_ids=hw_ids
  endif

  ; connect to MLSO database
  db->getProperty, host_name=host
  mg_log, 'using connection to %s', host, name=log_name, /debug

  year    = strmid (date, 0, 4)	; yyyy
  month   = strmid (date, 4, 2)	; mm
  day     = strmid (date, 6, 2)	; dd

  l2_dir = filepath('level2', subdir=date, root=run->config('processing/raw_basedir'))
  cd, current=start_dir 
  cd, l2_dir

  ; step through list of fits files passed in parameter
  nfiles = n_elements(fits_list)
  if (nfiles eq 0) then begin
    mg_log, 'no images in FITS list', name=log_name, /info
    goto, done
  endif

  i = -1
  n_pb_added = 0L
  n_nrgf_added = 0L
  n_pb_avg_added = 0L
  n_pb_extavg_added = 0L
  n_nrgf_extavg_added = 0L

  ; The decision is to not include non-FITS in the database because raster
  ; files (GIFs) will be created for every image in database. However, since
  ; we may add them later, or other file types, we'll keep the field in the
  ; kcor_img database table.
  filetype   = 'fits'
  filetype_count = db->query('select count(filetype_id) from mlso_filetype where filetype=''%s''', $
                             filetype, fields=fields, $
                             status=status, error_message=error_message, sql_statement=sql_cmd)
  if (status ne 0L) then begin
    mg_log, 'error querying mlso_filetype table', name=log_name, /error
    mg_log, 'status: %d, error message: %s', status, error_message, $
            name=log_name, /error
    mg_log, 'SQL command: %s', sql_cmd, name=log_name, /error
    goto, done
  endif
  if (filetype_count.count_filetype_id_ eq 0) then begin
    ; if given filetype is not in the mlso_filetype table, set it to 'unknown'
    ; and log error
    filetype = 'unknown'
    mg_log, 'filetype: %s', filetype, name=log_name, /error
  endif
  filetype_results = db->query('select * from mlso_filetype where filetype=''%s''', $
                               filetype, fields=fields, $
                               status=status, error_message=error_message, sql_statement=sql_cmd)
  if (status ne 0L) then begin
    mg_log, 'error querying mlso_filetype table', name=log_name, /error
    mg_log, 'status: %d, error message: %s', status, error_message, $
            name=log_name, /error
    mg_log, 'SQL command: %s', sql_cmd, name=log_name, /error
    goto, done
  endif
  filetype_num = filetype_results.filetype_id	

  while (++i lt nfiles) do begin
    fts_file = fits_list[i]

    is_nrgf = strpos(file_basename(fts_file), 'nrgf') ge 0L
    is_avg = strpos(file_basename(fts_file), '_avg') ge 0L
    is_extavg = strpos(file_basename(fts_file), 'extavg') ge 0L

    fts_file += '.gz'

    if (~file_test(fts_file)) then begin
      mg_log, '%s not found', fts_file, name=log_name, /warn
      continue
    endif else begin
      mg_log, 'ingesting %s', fts_file, name=log_name, /info
    endelse

    ; extract desired items from header
    hdu   = headfits(fts_file, /silent)   ; read FITS header
    date_obs   = sxpar(hdu, 'DATE-OBS', count=qdate_obs)
    date_end   = sxpar(hdu, 'DATE-END', count=qdate_end)

    ; normalize odd values for date/times, particularly "60" as minute value in
    ; DATE-END
    date_obs = kcor_normalize_datetime(date_obs, $
                                       components=img_date_parts, $
                                       error=error)
    date_end = kcor_normalize_datetime(date_end, error=error)
    if (error ne 0L) then begin
      date_end = kcor_normalize_datetime(date_obs, error=error, /add_15)
    endif

    sun, img_date_parts[0], img_date_parts[1], img_date_parts[2], $
         img_date_parts[3] + img_date_parts[4] / 60.0 + img_date_parts[5] / 3600., $
         carrington=carrington
    carrington_rotation = long(carrington)

    exptime    = sxpar(hdu, 'EXPTIME',  count=qexptime)
    numsum     = sxpar(hdu, 'NUMSUM',   count=qnumsum)
    quality    = sxpar(hdu, 'QUALITY',  count=qquality)

    if (strtrim(quality, 2) eq 'ok') then quality = 75

    level      = strtrim(sxpar(hdu, 'LEVEL', count=qlevel), 2)

    ; TODO: Older NRGF headers have 'NRGF' appended to level string, but newer
    ;       headers will have another keyword added to header for producttype
    os = strpos(level, 'NRGF')
    if (os ne -1) then begin
      level = strmid(level, 0, os)
    endif	

    ; get product type from filename
    if (is_nrgf) then begin
      case 1 of
        is_extavg: producttype = 'nrgfextavg'
        is_avg: producttype = 'nrgfavg'
        else: producttype = 'nrgf'
      endcase
    endif else begin
      case 1 of
        is_extavg: producttype = 'pbextavg'
        is_avg: producttype = 'pbavg'
        else: producttype = 'pb'
      endcase
    endelse

    fits_file = file_basename(fts_file, '.gz') ; remove '.gz' from file name.

    ; get IDs from relational tables
    producttype_count = db->query('select count(producttype_id) from mlso_producttype where producttype=''%s''', $
                                  producttype, fields=fields, $
                                  status=status, error_message=error_message, sql_statement=sql_cmd)
    if (status ne 0L) then begin
      mg_log, 'error querying mlso_producttype table', name=log_name, /error
      mg_log, 'status: %d, error message: %s', status, error_message, $
              name=log_name, /error
      mg_log, 'SQL command: %s', sql_cmd, name=log_name, /error
      continue
    endif
    if (producttype_count.count_producttype_id_ eq 0) then begin
      ; if given producttype is not in the mlso_producttype table, set it to
      ; 'unknown' and log error
      producttype = 'unknown'
      mg_log, 'producttype: %s', producttype, name=log_name, /error
    endif
    producttype_results = db->query('select * from mlso_producttype where producttype=''%s''', $
                                    producttype, fields=fields, $
                                    status=status, error_message=error_message, sql_statement=sql_cmd)
    if (status ne 0L) then begin
      mg_log, 'error querying mlso_producttype table', name=log_name, /error
      mg_log, 'status: %d, error message: %s', status, error_message, $
              name=log_name, /error
      mg_log, 'SQL command: %s', sql_cmd, name=log_name, /error
      continue
    endif
    producttype_num = producttype_results.producttype_id	

    level_num = kcor_get_level_id(level, database=db, count=level_found)
    if (level_found eq 0) then mg_log, 'using unknown level', name=log_name, /error

    ; DB insert command
    db->execute, 'insert into kcor_img (file_name, date_obs, date_end, obs_day, carrington_rotation, level, quality, producttype, filetype, numsum, exptime) values (''%s'', ''%s'', ''%s'', %d, %d, %d, %d, %d, %d, %d, %f)', $
                 fits_file, date_obs, date_end, obsday_index, carrington_rotation, $
                 level_num, quality, producttype_num, $
                 filetype_num, numsum, exptime, $
                 status=status, error_message=error_message, sql_statement=sql_cmd
    if (status eq 0L) then begin
      if (is_nrgf) then begin
        case 1 of
          is_extavg: n_nrgf_extavg_added += 1
          else: n_nrgf_added += 1
        endcase
      endif else begin
        case 1 of
          is_extavg: n_pb_extavg_added += 1
          is_avg: n_pb_avg_added += 1
          else: n_pb_added += 1
        endcase
      endelse
    endif else begin
      mg_log, 'error inserting in kcor_img table', name=log_name, /error
      mg_log, 'status: %d, error message: %s', status, error_message, $
              name=log_name, /error
      mg_log, 'SQL command: %s', sql_cmd, name=log_name, /error
    endelse
  endwhile

  ; update number of files in mlso_numfiles
  num_files_results = db->query('select * from mlso_numfiles where day_id=''%d''', obsday_index)
  n_pb_files = num_files_results.num_kcor_pb_fits + n_pb_added
  n_nrgf_files = num_files_results.num_kcor_nrgf_fits + n_nrgf_added
  n_pb_avg_files = num_files_results.num_kcor_pb_avg_fits + n_pb_avg_added
  n_pb_extavg_files = num_files_results.num_kcor_pb_extavg_fits + n_pb_extavg_added
  n_nrgf_extavg_files = num_files_results.num_kcor_nrgf_extavg_fits + n_nrgf_extavg_added

  set_expression = 'num_kcor_' + ['pb_fits', $
                                  'pb_lowresgif', $
                                  'pb_fullresgif', $
                                  'nrgf_fits', $
                                  'nrgf_lowresgif', $
                                  'nrgf_fullresgif', $
                                  'pb_avg_fits', $
                                  'pb_avg_lowresgif', $
                                  'pb_avg_fullresgif', $
                                  'pb_extavg_fits', $
                                  'nrgf_extavg_fits']
  n_files = [n_pb_files, $
             n_pb_files, $
             n_pb_files, $
             n_nrgf_files, $
             n_nrgf_files, $
             n_nrgf_files, $
             n_pb_avg_files, $
             n_pb_avg_files, $
             n_pb_avg_files, $
             n_pb_extavg_files, $
             n_nrgf_extavg_files]
  set_expression += '=' + strtrim(n_files, 2)
  set_expression = strjoin(set_expression, ', ')
  db->execute, 'update mlso_numfiles set %s where day_id=''%d''', $
               set_expression, obsday_index, $
               status=status, error_message=error_message, sql_statement=sql_cmd
  if (status ne 0L) then begin
    mg_log, 'error updating mlso_numfiles table', name=log_name, /error
    mg_log, 'status: %d, error message: %s', status, error_message, $
            name=log_name, /error
    mg_log, 'SQL command: %s', sql_cmd, name=log_name, /error
  endif

  done:
  cd, start_dir

  mg_log, 'done', name=log_name, /info
end


; main-level example program

date = '20180802'
filelist = ['20180802_204107_kcor_l2.fts']

run = kcor_run(date, $
               config_filename=filepath('kcor.latest.cfg', $
                                        subdir=['..', '..', 'config'], $
                                        root=mg_src_root()))
obsday_index = mlso_obsday_insert(date, run=run)
kcor_img_insert, date, filelist, run=run, obsday_index=obsday_index
obj_destroy, run

end
