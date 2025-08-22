; docformat = 'rst'

pro kcor_nrgf_profile, fits_filename, nrgf_r, nrgf_mean_r, nrgf_sdev_r, r_sun, run=run
  compile_opt strictarr

  p_dir = filepath('p', subdir=[run.date], root=run->config('processing/raw_basedir'))
  if (~file_test(p_dir, /directory)) then file_mkdir, p_dir

  original_device = !d.name
  set_plot, 'Z'
  device, set_resolution=[800, 800]
  device, get_decomposed=original_decomposed
  device, decomposed=0
  tvlct, original_rgb, /get
  loadct, 0, /silent
  tvlct, r, g, b, /get

  start_radius = 1.05

  radius = nrgf_r / r_sun
  plot_indices = where(radius ge start_radius, /null)
  plot, radius[plot_indices], nrgf_mean_r[plot_indices], $
        title=string(file_basename(fits_filename), $
                     format='(%"Azimuthally averaged pB vs radius for %s")'), $
        xrange=[1.0, 3.0], xstyle=1, xtitle='Solar Radius', $
        /ylog, yrange=[1.0e-9, 2.0e-6], ystyle=1, ytitle='Calibrated averaged pB [B/Bsun]', $
        background=255, color=0

  oplot, radius[plot_indices], (nrgf_mean_r + nrgf_sdev_r)[plot_indices], $
         color=0, linestyle=1
  oplot, radius[plot_indices], (nrgf_mean_r - nrgf_sdev_r)[plot_indices], $
         color=0, linestyle=1

  im = tvrd()

  datetime = strmid(file_basename(fits_filename), 0, 15)
  basename = string(datetime, format='(%"%s_kcor_pb_radial_profile.gif")')
  filename = filepath(basename, root=p_dir)

  write_gif, filename, im, r, g, b

  done:
  tvlct, original_rgb
  device, decomposed=original_decomposed
  set_plot, original_device
end
