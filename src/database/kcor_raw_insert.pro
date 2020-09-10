; docformat = 'rst'

;+
; Utility to insert values into the MLSO database table: kcor_raw.
;
; Reads a list of L0 files for a specified date and inserts a row of data into
; 'kcor_raw'.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;   files : in, required, type=strarr
;     array of FITS files to insert into the database
;   quality : in, required, type=string
;     quality for images: 'oka', 'brt', 'cal', 'cld', 'dev', 'dim', 'nsy', or
;     'sat'
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;   obsday_index : in, required, type=integer
;     index into mlso_numfiles database table
;   database : in, optional, type=MGdbMySql object
;     database connection to use
;   log_name : in, required, type=string
;     log name to use for logging, i.e., "kcor/rt", "kcor/eod", etc.
;
; :Examples:
;   For example::
;
;     date = '20170204'
;     filelist = ['20170204_205610_kcor.fts.gz', '20170204_205625_kcor.fts.gz']
;     kcor_raw_insert, date, filelist, 'oka', run=run, obsday_index=obsday_index
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
pro kcor_raw_insert, date, fits_list, quality, $
                     run=run, $
                     database=database, $
                     obsday_index=obsday_index, $
                     log_name=log_name
  compile_opt strictarr
  on_error, 2

  ; connect to MLSO database

  ; Note: The connect procedure accesses DB connection information in the file
  ;       .mysqldb. The "config_section" parameter specifies which group of data
  ;       to use.
  if (obj_valid(database)) then begin
    db = database

    db->getProperty, host_name=host
    mg_log, 'using connection to %s', host, name=log_name, /debug
  endif else begin
    db = mgdbmysql()
    db->connect, config_filename=run->config('database/config_filename'), $
                 config_section=run->config('database/config_section')

    db->getProperty, host_name=host
    mg_log, 'connected to %s', host, name=log_name, /info
  endelse

  year  = strmid(date, 0, 4)   ; yyyy
  month = strmid(date, 4, 2)   ; mm
  day   = strmid(date, 6, 2)   ; dd

  date_dir = filepath(date, root=run->config('processing/raw_basedir'))
  cd, current=start_dir 
  cd, date_dir

  ; step through list of fits files passed in parameter
  n_files = n_elements(fits_list)
  if (n_files eq 0) then begin
    mg_log, 'no images in FITS list for %s', quality, name=log_name, /info
    goto, done
  endif

  for i = 0L, n_files - 1L do begin
    fts_file = fits_list[i]

    if (~file_test(fts_file)) then begin
      mg_log, '%s (%s) not found', fts_file, quality, name=log_name, /warn
      continue
    endif else begin
      mg_log, 'ingesting %s (%s)', fts_file, quality, name=log_name, /info
    endelse

    ; extract desired items from header
    kcor_read_rawdata, fts_file, image=image, header=hdu, $
                       repair_routine=run->epoch('repair_routine'), $
                       xshift=run->epoch('xshift_camera'), $
                       start_state=run->epoch('start_state')

    date_obs = sxpar(hdu, 'DATE-OBS', count=qdate_obs)
    date_end = sxpar(hdu, 'DATE-END', count=qdate_end)

    mean_int_img0 = mean(image[*, *, 0, 0])
    mean_int_img1 = mean(image[*, *, 1, 0])
    mean_int_img2 = mean(image[*, *, 2, 0])
    mean_int_img3 = mean(image[*, *, 3, 0])
    mean_int_img4 = mean(image[*, *, 0, 1])
    mean_int_img5 = mean(image[*, *, 1, 1])
    mean_int_img6 = mean(image[*, *, 2, 1])
    mean_int_img7 = mean(image[*, *, 3, 1])

    median_int_img0 = median(image[*, *, 0, 0])
    median_int_img1 = median(image[*, *, 1, 0])
    median_int_img2 = median(image[*, *, 2, 0])
    median_int_img3 = median(image[*, *, 3, 0])
    median_int_img4 = median(image[*, *, 0, 1])
    median_int_img5 = median(image[*, *, 1, 1])
    median_int_img6 = median(image[*, *, 2, 1])
    median_int_img7 = median(image[*, *, 3, 1])

    ; normalize odd values for date/times, particularly "60" as minute value in
    ; DATE-END
    date_obs = kcor_normalize_datetime(date_obs, error=error)
    date_end = kcor_normalize_datetime(date_end, error=error)
    if (error ne 0L) then begin
      date_end = kcor_normalize_datetime(date_obs, error=error, /add_15)
    endif

    level = 'L0'
    fits_file = file_basename(fts_file, '.gz') ; remove '.gz' from file name.

    ; get IDs from relational tables

    level_count = db->query('SELECT count(level_id) FROM kcor_level WHERE level=''%s''', $
                            level, fields=fields)
    if (level_count.count_level_id_ eq 0) then begin
      ; if given level is not in the kcor_level table, set it to 'unknown' and
      ; log error
      level = 'unk'
      mg_log, 'level: %s', level, name=log_name, /error
    endif
    level_results = db->query('SELECT * FROM kcor_level WHERE level=''%s''', $
                              level, fields=fields)
    level_num = level_results.level_id	

    quality_count = db->query('SELECT count(quality_id) FROM kcor_quality WHERE quality=''%s''', $
                              quality, fields=fields)
    if (quality_count.count_quality_id_ eq 0) then begin
      ; if given quality is not in the kcor_quality table, exit
      mg_log, 'unknown quality: %s', quality, name=log_name, /error
      goto, done
    endif
    quality_results = db->query('SELECT * FROM kcor_quality WHERE quality=''%s''', $
                                quality, fields=fields)
    quality_id = quality_results.quality_id

    ; DB insert command
    db->execute, 'INSERT INTO kcor_raw (file_name, date_obs, date_end, obs_day, level, quality_id, mean_int_img0, mean_int_img1, mean_int_img2, mean_int_img3, mean_int_img4, mean_int_img5, mean_int_img6, mean_int_img7, median_int_img0, median_int_img1, median_int_img2, median_int_img3, median_int_img4, median_int_img5, median_int_img6, median_int_img7) VALUES (''%s'', ''%s'', ''%s'', %d, %d, %d, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)', $
                 fits_file, date_obs, date_end, obsday_index, level_num, quality_id, $
                 mean_int_img0, mean_int_img1, mean_int_img2, mean_int_img3, $
                 mean_int_img4, mean_int_img5, mean_int_img6, mean_int_img7, $
                 median_int_img0, median_int_img1, median_int_img2, median_int_img3, $
                 median_int_img4, median_int_img5, median_int_img6, median_int_img7, $
                 status=status, error_message=error_message, sql_statement=sql_cmd

    if (status ne 0L) then begin
      mg_log, 'error inserting in kcor_raw table', name=log_name, /error
      mg_log, 'status: %d, error message: %s', status, error_message, $
              name=log_name, /error
      mg_log, 'SQL command: %s', sql_cmd, name=log_name, /error
    endif
  endfor

  done:
  if (~obj_valid(database)) then obj_destroy, db
  cd, start_dir

  mg_log, 'done', name=log_name, /info
end


; main-level example program

date = '20170305'
filelist = ['20170305_185807_kcor.fts.gz', $
            '20170305_185822_kcor.fts.gz', $
            '20170305_185837_kcor.fts.gz']

run = kcor_run(date, $
               config_filename=filepath('kcor.mgalloy.mahi.latest.cfg', $
                                        subdir=['..', '..', 'config'], $
                                        root=mg_src_root()))
kcor_raw_insert, date, filelist, 'oka', run=run

end
