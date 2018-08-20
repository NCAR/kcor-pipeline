; docformat = 'rst'

;+
; Utility to insert values into the MLSO database table: kcor_sci.
;
; Reads a list of L1 files for a specified date and inserts a row of data
; into 'kcor_cal' table.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;   files: in, required, type=strarr
;     array of FITS files to insert into the database
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;   obsday_index : in, required, type=integer
;     index into mlso_numfiles database table
;   database : in, optional, type=MGdbMySql object
;     database connection to use
;
; :Examples:
;   For example::
;
;     date = '20170204'
;     files = ['20170214_190402_kcor_l1.5.fts.gz']
;     kcor_sci_insert, date, files, run=run, obsday_index=obsday_index
;
; :Author:
;   mgalloy
;-
pro kcor_sci_insert, date, files, $
                     run=run, $
                     database=database, $
                     obsday_index=obsday_index
  compile_opt strictarr
  on_error, 2

  if (n_params() ne 2) then begin
    mg_log, 'missing date or filelist parameters', name='kcor/eod', /error
    return
  endif

  ; connect to MLSO database

  ; Note: The connect procedure accesses DB connection information in the file
  ;       .mysqldb. The "config_section" parameter specifies
  ;       which group of data to use.
  if (obj_valid(database)) then begin
    db = database

    db->getProperty, host_name=host
    mg_log, 'using connection to %s', host, name='kcor/eod', /debug
  endif else begin
    db = mgdbmysql()
    db->connect, config_filename=run.database_config_filename, $
                 config_section=run.database_config_section

    db->getProperty, host_name=host
    mg_log, 'connected to %s', host, name='kcor/eod', /info
  endelse

  l1_dir = filepath('level1', subdir=date, root=run.raw_basedir)
  cd, current=start_dir
  cd, l1_dir

  ; angles for full circle in radians
  theta = findgen(360) * !dtor

  for f = 0L, n_elements(files) - 1L do begin
    if (~file_test(files[f])) then files[f] += '.gz'

    if (~file_test(files[f])) then begin
      mg_log, '%s not found', files[f], name='kcor/eod', /warn
      continue
    endif else begin
      mg_log, 'inserting %s', files[f], name='kcor/eod', /info
    endelse

    image = readfits(files[f], header, /silent)
    cx = sxpar(header, 'CRPIX1') - 1.0   ; convert from FITS convention to
    cy = sxpar(header, 'CRPIX2') - 1.0   ; IDL convention

    level_name = strtrim(sxpar(hdu, 'LEVEL'), 2)

    date_obs = sxpar(header, 'DATE-OBS', count=qdate_obs)

    ; normalize odd values for date/times
    date_obs = kcor_normalize_datetime(date_obs)

    year   = long(strmid(date_obs,  0, 4))
    month  = long(strmid(date_obs,  5, 2))
    day    = long(strmid(date_obs,  8, 2))
    hour   = long(strmid(date_obs, 11, 2))
    minute = long(strmid(date_obs, 14, 2))
    second = long(strmid(date_obs, 17, 2))

    fhour = hour + minute / 60.0 + second / 60.0 / 60.0
    mlso_sun, year, month, day, fhour, sd=rsun, pa=pangle, la=bangle

    run.time = date_obs
    sun_pixels = rsun / run->epoch('plate_scale')

    n_radii = 90
    start_radius = 1.05
    radius_step = 0.02
    radii = radius_step * findgen(n_radii) + start_radius
    intensity = fltarr(n_radii)
    intensity_stddev = fltarr(n_radii)
    for r = 0L, n_radii - 1L do begin
      x = sun_pixels * radii[r] * cos(theta) + cx
      y = sun_pixels * radii[r] * sin(theta) + cy
      intensity[r] = mean(image[round(x), round(y)])
      intensity_stddev[r] = stddev(image[round(x), round(y)])
    endfor

    x = (rebin(reform(findgen(1024), 1024, 1), 1024, 1024) - cx) / sun_pixels
    y = (rebin(reform(findgen(1024), 1, 1024), 1024, 1024) - cy) / sun_pixels
    d = sqrt(x^2 + y^2)
    annulus = where(d gt 1.1 and d lt 2.0, count)

    total_pb = count eq 0L ? 0.0 : total(image[annulus], /preserve_type)

    r108 = kcor_annulus_gridmeans(image, 1.08, sun_pixels)
    r13 = kcor_annulus_gridmeans(image, 1.3, sun_pixels)
    r18 = kcor_annulus_gridmeans(image, 1.8, sun_pixels)

    level_id = kcor_get_level_id(level_name, database=db, count=level_found)
    if (level_found eq 0) then mg_log, 'using unknown level', name=log_name, /error

    db->execute, 'INSERT INTO kcor_sci (file_name, date_obs, obs_day, level, totalpB, intensity, intensity_stddev, r108, r13, r18) VALUES (''%s'', ''%s'', %d, %d, %f, ''%s'', ''%s'', ''%s'', ''%s'', ''%s'')', $
                 file_basename(files[f], '.gz'), $
                 date_obs, $
                 obsday_index, $
                 level_id,
                 total_pb, $
                 db->escape_string(intensity), $
                 db->escape_string(intensity_stddev), $
                 db->escape_string(r108), $
                 db->escape_string(r13), $
                 db->escape_string(r18), $
                 status=status, $
                 error_message=error_message, $
                 sql_statement=sql_cmd
    if (status ne 0L) then begin
      mg_log, 'error inserting into kcor_sci table', name='kcor/eod', /error
      mg_log, 'status: %d, error message: %s', status, error_message, $
              name='kcor/eod', /error
      mg_log, 'SQL command: %s', sql_cmd, name='kcor/eod', /error
    endif
  endfor

  done:
  if (~obj_valid(database)) then obj_destroy, db
  cd, start_dir

  mg_log, 'done', name='kcor/eod', /info
end


; main-level example program

date = '20161127'
run = kcor_run(date, $
               config_filename=filepath('kcor.mgalloy.mahi.latest.cfg', $
                                        subdir=['..', '..', 'config'], $
                                        root=mg_src_root()))

obsday_index = mlso_obsday_insert(date, run=run, database=db)

files = ['20170318_205523_kcor_l1.5.fts.gz']
kcor_sci_insert, date, files, run=run, database=db, obsday_index=obsday_index

results = db->query('select * from kcor_sci', sql_statement=cmd, error=error, fields=fields)
help, error

;heap_free, results

obj_destroy, db

end
