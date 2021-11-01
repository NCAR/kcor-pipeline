; docformat = 'rst'

pro kcor_plot_calibration, cal_filename, run=run, gain_norm_stddev=gain_norm_stddev
  compile_opt strictarr

  logger_name = run.logger_name

  base_dir  = run->config('processing/raw_basedir')
  date_dir  = filepath(run.date, root=base_dir)
  plots_dir = filepath('p', root=date_dir)

  if (~file_test(plots_dir, /directory)) then file_mkdir, plots_dir

  norm = 1.0e-6

  ; read gain
  cal_id = ncdf_open(cal_filename)
  ncdf_varget, cal_id, 'Gain', gain
  gain *= norm
  ncdf_close, cal_id

  gain_norm_stddev = fltarr(2)
  gain_stddev = fltarr(2)

  d = shift(dist(1024, 1024), 512, 512)
  min_radius = 200.0
  max_radius = 500.0
  annulus_indices = where(d lt max_radius and d gt min_radius, n_annulus)

  for c = 0, 1 do begin
    camera_gain = reform(gain[*, *, c])
    gain_stddev[c] = stddev(camera_gain[annulus_indices])
    gain_norm_stddev[c] = gain_stddev[c] / median(camera_gain[annulus_indices])
  endfor

  ; create plot of profile through gain for both cameras
  original_device = !d.name
  tvlct, original_rgb, /get

  gain_range = [0.0, 2500.0] * norm
  charsize = 1.2
  y = 512  ; height of gain profile

  set_plot, 'Z'
  device, set_resolution=[772, 500], $
          decomposed=0, $
          set_colors=256, $
          z_buffering=0
  loadct, 0, /silent
  !p.multi = [0, 1, 2]

  for c = 0, 1 do begin
    profile = gain[*, y, c]
    nx = n_elements(profile)
    r = abs(findgen(nx) - (nx - 1) / 2.0)
    x = findgen(nx)
    annulus_indices = where(r lt max_radius and r gt min_radius, complement=inside_indices)
    plot, x[annulus_indices], profile[annulus_indices], $
          title=string(run.date, c, $
                       format='(%"Profile of dark corrected gain on %s for camera %d")'), $
          xstyle=1, $
          xtitle='Column [pixels]', $
          yrange=gain_range, ystyle=1, $
          ytitle='Gain value [B/Bsun]', $
          background=255, color=0, charsize=charsize, psym=3
    oplot, x[inside_indices], profile[inside_indices], color=195
    xyouts, 0.15, 0.5 * c + 0.20, /normal, $
            string(gain_stddev[c], gain_norm_stddev[c], $
                   format='(%"std dev: %0.3g!C!Cstd dev / median: %0.4f")'), $
            charsize=1.0, color=0
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


; main-level example program

date = '20210801'
config_basename = 'kcor.latest.cfg'
config_filename = filepath(config_basename, subdir=['..', '..', 'config'], root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)

cal_basename = '20210801_190123_kcor_cal_v24_2.0.65-dev_2.500ms.ncdf'
cal_filename = filepath(cal_basename, root='/hao/twilight/Data/KCor/calib_files.latest')
kcor_plot_calibration, cal_filename, $
                       run=run, $
                       gain_norm_stddev=gain_norm_stddev

obj_destroy, run

print, gain_norm_stddev

end
