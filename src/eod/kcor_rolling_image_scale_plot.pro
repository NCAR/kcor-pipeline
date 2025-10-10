; docformat = 'rst'

;+
; Plot IMAGESCL value over the last `n` days.
;
; :Params:
;   end_date : in, required, type=string
;     end date of the plot in the form "YYYYMMDD"
;
; :Keywords:
;   n_days : in, optional, type=long
;     number of days to plot
;   db : in, required, type=object
;     `KCordbMySQL` object
;   run : in, required, type=object
;     `kcor_run` object
;-
pro kcor_rolling_image_scale_plot, end_date, n_days=n_days, database=db, run=run, $
                                   output_basename=output_basename
  compile_opt strictarr

  date_format = '%04d-%02d-%02d'

  end_date_tokens = long(kcor_decompose_date(end_date))
  end_date_str = string(end_date_tokens, format=date_format)
  end_date_jd = julday(end_date_tokens[1], $
                       end_date_tokens[2], $
                       end_date_tokens[0], $
                       0, 0, 0) + 1.0D

  _n_days = n_elements(n_days) eq 0L ? 90L : n_days

  start_date_jd = end_date_jd - _n_days
  caldat, start_date_jd, start_month, start_day, start_year
  start_date_str = string(start_year, start_month, start_day, format=date_format)

  mg_log, 'querying for image scales...', name=run.logger_name, /info

  date_tokens = long(kcor_decompose_date(run.date))

  query = 'select * from kcor_eng where image_scale is not NULL and date_obs between \"%s\" and \"%s\" order by date_obs'
  data = db->query(query, start_date_str, end_date_str, $
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

  plate_scale[*] = run->epoch('plate_scale')
  plate_scale_tolerance[*] = run->epoch('plate_scale_tolerance')

  jds = kcor_dateobs2julday(data.date_obs)
  if (_n_days gt 130) then begin
    xtick_format = '%M'
    xminor = 1
  endif else begin
    xtick_format = '%Y-%N-%D'
    xminor = 2
  endelse
  !null = label_date(date_format=xtick_format)

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

  charsize = 1.85

  xrange = [start_date_jd, end_date_jd]

  range_jds = jds
  range_jds[0] = xrange[0]
  range_jds[-1] = xrange[-1]

  xtickv = mg_tick_locator(xrange, /months)
  xticks = n_elements(xtickv) - 1L

  ; if (n_days_with_data lt 7L) then begin
  ;   xtickv = floor(jds[0]) - 0.5 + findgen(n_days_with_data + 1L)
  ;   xticks = n_days_with_data
  ;   xminor = 1
  ; endif else begin
  ;   default_n_periods = 5L
  ;   period_length = floor(n_days_with_data / float(default_n_periods))
  ;   n_periods = n_days_with_data / period_length + 1L
; 
  ;   xtickv = xrange[0] + findgen(n_periods) * period_length
  ;   xticks = n_periods - 1L
; 
  ;   xminor = period_length
  ; endelse

  ; plot 1 -- normal plot of image scale over the mission

  mg_range_plot, [jds], [image_scale], $
                 charsize=charsize, $
                 title=string(start_date_str, end_date_str, $
                              format='Image scale per file from %s to %s'), $
                 color=color, background=background_color, $
                 psym=psym, symsize=symsize, $
                 clip_color=clip_color, clip_psym=7, clip_symsize=1.0, $
                 xtitle='Date', $
                 xstyle=1, $
                 xtickformat='label_date', $
                 xrange=xrange, $
                 xtickv=xtickv, $
                 xticks=xticks, $
                 xminor=xminor, $
                 ytitle='Image scale [arcsec/pixel]', $
                 ystyle=1, yrange=image_scale_range

  if (n_files gt 1L) then begin
    diffs = [0.0, plate_scale[1:-1] - plate_scale[0:-2]]
    change_indices = where(diffs gt 0.0, n_changes, /null)
    change_indices = [0L, change_indices, n_elements(plate_scale)]
    for c = 0L, n_changes do begin
      s = change_indices[c]
      e = change_indices[c+1] - 1
      polyfill, [range_jds[s:e], reverse(range_jds[s:e]), range_jds[s]], $
                [plate_scale[s:e] + plate_scale_tolerance[s:e], $
                 reverse(plate_scale[s:e] - plate_scale_tolerance[s:e]), $
                 plate_scale[s] + plate_scale_tolerance[s]], $
                color=tolerance_color
      plots, range_jds[s:e], plate_scale[s:e], linestyle=0, color=platescale_color
    endfor
  endif else begin
    plots, [jds], [plate_scale], linestyle=0, color=platescale_color
  endelse

  mg_range_oplot, jds, image_scale, $
                  color=color, $
                  psym=psym, symsize=symsize, $
                  clip_color=clip_color, clip_psym=7, clip_symsize=1.0

  ; plot 2 -- plot of RCAM and TCAM image scales over the mission

  mg_range_plot, [jds], [rcam_image_scale], /nodata, $
                 charsize=charsize, $
                 title='Image scale per camera per file over the KCor mission', $
                 color=color, background=background_color, $
                 psym=psym, symsize=symsize, $
                 clip_color=clip_color, clip_psym=7, clip_symsize=1.0, $
                 xtitle='Date', $
                 xstyle=1, $
                 xtickformat='label_date', $
                 xrange=xrange, $
                 xtickv=xtickv, $
                 xticks=xticks, $
                 xminor=xminor, $
                 ytitle='Image scale [arcsec/pixel]', $
                 ystyle=1, yrange=image_scale_range
  mg_range_oplot, [jds], [rcam_image_scale], $
                  color=rcam_color, $
                  psym=psym, symsize=symsize, $
                  clip_color=clip_color, clip_psym=7, clip_symsize=1.0
  mg_range_oplot, [jds], [tcam_image_scale], $
                  color=tcam_color, $
                  psym=psym, symsize=symsize, $
                  clip_color=clip_color, clip_psym=7, clip_symsize=1.0
  xyouts, 0.825, 0.62, /normal, 'RCAM (camera 0)', charsize=0.85, color=rcam_color
  xyouts, 0.825, 0.60, /normal, 'TCAM (camera 1)', charsize=0.85, color=tcam_color

  ; plot 3 -- difference plot of RCAM and TCAM image scales over the mission

  mg_range_plot, [jds], [rcam_image_scale - tcam_image_scale], $
                 charsize=charsize, $
                 title='Image scale difference (RCAM - TCAM) between cameras per file over the KCor mission', $
                 color=color, background=background_color, $
                 psym=psym, symsize=symsize, $
                 clip_color=clip_color, clip_psym=7, clip_symsize=1.0, $
                 xtitle='Date', $
                 xstyle=1, $
                 xtickformat='label_date', $
                 xrange=xrange, $
                 xtickv=xtickv, $
                 xticks=xticks, $
                 xminor=xminor, $
                 ytitle='Image scale difference [arcsec/pixel]', $
                 ystyle=1, yrange=image_scale_difference_range
  plots, xrange, fltarr(2), color=tolerance_color

  ; save plots image file
  if (n_elements(output_basename) eq 0L) then begin
    output_basename = string(run.date, _n_days, $
                            format='(%"%s.kcor.rolling.%dday.image_scale.gif")')
  endif
  output_filename = filepath(output_basename, $
                             subdir=[run.date, 'p'], $
                             root=run->config('processing/raw_basedir'))
  mg_log, 'writing %s', output_basename, name=run.logger_name, /info
  write_gif, output_filename, tvrd(), r, g, b

  done:
  !p.multi = 0
  if (n_elements(original_rgb) gt 0L) then tvlct, original_rgb
  if (n_elements(original_decomposed) gt 0L) then device, decomposed=original_decomposed
  if (n_elements(original_device) gt 0L) then set_plot, original_device

  mg_log, 'done', name=run.logger_name, /info
end


; main-level example program

date = '20221231'
config_basename = 'kcor.reprocessing.cfg'
config_filename = filepath(config_basename, $
                           subdir=['..', '..', '..', 'kcor-config'], $
                           root=mg_src_root())

run = kcor_run(date, mode='test', config_filename=config_filename)

db = kcordbmysql()
db->connect, config_filename=run->config('database/config_filename'), $
             config_section=run->config('database/config_section')

kcor_rolling_image_scale_plot, date, n_days=90, database=db, run=run

obj_destroy, [db, run]

end
