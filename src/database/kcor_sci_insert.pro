; docformat = 'rst'

;+
; Utility to insert values into the MLSO database table: kcor_sci.
;
; Reads a list of L2 files for a specified date and inserts a row of data
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
;   database : in, optional, type=KCordbMySql object
;     database connection to use
;
; :Examples:
;   For example::
;
;     date = '20170204'
;     files = ['20170214_190402_kcor_l2.fts.gz']
;     kcor_sci_insert, date, files, run=run, obsday_index=obsday_index
;
; :Author:
;   mgalloy
;-
pro kcor_sci_insert, date, files, $
                     run=run, $
                     database=db, $
                     obsday_index=obsday_index
  compile_opt strictarr
  on_error, 2

  if (n_params() ne 2) then begin
    mg_log, 'missing date or filelist parameters', name='kcor/eod', /error
    return
  endif

  ; connect to MLSO database
  db->getProperty, host_name=host
  mg_log, 'using connection to %s', host, name='kcor/eod', /debug

  l2_dir = filepath('level2', subdir=date, root=run->config('processing/raw_basedir'))
  cd, current=start_dir
  cd, l2_dir

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

    level_name = strtrim(sxpar(header, 'LEVEL'), 2)

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
    sun, year, month, day, fhour, sd=rsun, pa=pangle, la=bangle

    run.time = date_obs
    sun_pixels = rsun / run->epoch('plate_scale')

    intensity = kcor_extract_radial_intensity(files[f], $
                                              run->epoch('plate_scale'), $
                                              standard_deviation=intensity_stddev)

    x = (rebin(reform(findgen(1024), 1024, 1), 1024, 1024) - cx) / sun_pixels
    y = (rebin(reform(findgen(1024), 1, 1024), 1024, 1024) - cy) / sun_pixels
    d = sqrt(x^2 + y^2)
    annulus = where(d gt 1.1 and d lt 2.0, count)
    total_pb = count eq 0L ? 0.0 : total(image[annulus], /preserve_type)

    r111 = kcor_annulus_gridmeans(image, 1.11, sun_pixels)
    r115 = kcor_annulus_gridmeans(image, 1.15, sun_pixels)
    r120 = kcor_annulus_gridmeans(image, 1.2, sun_pixels)
    r135 = kcor_annulus_gridmeans(image, 1.35, sun_pixels)
    r150 = kcor_annulus_gridmeans(image, 1.5, sun_pixels)
    r175 = kcor_annulus_gridmeans(image, 1.75, sun_pixels)
    r200 = kcor_annulus_gridmeans(image, 2.0, sun_pixels)
    r225 = kcor_annulus_gridmeans(image, 2.25, sun_pixels)
    r250 = kcor_annulus_gridmeans(image, 2.5, sun_pixels)

    enhanced_radius = run->epoch('enhanced_radius')
    enhanced_amount = run->epoch('enhanced_amount')
    enhanced_image = kcor_enhanced(image, $
                                   radius=enhanced_radius, $
                                   amount=enhanced_amount)
    enhanced_r111 = kcor_annulus_gridmeans(enhanced_image, 1.11, sun_pixels)
    enhanced_r115 = kcor_annulus_gridmeans(enhanced_image, 1.15, sun_pixels)
    enhanced_r120 = kcor_annulus_gridmeans(enhanced_image, 1.2, sun_pixels)
    enhanced_r135 = kcor_annulus_gridmeans(enhanced_image, 1.35, sun_pixels)
    enhanced_r150 = kcor_annulus_gridmeans(enhanced_image, 1.5, sun_pixels)
    enhanced_r175 = kcor_annulus_gridmeans(enhanced_image, 1.75, sun_pixels)
    enhanced_r200 = kcor_annulus_gridmeans(enhanced_image, 2.0, sun_pixels)
    enhanced_r225 = kcor_annulus_gridmeans(enhanced_image, 2.25, sun_pixels)
    enhanced_r250 = kcor_annulus_gridmeans(enhanced_image, 2.5, sun_pixels)

    level_id = kcor_get_level_id(level_name, database=db, count=level_found)
    if (level_found eq 0) then mg_log, 'using unknown level', name=log_name, /error

    fields = [{name: 'file_name', type: '''%s'''}, $
              {name: 'date_obs', type: '''%s'''}, $
              {name: 'obs_day', type: '%d'}, $
              {name: 'level', type: '%d'}, $
              {name: 'totalpB', type: '%f'}, $
              {name: 'intensity', type: '''%s'''}, $
              {name: 'intensity_stddev', type: '''%s'''}, $
              {name: 'r111', type: '''%s'''}, $
              {name: 'r115', type: '''%s'''}, $
              {name: 'r12', type: '''%s'''}, $
              {name: 'r135', type: '''%s'''}, $
              {name: 'r15', type: '''%s'''}, $
              {name: 'r175', type: '''%s'''}, $
              {name: 'r20', type: '''%s'''}, $
              {name: 'r225', type: '''%s'''}, $
              {name: 'r25', type: '''%s'''}, $
              {name: 'enhanced_r111', type: '''%s'''}, $
              {name: 'enhanced_r115', type: '''%s'''}, $
              {name: 'enhanced_r12', type: '''%s'''}, $
              {name: 'enhanced_r135', type: '''%s'''}, $
              {name: 'enhanced_r15', type: '''%s'''}, $
              {name: 'enhanced_r175', type: '''%s'''}, $
              {name: 'enhanced_r20', type: '''%s'''}, $
              {name: 'enhanced_r225', type: '''%s'''}, $
              {name: 'enhanced_r25', type: '''%s'''}]

    sql_cmd = string(strjoin(fields.name, ', '), $
                     strjoin(fields.type, ', '), $
                     format='(%"insert into kcor_sci (%s) values (%s)")')

    db->execute, sql_cmd, $
                 file_basename(files[f], '.gz'), $
                 date_obs, $
                 obsday_index, $
                 level_id, $
                 total_pb, $

                 db->escape_string(intensity), $
                 db->escape_string(intensity_stddev), $

                 db->escape_string(r111), $
                 db->escape_string(r115), $
                 db->escape_string(r120), $
                 db->escape_string(r135), $
                 db->escape_string(r150), $
                 db->escape_string(r175), $
                 db->escape_string(r200), $
                 db->escape_string(r225), $
                 db->escape_string(r250), $

                 db->escape_string(enhanced_r111), $
                 db->escape_string(enhanced_r115), $
                 db->escape_string(enhanced_r120), $
                 db->escape_string(enhanced_r135), $
                 db->escape_string(enhanced_r150), $
                 db->escape_string(enhanced_r175), $
                 db->escape_string(enhanced_r200), $
                 db->escape_string(enhanced_r225), $
                 db->escape_string(enhanced_r250), $

                 status=status
    if (status ne 0L) then continue
  endfor

  done:
  cd, start_dir

  mg_log, 'done', name='kcor/eod', /info
end


; main-level example program

date = '20221007'
run = kcor_run(date, $
               config_filename=filepath('kcor.latest.cfg', $
                                        subdir=['..', '..', '..', 'kcor-config'], $
                                        root=mg_src_root()))

obsday_index = mlso_obsday_insert(date, run=run, database=db)

files = ['20221007_172234_kcor_l2.fts.gz']
kcor_sci_insert, date, files, run=run, database=db, obsday_index=obsday_index

results = db->query('select * from kcor_sci', sql_statement=cmd, error=error, fields=fields)
help, error

;heap_free, results

obj_destroy, db

end
