; docformat = 'rst'

;+
; Plot IMAGESCL value over the mission.
;
; :Keywords:
;   db : in, required, type=object
;     `KCordbMySQL` object
;   run : in, required, type=object
;     `kcor_run` object
;-
pro kcor_mission_image_scale_plot, database=db, run=run
  compile_opt strictarr

  mg_log, 'querying for image scales...', name=run.logger_name, /info

  query = 'select * from kcor_eng order by date_obs'
  data = db->query(query, $
                   count=n_files, error=error, fields=fields, sql_statement=sql)

  if (n_files eq 0L) then begin
    mg_log, 'no files found', name=run.logger_name, /warn
    goto, done
  endif else begin
    mg_log, '%d files found', n_files, name=run.logger_name, /info
  endelse

  image_scale = data.image_scale
  plate_scale = 0.0 * image_scale
  plate_scale_tolerance = 0.0 * image_scale

  ;for f = 0L, n_files - 1L do begin
    plate_scale[*] = run->epoch('plate_scale')
    plate_scale_tolerance[*] = run->epoch('plate_scale_tolerance')
  ;endfor

  jds = kcor_dateobs2julday(data.date_obs)
  !null = label_date(date_format='%Y-%N-%D')

  image_scale_range = [5.4, 5.8]

  ; save original graphics settings
  original_device = !d.name

  mg_log, 'creating plot...', name=run.logger_name, /info

  ; setup graphics device
  set_plot, 'Z'
  device, get_decomposed=original_decomposed
  tvlct, original_rgb, /get
  device, decomposed=0, $
          set_pixel_depth=8, $
          set_resolution=[800, 300]

  tvlct, 0, 0, 0, 0
  tvlct, 255, 255, 255, 1
  tvlct, 255, 0, 0, 2
  tvlct, 255, 128, 128, 3
  tvlct, 240, 240, 240, 4
  tvlct, r, g, b, /get

  color            = 0
  background_color = 1
  clip_color       = 2
  platescale_color = 3
  tolerance_color  = 4

  psym             = 6
  symsize          = 0.25

  month_ticks = mg_tick_locator([jds[0], jds[-1]], /months)
  if (n_elements(month_ticks) eq 0L) then begin
    month_ticks = 1L
  endif else begin
    month_ticks = month_ticks[0:*:12]
  endelse

  mg_range_plot, [jds], [image_scale], $
                 charsize=charsize, $
                 title='Image scale per file over the KCor mission', $
                 color=color, background=background_color, $
                 psym=psym, symsize=symsize, $
                 clip_color=2, clip_psym=7, clip_symsize=1.0, $
                 xtitle='Date', $
                 xstyle=1, $
                 xtickformat='label_date', $
                 xtickv=month_ticks, $
                 xticks=n_elements(month_ticks) - 1L, $
                 xminor=12, $
                 ytitle='Image scale [arcsec/pixel]', $
                 ystyle=1, yrange=image_scale_range


  if (n_files gt 1L) then begin
    diffs = [0.0, plate_scale[1:-1] - plate_scale[0:-2]]
    change_indices = where(diffs gt 0.0, n_changes, /null)
    change_indices = [0L, change_indices, n_elements(plate_scale)]
    for c = 0L, n_changes do begin
      s = change_indices[c]
      e = change_indices[c+1] - 1
      polyfill, [jds[s:e], reverse(jds[s:e]), jds[s]], $
                [plate_scale[s:e] + plate_scale_tolerance, $
                 reverse(plate_scale[s:e] - plate_scale_tolerance), $
                 plate_scale[s] + plate_scale_tolerance], $
                color=tolerance_color
      plots, jds[s:e], plate_scale[s:e], linestyle=0, color=platescale_color
    endfor
  endif else begin
    plots, [jds], [plate_scale], linestyle=0, color=platescale_color
  endelse

  mg_range_oplot, jds, image_scale, $
                  color=color, $
                  psym=psym, symsize=symsize, $
                  clip_color=2, clip_psym=7, clip_symsize=1.0

  ; save plots image file
  output_basename = string(run.date, $
                           format='(%"%s.kcor.mission.image_scale.gif")')
  output_filename = filepath(output_basename, $
                             subdir=[run.date, 'p'], $
                             root=run->config('processing/raw_basedir'))
  mg_log, 'writing %s', output_basename, name=run.logger_name, /info
  write_gif, output_filename, tvrd(), r, g, b

  done:
  if (n_elements(original_rgb) gt 0L) then tvlct, original_rgb
  if (n_elements(original_decomposed) gt 0L) then device, decomposed=original_decomposed
  if (n_elements(original_device) gt 0L) then set_plot, original_device

  mg_log, 'done', name=run.logger_name, /info
end


; main-level example program

date = '20221007'
config_basename = 'kcor.latest.cfg'
config_filename = filepath(config_basename, $
                           subdir=['..', '..', '..', 'kcor-config'], $
                           root=mg_src_root())

run = kcor_run(date, mode='test', config_filename=config_filename)

db = kcordbmysql()
db->connect, config_filename=run->config('database/config_filename'), $
             config_section=run->config('database/config_section')

kcor_mission_image_scale_plot, database=db, run=run

obj_destroy, [db, run]

end
