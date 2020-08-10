; docformat = 'rst'

pro kcor_plot_gain_images, config_filename, compare=compare
  compile_opt strictarr

  scale = 4L
  width = 100L
  height = 100L
  xpos = 150L
  ypos = 150L

  run = kcor_run('20190101', config_filename=config_filename)

  pattern = filepath('*.ncdf', root=run->config('calibration/out_dir'))
  calib_files = file_search(pattern, count=n_calib_files)
  print, n_calib_files, format='(%"found %d cal files")'  

  camera0_range = [1750.0, 2150.0]
  camera1_range = [1750.0, 1900.0]

  ;for f = 0L, n_calib_files - 1L do begin
  ;  basename = file_basename(calib_files[f])
  ;  print, f + 1, n_calib_files, basename, format='(%"%d/%d: %s")'
  ;  gain = mg_nc_getdata(calib_files[f], 'Gain')

  ;  window, xsize=2 * width * scale, ysize=height * scale, /free, $
  ;          title=basename
  ;  subset = gain[xpos:xpos + width - 1L, ypos:ypos + height - 1L, *]

  ;  tv, congrid(bytscl(subset[*, *, 0], camera0_range[0], camera0_range[1]), $
  ;              scale * width, scale * height), $
  ;      0
  ;  tv, congrid(bytscl(subset[*, *, 1], camera1_range[0], camera1_range[1]), $
  ;              scale * width, scale * height), $
  ;      1
  ;endfor
  
  charsize = keyword_set(compare) ? 1.75 : 1.2

  original_device = !d.name
  device, get_decomposed=original_decomposed
  set_plot, 'Z'
  device, decomposed=0

  for f = 0L, n_calib_files - 1L do begin
    basename = file_basename(calib_files[f])
    print, f + 1, n_calib_files, basename, format='(%"%d/%d: %s")'
    gain = mg_nc_getdata(calib_files[f], 'Gain')

    title = string(basename, file_basename(config_filename), $
                   format='(%"%s [%s]")')
    mg_window, xsize=12.0, ysize=(keyword_set(compare) ? 4L : 2L) * 5.0, $
               /inches, /free, title=title
    !p.multi = [0, 1, keyword_set(compare) ? 4 : 2]

    for c = 0L, 1L do begin
      plot, gain[*, 512, c], $
            xstyle=1, ystyle=1, yrange=[0.0, 2500.0], $
            psym=3, $
            title=string(c, format='(%"Shifted cal file [cameras %d]")'), $
            charsize=charsize
    endfor

    if (keyword_set(compare)) then begin
      production_calfiles = file_search(filepath(strmid(basename, 0, 8) + '*.ncdf', $
                                                 root='/hao/mlsodata1/Data/KCor/calib_files'), $
                                        count=n_production_calfiles)
      production_gain = mg_nc_getdata(production_calfiles[-1], 'Gain')

      for c = 0L, 1L do begin
        plot, production_gain[*, 512, c], $
              xstyle=1, ystyle=1, yrange=[0.0, 2500.0], $
              psym=3, $
              title=string(c, format='(%"Production cal file [cameras %d]")'), $
              charsize=charsize
      endfor
    endif

    !p.multi = 0

    im = tvrd(true=0)
    write_png, filepath(string(basename, format='(%"%s-profile.png")'), $
                        subdir='gain-profiles', $
                        root='.'), $
               im
  endfor

  set_plot, original_device
  device, decomposed=original_decomposed
  obj_destroy, run
end


; main-level example program

config_filename = filepath('kcor.production.cfg', $
                           subdir=['..', 'config'], $
                           root=mg_src_root())
kcor_plot_gain_images, config_filename, compare=0B

end
