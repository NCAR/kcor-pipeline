; docformat = 'rst'

pro kcor_nrgf_profile, fits_filename, nrgf_r, nrgf_mean_r, nrgf_sdev_r, run=run
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

  !p.multi = [0, 1, 2]

  plot, nrgf_r, nrgf_mean_r, $
        title=string(file_basename(fits_filename), $
                     format='(%"Radial means of NRGF for %s")'), $
        xrange=[0, 512], xstyle=1, xtitle='Radius [pixels]', $
        ytitle='Radial mean', $
        background=255, color=0

  plot, nrgf_r, nrgf_sdev_r, $
        title=string(file_basename(fits_filename), $
                     format='(%"Radial standard deviations of NRGF for %s")'), $
        xrange=[0, 512], xstyle=1, xtitle='Radius [pixels]', $
        ytitle='Standard deviation', $
        background=255, color=0

  !p.multi = 0

  im = tvrd()

  datetime = strmid(file_basename(fits_filename), 0, 15)
  basename = string(datetime, format='(%"%s_kcor_nrgf_profile.gif")')
  filename = filepath(basename, root=p_dir)

  write_gif, filename, im, r, g, b

  done:
  tvlct, original_rgb
  device, decomposed=original_decomposed
  set_plot, original_device
end
