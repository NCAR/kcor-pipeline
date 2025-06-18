; docformat = 'rst'

pro kcor_plot_gainmedians, run=run
  compile_opt strictarr

  n_cameras = 2L
  xsize = 1024L
  ysize = 1024L

  rcam_color = '0000ff'x
  tcam_color = '00ff00'x
  yrange = [0.0, 400.0]

  cache_file = 'annulus_medians.sav'

  if (~file_test(cache_file, /regular)) then begin
    r_out = run->epoch('r_out')
    calib_dir = run->config('calibration/out_dir')
    cal_files = file_search(filepath('*.ncdf', root=calib_dir), count=n_cal_files)
    print, n_cal_files, format='found %d cal files...'

    jds = dblarr(n_cal_files)
    annulus_medians = fltarr(n_cameras, n_cal_files)

    for f = 0L, n_cal_files - 1L do begin
      print, f + 1, n_cal_files, file_basename(cal_files[f]), format='%d/%d: %s'
      date_obs = mg_nc_getdata(cal_files[f], '.flat-date-obs')
      sgsdimv = mg_nc_getdata(cal_files[f], 'DIM Reference Voltage')
      exptime = mg_nc_getdata(cal_files[f], 'exptime')

      gain = mg_nc_getdata(cal_files[f], 'Gain')
      dark = mg_nc_getdata(cal_files[f], 'Dark')

      xcenter = [mg_nc_getdata(cal_files[f], 'Gain.RCAM x-center'), $
                mg_nc_getdata(cal_files[f], 'Gain.TCAM x-center')]
      ycenter = [mg_nc_getdata(cal_files[f], 'Gain.RCAM y-center'), $
                mg_nc_getdata(cal_files[f], 'Gain.TCAM y-center')]
      radius  = [mg_nc_getdata(cal_files[f], 'Gain.RCAM radius'), $
                mg_nc_getdata(cal_files[f], 'Gain.TCAM radius')]

      jds[f] = kcor_dateobs2julian(date_obs)

      for c = 0L, n_cameras - 1L do begin
        x = rebin(reform(dindgen(xsize), xsize, 1), xsize, ysize) - xcenter[0]
        y = rebin(reform(dindgen(ysize), 1, ysize), xsize, ysize) - ycenter[0]
        r = sqrt(x ^ 2.0 + y ^ 2.0)
        mask_indices = where(r gt radius[c] and r lt r_out)
        mask = fltarr(xsize, ysize) + !values.f_nan
        mask[mask_indices] = 1B

        dark_corrected_gain = reform(gain[*, *, c] - dark[*, *, c])
        normalized_corrected_gain = dark_corrected_gain / exptime / sgsdimv
        annulus_medians[c, f] = median(mask * normalized_corrected_gain)
      endfor
    endfor
    save, jds, annulus_medians, filename=cache_file
  endif else begin
    restore, filename=cache_file
  endelse

  !null = label_date(date_format='%Y-%N-%D')
  window, xsize=1200, ysize=600, /free, $
          title='Median of annulus of dark-corrected gains'
  xtickv = mg_tick_locator(jds, max_ticks=12, ticks=xticks, minor=xminor, /months)
  plot, jds, annulus_medians[0, *], /nodata, $
        xstyle=9, $
        xtickv=xtickv, xticks=xticks, xminor=xminor, $
        xtickformat='label_date', $
        ystyle=9, ytitle='Normalized dark-corrected gain value', yrange=yrange, $
        color='000000'x, background='ffffff'x, $
        title='Median of dark-corrected gains (normalized by exposure time and SGSDIMV)'
  oplot, jds, annulus_medians[0, *], color=rcam_color, psym=6, symsize=0.3
  oplot, jds, annulus_medians[1, *], color=tcam_color, psym=6, symsize=0.3
  xyouts, 1100.0, 500.0, 'RCAM', color=rcam_color, /device
  xyouts, 1100.0, 487.0, 'TCAM', color=tcam_color, /device

  dist_epochs = [julday(3, 18, 2015, 0, 0, 0.0), $
                 julday(8, 12, 2016, 0, 0, 0.0), $
                 julday(5, 22, 2017, 0, 0, 0), $
                 julday(1, 31, 2018, 0, 0, 0), $
                 julday(5, 22, 2018, 0, 0, 0), $
                 julday(1, 15, 2019, 0, 0, 0), $
                 julday(3, 7, 2019, 0, 0, 0), $
                 julday(12, 16, 2019, 0, 0, 0), $
                 julday(12, 26, 2020, 0, 0, 0), $
                 julday(10, 18, 2021, 0, 0, 0)]
  labels = ['cal epoch v25', $
            'cal epoch v10.1 and v10.2', $
            'distortion correction', $
            'cal epoch v15.1 and v16', $
            'cal epoch v20', $
            '?', $
            'distortion correction', $
            'distortion correction', $
            'cal epoch v24', $
            'cal epoch v25']
  for e = 0L, n_elements(dist_epochs) - 1L do begin
    plots, dblarr(2) + dist_epochs[e], yrange, color='d8d8d8'x
    xyouts, dist_epochs[e] + 20.0, 375.0 - 20.0 * (e mod 5), $
            string(dist_epochs[e], labels[e], $
                   format='(C(CYI4.4, "-", CMOI2.2, "-", CDI2.2), "!C", A)'), $
            alignment=0.0, color='a0a0a0'x
  endfor
end


; main-level example program

date = '20130930'
config_basename = 'kcor.production.cfg'
config_filename = filepath(config_basename, $
                           subdir=['..', '..', 'kcor-config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)

kcor_plot_gainmedians, run=run

obj_destroy, run

end
