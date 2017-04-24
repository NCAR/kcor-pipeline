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
;     files = ['20170214_190402_kcor_l1.fts.gz']
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
    if (~file_test(files[f])) then begin
      mg_log, '%s not found', files[f], name='kcor/eod', /warn
      continue
    endif else begin
      mg_log, 'db inserting %s', files[f], name='kcor/eod', /info
    endelse

    image = readfits(files[f], header, /silent)
    cx = sxpar(header, 'CRPIX1') - 1.0   ; convert from FITS convention to
    cy = sxpar(header, 'CRPIX2') - 1.0   ; IDL convention

    date_obs = sxpar(header, 'DATE-OBS', count=qdate_obs)
    year   = long(strmid(date_obs,  0, 4))
    month  = long(strmid(date_obs,  5, 2))
    day    = long(strmid(date_obs,  8, 2))
    hour   = long(strmid(date_obs, 11, 2))
    minute = long(strmid(date_obs, 14, 2))
    second = long(strmid(date_obs, 17, 2))

    fhour = hour + minute / 60.0 + second / 60.0 / 60.0
    sun, year, month, day, fhour, sd=rsun, pa=pangle, la=bangle

    sun_pixels = rsun / run.plate_scale

    n_radii = 50
    start_radius = 1.1
    radius_step = 0.02
    radii = radius_step * findgen(n_radii) + start_radius
    intensity = fltarr(50)
    for r = 0L, n_radii - 1L do begin
      x = sun_pixels * radii[r] * cos(theta) + cx
      y = sun_pixels * radii[r] * sin(theta) + cy
      intensity[r] = mean(image[round(x), round(y)])
    endfor

    r13 = kcor_annulus_gridmeans(image, 1.3, sun_pixels)
    r18 = kcor_annulus_gridmeans(image, 1.8, sun_pixels)

    db->execute, 'INSERT INTO kcor_sci (file_name, obs_day, intensity, r13, r18) VALUES (''%s'', %d, ''%s'', ''%s'', ''%s'')', $
                 file_basename(files[f], '.gz'), $
                 obsday_index, $
                 db->escape_string(intensity), $
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

files = ['20170318_205523_kcor_l1.fts.gz']
kcor_sci_insert, date, files, run=run, database=db, obsday_index=obsday_index

results = db->query('select * from kcor_sci', sql_statement=cmd, error=error, fields=fields)
help, error

;heap_free, results

obj_destroy, db

end
