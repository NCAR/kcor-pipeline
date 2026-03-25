; docformat = 'rst'

;+
; Create a simple difference GIF given two pB FITS files.
;
; :Params:
;   filename1 : in, required, type=string
;     filename of the first (earlier) pB FITS file
;   filename2 : in, required, type=string
;     filename of the second (later) pB FITS file
;   output_filename : in, required, type=string
;     filename of the difference GIF
;
; :Keywords:
;   run : in, required, type=object
;     KCor run object
;-
pro kcor_cme_create_difference_gif, filename1, filename2, output_filename, run=run
  compile_opt strictarr

  im1      = readfits(filename1)
  header1  = headfits(filename1)
  im2      = readfits(filename2)
  header2  = headfits(filename2)

  dateobs1 = fxpar(header1, 'DATE-OBS')
  rsun     = fxpar(header1, 'RSUN_OBS')   ; solar radius [arcsec/Rsun]
  cdelt1   = fxpar(header1, 'CDELT1')     ; resolution [arcsec/pixel]
  r_photo  = rsun / cdelt1                ; photosphere radius [pixels/Rsun]

  dateobs2 = fxpar(header2, 'DATE-OBS')

  diff     = im2 - im1   ; later - earlier image

  original_device = !d.name
  set_plot, 'Z'
  device, get_decomposed=original_decomposed
  device, set_resolution=[1024, 1024], $
          decomposed=0, $
          set_colors=256, $
          set_pixel_depth=8, $
          z_buffering=0
  tvlct, original_rgb, /get

  n_colors = 256
  loadct, 0, /silent, ncolors=n_colors
  annotation_color = n_colors - 1

  tvlct, red, green, blue, /get

  ; display scaled difference
  display_min    = run->epoch('display_difference_min')
  display_max    = run->epoch('display_difference_max')
  display_factor = 1.0e6
  scaled_image = bytscl(display_factor * diff, $
                        min=display_factor * display_min, $
                        max=display_factor * display_max, $
                        top=n_colors - 1L)
  tv, bytscl(diff, -2.0e-8, 2.0e-8)

  ; annotate image
  xyouts, 4, 990, /device, 'MLSO/HAO/KCOR', $
          charsize=1.5, color=annotation_color
  xyouts, 4, 970, /device, 'K-Coronagraph', $
          charsize=1.5, color=annotation_color
  xyouts, 4, 46, /device, 'Subtraction', $
          color=annotation_color, charsize=1.2
  xyouts, 4, 26, /device, string(display_min, display_max, $
                                 format='("min/max: ", e0.1, ", ", e0.1)'), $
          color=annotation_color, charsize=1.2

  xyouts, 1023 - 4, 990, /device, dateobs2, alignment=1.0, $
          charsize=1.0, color=annotation_color
  xyouts, 1023 - 4 - 10, 970, /device, 'minus', alignment=1.0, $
          charsize=1.0, color=annotation_color
  xyouts, 1023 - 4, 950, /device, dateobs1, alignment=1.0, $
          charsize=1.0, color=annotation_color

  kcor_add_directions, [511.5, 511.5], r_photo, $
                       dimensions=[1024, 1024], $
                       charsize=1.0, color=annotation_color
  kcor_suncir, 1024, 1024, 511.5, 511.5, 0, 0, r_photo, 0.0, log_name='kcor/cme'

  ; write image as GIF
  save = tvrd()
  write_gif, output_filename, save, red, green, blue

  done:
  tvlct, original_rgb
  device, decomposed=original_decomposed
  set_plot, original_device
end


; main-level example program

config_basename = 'kcor.reprocess.cfg'
config_filename = filepath(config_basename, $
                           subdir=['..', '..', 'kcor-config'], $
                           root=mg_src_root())

date = '20160101'
run = kcor_run(date, config_filename=config_filename)

root_dir = run->config('processing/raw_basedir')

subdir = [date, 'level2']
f1 = filepath('20160101_230329_kcor_l2_pb.fts.gz', subdir=subdir, root=root_dir)
f2 = filepath('20160101_231320_kcor_l2_pb.fts.gz', subdir=subdir, root=root_dir)
output_filename = 'difference.gif'

kcor_cme_create_difference_gif, f1, f2, output_filename, run=run

obj_destroy, run

end
