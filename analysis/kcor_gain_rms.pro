; docformat = 'rst'

pro kcor_gain_rms, config_filename
  compile_opt strictarr

  width = 100L
  height = 100L
  xpos = 150L
  ypos = 150L

  run = kcor_run('20190101', config_filename=config_filename)

  pattern = filepath('2019*.ncdf', root=run->config('calibration/out_dir'))
  calib_files = file_search(pattern, count=n_calib_files)
  print, n_calib_files, format='(%"found %d cal files")'

  rms = fltarr(n_calib_files, 2)
  jds = dblarr(n_calib_files)

  for f = 0L, n_calib_files - 1L do begin
    basename = file_basename(calib_files[f])
    print, f + 1, n_calib_files, basename, format='(%"%d/%d: %s")'
    date = strmid(basename, 0, 8)
    date_parts = long(kcor_decompose_date(date))
    jds[f] = julday(date_parts[1], date_parts[2], date_parts[0])
    gain = mg_nc_getdata(calib_files[f], 'Gain')
    for c = 0L, 1L do begin
      ;m = mean(gain[xpos:xpos + width - 1L, ypos:ypos + height - 1L, c])
      ;rms[f, c] = mg_rms(gain[xpos:xpos + width - 1L, ypos:ypos + height - 1L, c])
      rms[f, c] = stddev(gain[xpos:xpos + width - 1L, ypos:ypos + height - 1L, c])
      ;rms[f, c] /= m
    endfor
  endfor

  range = mg_range(rms)
  ;range = [0.9999, 1.0002]
  !null = label_date(date_format='%Y-%N-%D')
  plot, jds, rms[*, 0], /nodata, $
        yrange=range, xstyle=1, ystyle=1, xtickformat='label_date', $
        title='Std Dev (cam 0: red, cam 1: green)'
  oplot, jds, rms[*, 0], psym=1, symsize=0.5, color='0000ff'x
  oplot, jds, rms[*, 1], psym=2, symsize=0.5, color='00ff00'x

  obj_destroy, run
end


; main-level example

config_filename = filepath('kcor.production.cfg', subdir=['..', 'config'], $
                           root=mg_src_root())
kcor_gain_rms, config_filename

end
