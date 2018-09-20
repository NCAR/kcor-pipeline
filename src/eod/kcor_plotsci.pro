; docformat = 'rst'

;+
; Produce plots for the daily science image.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;   daily_science_file : in, required, type=string
;     filename of science image to produce plot for
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;-
pro kcor_plotsci, date, daily_science_file, run=run
  compile_opt strictarr

  mg_log, 'starting', name='kcor/eod', /info
  mg_log, '%s', file_basename(daily_science_file), name='kcor/eod', /info

  cd, current=orig_dir
  cd, filepath('', subdir=[date, 'level1'], root=run.raw_basedir)

  time = strmid(file_basename(daily_science_file), 9, 6)

  intensity = kcor_extract_radial_intensity(daily_science_file, $
                                            run->epoch('plate_scale'), $
                                            radii=radii, $
                                            standard_deviation=intensity_stddev)

  ; save original plotting environment to restore later
  orig_device = !d.name
  device, get_decomposed=orig_decomposed
  tvlct, orig_rgb, /get

  ; set up plotting environment
  set_plot, 'Z'
  device, set_resolution=[772, 250], decomposed=0, set_colors=256, z_buffering=0
  loadct, 0, /silent
  tvlct, red, green, blue, /get

  plot, radii, intensity, $
        title=string(date, time, format='(%"Radial intensity for %s @ %s UT")'), $
        xtitle='radius [R_sun]', xstyle=9, xrange=[1.0, 3.0], $
        ytitle='intensity [B/B_sun]', /ylog, yrange=[1.0e-9, 2.0e-6], ystyle=9, $
        color=0, background=255
  oplot, radii, intensity + intensity_stddev, linestyle=1, color=0
  oplot, radii, intensity - intensity_stddev, linestyle=1, color=0

  plot_image = tvrd()

  sci_intensity_plot_basename = string(date, format='(%"%s.kcor.daily.intensity.gif")')
  sci_intensity_plot_filename = filepath(sci_intensity_plot_basename, $
                                         subdir=[date, 'p'], $
                                         root=run.raw_basedir)
  write_gif, sci_intensity_plot_filename, plot_image, red, green, blue

  done:

  cd, orig_dir

  ; restore original plotting environment
  set_plot, orig_device
  device, decomposed=orig_decomposed
  tvlct, orig_rgb

  mg_log, 'done', name='kcor/eod', /info
end


; main-level example program

date = '20160803'
filename = '20160803_223136_kcor_l1.fts.gz'
config_filename = filepath('kcor.mgalloy.mahi.susino.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)

kcor_plotsci, date, filename, run=run

obj_destroy, run

end
