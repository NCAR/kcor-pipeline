; docformat = 'rst'

;+
; Display image, annotate, and save as a full resolution GIF file.
;
; :Params:
;   filename : in, required, type=string
;     level 0 filename
;   corona : in, required, type="fltarr(1024, 1024)"
;     corona
;   date_obs : in, required, type=string
;     observation date
;
; :Keywords:
;   scaled_image : out, optional, type=lonarr
;     set to a named variable to retrieve the scaled image
;   nomask : in, optional, type=boolean
;     set to not mask the occulter
;   run : in, required, type=object
;     KCor run object
;   log_name : in, optional, type=string
;     logger name to send log messages to
;   level : in, required, type=integer
;     level 1 or 2
;-
pro kcor_create_gif, filename, corona, date_obs, $
                     scaled_image=scaled_image, $
                     nomask=nomask, $
                     camera=camera, $
                     occulter_radius=occulter_radius, $
                     run=run, $
                     log_name=log_name, $
                     level=level
  compile_opt strictarr

  date_struct = kcor_parse_dateobs(date_obs)
  sun, date_struct.year, date_struct.month, date_struct.day, date_struct.ehour, $
       sd=radsun
  r_photo = radsun / run->epoch('plate_scale')

  original_device = !d.name
  set_plot, 'Z'
  device, get_decomposed=original_decomposed
  device, set_resolution=[1024, 1024], $
          decomposed=0, $
          set_colors=256, $
          z_buffering=0
  tvlct, original_rgb, /get

  ; load color table
  lct, filepath('quallab_ver2.lut', root=run.resources_dir)
  tvlct, red, green, blue, /get

  n_colors = keyword_set(nomask) ? 255 : 256

  loadct, 0, /silent, ncolors=n_colors
  mg_gamma_ct, run->epoch('display_gamma'), /current, n_colors=n_colors

  if (keyword_set(nomask)) then begin
    green_color = 255
    tvlct, 0, 255, 0, green_color

    annotation_color = 254
  endif else begin
    annotation_color = 255
  endelse

  tvlct, red, green, blue, /get

  erase

  display_factor = 1.0e6
  scaled_image = bytscl((display_factor * corona)^run->epoch('display_exp'), $
                        min=display_factor * run->epoch('display_min'), $
                        max=display_factor * run->epoch('display_max'), $
                        top=n_colors - 1L)
  tv, scaled_image

  xyouts, 4, 990, /device, $
          'MLSO/HAO/KCOR', $
          charsize=1.5, $
          color=annotation_color
  xyouts, 4, 970, /device, $
          'K-Coronagraph', $
          charsize=1.5, $
          color=annotation_color
  xyouts, 512, 1000, /device, alignment=0.5, $
          'North', $
          charsize=1.2, $
          color=annotation_color
  xyouts, 1018, 995, /device, alignment=1.0, $
          string(date_struct.day, date_struct.month_name, date_struct.year, $
                 format='(%"%02d %s %04d")'), $
          charsize=1.2, $
          color=annotation_color
  xyouts, 1010, 975, /device, alignment=1.0, $
          string(date_struct.doy, format='(%"DOY %03d")'), $
          charsize=1.2, $
          color=annotation_color
  xyouts, 1018, 955, /device, alignment=1.0, $
          string(date_struct.hour, date_struct.minute, date_struct.second, $
                 format='(%"%02d:%02d:%02d UT")'), $
          charsize=1.2, $
          color=annotation_color
  xyouts, 22, 512, /device, alignment=0.5, orientation=90.0, $
          'East', charsize=1.2, $
          color=annotation_color
  xyouts, 1012, 512, /device, alignment=0.5, orientation=90.0, $
          'West', charsize=1.2, $
          color=annotation_color
  xyouts, 4, 46, /device, $
          string(level, format='(%"Level %d data")'), $
          charsize=1.2, $
          color=annotation_color
  xyouts, 4, 26, /device, $
          string(run->epoch('display_min'), $
                 run->epoch('display_max'), $
                 format='(%"min/max: %0.2g, %0.2g")'), $
          charsize=1.2, $
          color=annotation_color
  xyouts, 4, 6, /device, $
          string(run->epoch('display_exp'), $
                 run->epoch('display_gamma'), $
                 format='(%"scaling: Intensity ^ %3.1f, gamma=%4.2f")'), $
          charsize=1.2, $
          color=annotation_color
  xyouts, 1018, 6, /device, alignment=1.0, $
          'Circle = photosphere.', $
          charsize=1.2, $
          color=annotation_color

  ; image has been shifted to center of array
  ; draw circle at photosphere
  if (keyword_set(nomask)) then begin
    dims = size(scaled_image, /dimensions)
    tvcircle, occulter_radius, $
              (dims[0] - 1.0) / 2.0, $
              (dims[1] - 1.0) / 2.0, $
              green_color, /device
  endif else begin
    kcor_add_directions, fltarr(2) + 511.5, r_photo, $
                         charsize=1.5, $
                         dimensions=lonarr(2) + 1024L, $
                         color=annotation_color
    kcor_suncir, 1024, 1024, 511.5, 511.5, 0, 0, r_photo, 0.0, $
                 color=annotation_color, $
                 log_name=log_name
  endelse

  device, decomposed=1
  save     = tvrd()
  _camera = n_elements(camera) eq 0L $
              ? '' $
              : string(camera, format='_cam%d')
  gif_file = string(strmid(file_basename(filename), 0, 20), $
                    level, $
                    _camera, $
                    keyword_set(nomask) ? '_nomask' : '', $
                    format='(%"%s_l%d%s%s.gif")')
  write_gif, filepath(gif_file, $
                      subdir=[run.date, string(level, format='(%"level%d")')], $
                      root=run->config('processing/raw_basedir')), $
             save, red, green, blue

  tvlct, original_rgb
  device, decomposed=original_decomposed
  set_plot, original_device
end


; main-level example program

date = '20221007'
config_basename = 'kcor.latest.cfg'
config_filename = filepath(config_basename, $
                           subdir=['..', '..', '..', 'kcor-config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename, mode='eod')

l1_dirname = filepath('', subdir=[date, 'level1'], root=run->config('processing/raw_basedir'))
l1_basename = '20221007_173714_kcor_l1.fts.gz'
l1_filename = filepath(l1_basename, root=l1_dirname)

data = readfits(l1_filename, l1_header, /silent)
u = reform(data[*, *, 0])
q = reform(data[*, *, 1])
intensity = reform(data[*, *, 1])

corona = float(u) - float(rot(q, 45.0, /interp))

date_obs = sxpar(l1_header, 'DATE-OBS')
rcam_rad = sxpar(l1_header, 'RCAM_RAD')
tcam_rad = sxpar(l1_header, 'TCAM_RAD')
occulter_radius = (rcam_rad + tcam_rad) / 2.0

kcor_create_gif, l1_filename, corona, date_obs, $
                 level=2, $
                 scaled_image=scaled_image, $
                 nomask=1B, $
                 occulter_radius=occulter_radius, $
                 run=run, $
                 log_name=log_name

end
