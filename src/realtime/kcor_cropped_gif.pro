; docformat = 'rst'

;+
; Create a cropped GIF of an image.
;
; :Params:
;   im : in, required, type="fltarr(1024, 1024)"
;     image data
;   date_obs : in, required, type=structure
;     structure with fields doy, year, month, day, hour, minute, second, ehour,
;     and month_name
;
; :Keywords:
;   nomask : in, optional, type=boolean
;     set to not apply a mask to the FITS or GIF files, adding a "nomask" to the
;     filenames
;   run : in, required, type=object
;     `kcor_run` object
;   average : in, optional, type=boolean
;     set to indicate that `im` represents an average image
;   daily : in, optional, type=boolean
;     set to indicate that `im` represents a daily image, i.e., along with
;     `AVERAGE` to indicate the `extavg` image
;   output : out, optional, type=string
;     set to a named variable to retrieve the filename of the GIF written
;-
pro kcor_cropped_gif, im, date, date_obs, $
                      nomask=nomask, $
                      daily=daily, average=average, $
                      output_filename=cgif_filename, $
                      run=run, log_name=log_name, $
                      level=level, $
                      enhanced=enhanced
  compile_opt strictarr

  start_index = 256L
  end_index   = 1024L - start_index - 1L
  width       = end_index - start_index + 1L
  height      = end_index - start_index + 1L
  crop_image  = im[start_index:end_index, start_index:end_index]

  original_device = !d.name
  set_plot, 'Z'

  erase

  ; configure device
  device, get_decomposed=original_decomposed
  device, set_resolution=[width, height], $
          decomposed=0, $
          set_colors=256, $
          z_buffering=0, $
          set_pixel_depth=8

  ; load black and white color table
  loadct, 0, /silent
  gamma_ct, 1.0, /current   ; reset gamma to linear ramp

  min = run->epoch('cropped_display_min')
  max = run->epoch('cropped_display_max')
  exp = run->epoch('cropped_display_exp')

  ; display image
  display_factor = 1.0e6
  tv, bytscl((display_factor * crop_image)^exp, $
             min=display_factor * min, $
             max=display_factor * max)

  ; print annotations

  ; top
  xyouts, 4, 495, 'MLSO/HAO/KCOR', color=255, charsize=1.2, /device
  xyouts, 256, 495, 'North', color=255, charsize=1.2, /device, alignment=0.5

  xyouts, 507, 495, $
          string(date_obs.day, date_obs.month_name, date_obs.year, $
                 date_obs.hour, date_obs.minute, date_obs.second, $
                 format='(%"%02d %s %04d %02d:%02d:%02d UT")'), $
          /device, alignment=1.0, charsize=1.0, color=255

  ; bottom
  xyouts, 4, 6, string(min, max, $
                       format='(%"min/max: %0.2g, %0.2g")'), $
          color=255, charsize=1.0, /device
  if (keyword_set(average)) then begin
    avg_type = keyword_set(daily) ? '10 min avg' : '2 min avg'
    xyouts, 256, 6, avg_type, color=255, charsize=1.0, /device, alignment=0.5
  endif
  product_name = keyword_set(enhanced) ? 'Enh Intensity' : 'Intensity'
  xyouts, 507, 6, string(product_name, exp, $
                         format='(%"scaling: %s ^ %3.1f")'), $
          color=255, charsize=1.0, /device, alignment=1.0

  ; solar radius outline
  sun, date_obs.year, date_obs.month, date_obs.day, date_obs.ehour, $
       sd=radsun
  r_photosphere = radsun / run->epoch('plate_scale')

  ; put a grid on masked GIFs
  if (~keyword_set(nomask)) then begin
    kcor_add_directions, [255.5, 255.5], r_photosphere, $
                         charsize=1.0, /cropped, dimensions=[512, 512], color=255
    kcor_suncir, 512, 512, 255.5, 255.5, 0, 0, r_photosphere, 0.0, log_name=log_name
  endif

  ; save
  raster = tvrd()
  tvlct, red, green, blue, /get

  dir = filepath(string(level, format='(%"level%d")'), $
                 subdir=date, root=run->config('processing/raw_basedir'))
  cgif_basename = string(date_obs.year, date_obs.month, date_obs.day, $
                         date_obs.hour, date_obs.minute, date_obs.second, $
                         level, $
                         level eq 2 ? '_pb' : '', $
                         keyword_set(average) $
                           ? (keyword_set(daily) ? '_extavg' : '_avg') $
                           : '', $
                         keyword_set(enhanced) ? '_enhanced' : '', $
                         keyword_set(nomask) ? '_nomask' : '', $
                         format='(%"%04d%02d%02d_%02d%02d%02d_kcor_l%d%s%s_cropped%s%s.gif")')
  cgif_filename = filepath(cgif_basename, root=dir)
  write_gif, cgif_filename, raster, red, green, blue

  done:
  device, decomposed=original_decomposed
  set_plot, original_device
end


; main-level example program

;date = '20180423'
date = '20180604'
;l1_basename = '20180424_000420_kcor_l1.5.fts.gz'
l2_basename = '20180605_011443_kcor_l2_avg.fts.gz'

config_filename = filepath('kcor.latest.cfg', $
                           subdir='../../config', $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)

l2_filename = filepath(l1_basename, $
                       subdir=[date, 'level2'], $
                       root=run->config('processing/raw_basedir'))

im = readfits(l2_filename, header, /silent)
date_obs = sxpar(header, 'DATE-OBS')
date_obs = kcor_parse_dateobs(date_obs)

kcor_cropped_gif, im, date, date_obs, run=run, /average

obj_destroy, run

end
