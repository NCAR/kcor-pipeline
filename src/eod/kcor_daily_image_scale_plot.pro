; docformat = 'rst'

;+
; Plot IMAGESCL value over the day.
;
; :Keywords:
;   db : in, required, type=object
;     `KCordbMySQL` object
;   run : in, required, type=object
;     `kcor_run` object
;-
pro kcor_daily_image_scale_plot, database=db, run=run
  compile_opt strictarr

  mg_log, 'querying for image scales...', name=run.logger_name, /info

  date = strjoin(kcor_decompose_date(run.date), '-')
  query = 'select * from mlso_numfiles where obs_day = ''%s'''
  data = db->query(query, date, error=error, fields=fields, sql_statement=sql)

  obs_day = data.day_id
  query = 'select * from kcor_eng where image_scale is not NULL and obs_day=%d order by date_obs'
  data = db->query(query, obs_day, $
                   count=n_files, error=error, fields=fields, sql_statement=sql)

  if (n_files eq 0L) then begin
    mg_log, 'no files found', name=run.logger_name, /warn
    goto, done
  endif else begin
    mg_log, '%d files found', n_files, name=run.logger_name, /info
  endelse

  image_scale = data.image_scale
  rcam_image_scale = data.rcam_image_scale
  tcam_image_scale = data.tcam_image_scale
  plate_scale = 0.0 * image_scale
  plate_scale_tolerance = 0.0 * image_scale

  ;for f = 0L, n_files - 1L do begin
    plate_scale[*] = run->epoch('plate_scale')
    plate_scale_tolerance[*] = run->epoch('plate_scale_tolerance')
  ;endfor

  times = kcor_dateobs2julday(data.date_obs) - 0.5 - 10.0 / 24.0
  times -= long(times[0])
  times *= 24.0

  hours_range = [6.0, 18.0]
  image_scale_range = [5.5, 5.8]
  image_scale_difference_range = 0.05 * [-1.0, 1.0]

  ; save original graphics settings
  original_device = !d.name

  mg_log, 'creating plot...', name=run.logger_name, /info

  n_plots = 3L

  ; setup graphics device
  set_plot, 'Z'
  device, get_decomposed=original_decomposed
  tvlct, original_rgb, /get
  device, decomposed=0, $
          set_pixel_depth=8, $
          set_resolution=[800, n_plots * 300]

  !p.multi = [0, 1, n_plots, 0, 0]

  tvlct, 0, 0, 0, 0
  tvlct, 255, 255, 255, 1
  tvlct, 255, 140, 0, 2
  tvlct, 255, 0, 0, 3
  tvlct, 0, 0, 255, 4
  tvlct, 255, 128, 128, 5
  tvlct, 240, 240, 240, 6
  tvlct, r, g, b, /get

  color            = 0
  background_color = 1
  clip_color       = 2
  rcam_color       = 3
  tcam_color       = 4
  platescale_color = 5
  tolerance_color  = 6

  psym             = 6
  symsize          = 0.25

  charsize = 2.0

  ; plot 1 -- normal plot of image scale over the day

  mg_range_plot, [times], [image_scale], $
                 charsize=charsize, $
                 title=string(date, format='Image scale per file for %s'), $
                 color=color, background=background_color, $
                 psym=psym, symsize=symsize, $
                 clip_color=clip_color, clip_psym=7, clip_symsize=1.0, $
                 xtitle='Time of day [HST]', $
                 xstyle=1, $
                 xticks=hours_range[1] - hours_range[0], $
                 xrange=hours_range, $
                 xminor=12, $
                 ytitle='Image scale [arcsec/pixel]', $
                 ystyle=1, yrange=image_scale_range


  if (n_files gt 1L) then begin
    ps_times = [hours_range[0], times, hours_range[1]]
    plate_scale = [plate_scale[0], plate_scale, plate_scale[-1]]
    plate_scale_tolerance = [plate_scale_tolerance[0], $
                             plate_scale_tolerance, $
                             plate_scale_tolerance[-1]]
    diffs = [0.0, plate_scale[1:-1] - plate_scale[0:-2]]
    change_indices = where(diffs gt 0.0, n_changes, /null)
    change_indices = [0L, change_indices, n_elements(plate_scale)]
    for c = 0L, n_changes do begin
      s = change_indices[c]
      e = change_indices[c + 1] - 1
      polyfill, [ps_times[s:e], reverse(ps_times[s:e]), ps_times[s]], $
                [plate_scale[s:e] + plate_scale_tolerance, $
                 reverse(plate_scale[s:e] - plate_scale_tolerance), $
                 plate_scale[s] + plate_scale_tolerance[s]], $
                color=tolerance_color
      plots, ps_times[s:e], plate_scale[s:e], linestyle=0, color=platescale_color
    endfor
  endif else begin
    plots, [times], [plate_scale], linestyle=0, color=platescale_color
  endelse

  mg_range_oplot, times, image_scale, $
                  color=color, $
                  psym=psym, symsize=symsize, $
                  clip_color=clip_color, clip_psym=7, clip_symsize=1.0

  ; plot 2 -- plot of RCAM and TCAM image scales over the day

  mg_range_plot, [times], [rcam_image_scale], /nodata, $
                 charsize=charsize, $
                 title=string(date, format='Image scale per camera per file for %s'), $
                 color=color, background=background_color, $
                 psym=psym, symsize=symsize, $
                 clip_color=clip_color, clip_psym=7, clip_symsize=1.0, $
                 xtitle='Time of day [HST]', $
                 xstyle=1, $
                 xticks=hours_range[1] - hours_range[0], $
                 xrange=hours_range, $
                 xminor=12, $
                 ytitle='Image scale [arcsec/pixel]', $
                 ystyle=1, yrange=image_scale_range
  mg_range_oplot, [times], [rcam_image_scale], $
                  color=rcam_color, $
                  psym=psym, symsize=symsize, $
                  clip_color=clip_color, clip_psym=7, clip_symsize=1.0
  mg_range_oplot, [times], [tcam_image_scale], $
                  color=tcam_color, $
                  psym=psym, symsize=symsize, $
                  clip_color=clip_color, clip_psym=7, clip_symsize=1.0

  ; plot 3 -- difference plot of RCAM and TCAM image scales over the day

  mg_range_plot, [times], [rcam_image_scale - tcam_image_scale], $
                 charsize=charsize, $
                 title=string(date, format='Image scale difference between cameras per file for %s'), $
                 color=color, background=background_color, $
                 psym=psym, symsize=symsize, $
                 clip_color=clip_color, clip_psym=7, clip_symsize=1.0, $
                 xtitle='Time of day [HST]', $
                 xstyle=1, $
                 xticks=hours_range[1] - hours_range[0], $
                 xrange=hours_range, $
                 xminor=12, $
                 ytitle='Image scale difference [arcsec/pixel]', $
                 ystyle=1, yrange=image_scale_difference_range
  plots, hours_range, fltarr(2), linestyle=0, color=tolerance_color

  ; save plots image file
  output_basename = string(run.date, $
                           format='(%"%s.kcor.daily.image_scale.gif")')
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

date = '20240409'
config_basename = 'kcor.production.cfg'
config_filename = filepath(config_basename, $
                           subdir=['..', '..', '..', 'kcor-config'], $
                           root=mg_src_root())

run = kcor_run(date, mode='test', config_filename=config_filename)

db = kcordbmysql()
db->connect, config_filename=run->config('database/config_filename'), $
             config_section=run->config('database/config_section')

kcor_daily_image_scale_plot, database=db, run=run

obj_destroy, [db, run]

end
