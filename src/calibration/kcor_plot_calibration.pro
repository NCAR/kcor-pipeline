; docformat = 'rst'

pro kcor_plot_calibration, cal_filename, run=run, gain_norm_stddev=gain_norm_stddev
  compile_opt strictarr

  logger_name = run.logger_name

  base_dir  = run->config('processing/raw_basedir')
  date_dir  = filepath(run.date, root=base_dir)
  plots_dir = filepath('p', root=date_dir)

  if (~file_test(plots_dir, /directory)) then file_mkdir, plots_dir

  ; read gain
  cal_id = ncdf_open(cal_filename)
  ncdf_varget, cal_id, 'Gain', gain
  ncdf_close, cal_id

  gain_norm_stddev = fltarr(2)
  d = shift(dist(1024, 1024), 512, 512)
  annulus_indices = where(d lt 500 and d gt 200, n_annulus)
  
  for c = 0, 1 do begin
    camera_gain = reform(gain[*, *, c])
    gain_norm_stddev[c] = stddev(camera_gain[annulus_indices]) $
                            / median(camera_gain[annulus_indices])
  endfor

  ; create plot of profile through gain for both cameras
  original_device = !d.name
  tvlct, original_rgb, /get

  gain_range = [0.0, 2500.0]
  charsize = 1.15
  y = 512  ; height of gain profile

  set_plot, 'Z'
  device, set_resolution=[772, 500], $
          decomposed=0, $
          set_colors=256, $
          z_buffering=0
  loadct, 0, /silent
  !p.multi = [0, 1, 2]

  for c = 0, 1 do begin
    plot, gain[*, y, c], $
          title=string(run.date, c, $
                       format='(%"Profile of dark corrected gain on %s for camera %d")'), $
          xstyle=1, $
          xtitle='Column [pixels]', $
          yrange=gain_range, ystyle=1, $
          ytitle='Gain value [B/Bsun]', $
          background=255, color=0, charsize=charsize
    xyouts, 0.15, 0.5 * c + 0.25, /normal, $
            string(gain_norm_stddev[c], format='(%"std dev / median: %0.4f / %0.4f")'), $
            charsize=charsize
  endfor

  im = tvrd()
  write_gif, filepath(string(run.date, format='(%"%s.kcor.gain-profile.gif")'), $
                      root=plots_dir), $
             im

  done:
  !p.multi = 0
  tvlct, original_rgb
  set_plot, original_device
end
