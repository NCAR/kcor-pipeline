; docformat = 'rst'

pro kcor_cam_difference, db, run=run
  compile_opt strictarr

  query_cmd = 'select * from kcor_eng where l0intazimeancam0 is not NULL order by date_obs;'
  sci_results = db->query(query_cmd)

  jds = kcor_dateobs2julian(sci_results.date_obs)
  percent_diff = 100.0 * (sci_results.l0intazimeancam0 - sci_results.l0intazimeancam1) / sci_results.l0intazimeancam1
  !null = label_date(date_format='%Y-%N-%D')
  device, decomposed=1
  window, xsize=1200, ysize=800, /free, $
          title='Time series of KCor dist corrected raw % difference between cameras at 1.1 Rsun'

  mg_range_plot, jds, percent_diff, $
                 xstyle=1, xtickformat='label_date', xtitle='Date', $
                 yticks=12, ytitle='% difference from camera 0', yrange=[-30.0, 30.0], $
                 psym=3, ticklen=0.01, $
                 clip_color='0000ff'x, color='000000'x, background='ffffff'x, $
                 title='KCor raw % difference between cameras at 1.1 Rsun'
  plots, [jds[0], jds[-1]], fltarr(2), color='000000'x

  window, xsize=1200, ysize=800, /free, $
          title='Heatmap of KCor raw % difference between cameras at 1.1 Rsun'
  device, decomposed=0
  loadct, 55, ncolors=254
  tvlct, 255, 255, 255, 254
  tvlct, 0, 0, 0, 255
  data = transpose([[jds], [percent_diff]])
  nbins = [1100, 750]
  percent_diff_range = [-30.0, 30.0]
  h = mg_hist_nd(data, nbins=nbins, min=[jds[0], percent_diff_range[0]], max=[jds[-1], percent_diff_range[1]])
  jds_scale = (jds[-1] - jds[0]) * dindgen(nbins[0]) / (nbins[0] - 1.0D) + jds[0]
  percent_diff_scale = (percent_diff_range[1] - percent_diff_range[0]) * dindgen(nbins[1]) / (nbins[1] - 1.0D) + percent_diff_range[0]

  mg_image, bytscl(h, 0, 100), $
            jds_scale, $
            percent_diff_scale, $
            /axes, ticklen=0.01, $
            xtickformat='label_date', xtitle='Date', $
            yticks=12, ytitle='% difference from camera 0', $
            title='KCor dist corrected raw % difference between cameras at 1.1 Rsun'
  plots, [jds[0], jds[-1]], fltarr(2)
  change_date = julday(6, 19, 2015, 0, 0, 0.0)
  ; March 15, 2015 02:01 UT
  ; June 19, 2015 00:22 UT
  plots, dblarr(2) + change_date, percent_diff_range, color=128
  xyouts, change_date, 25.0, $
          string(change_date, format='(C(CYI4.4, "-", CMOI2.2, "-", CDI2.2, "  !Cswapped color corrector lens  !Cinstalled new camera stages  !Cdistortion change  "))'), $
          alignment=1.0

  fix_date = julday(10, 1, 2018, 0, 0, 0.0)
  plots, dblarr(2) + fix_date, percent_diff_range, color=128
  xyouts, fix_date, 25.0, $
          string(fix_date, format='(C(CYI4.4, "-", CMOI2.2, "-", CDI2.2, "  "))'), $
          alignment=1.0

  dist_epochs = [julday(5, 22, 2017, 0, 0, 0), $
                 julday(3, 7, 2019, 0, 0, 0), $
                 julday(12, 16, 2019, 0, 0, 0)]
  loc_offset = 25.0
  loc_change = 4.0
  for e = 0L, n_elements(dist_epochs) - 1L do begin
    plots, dblarr(2) + dist_epochs[e], percent_diff_range, color=192, linestyle=2
    xyouts, dist_epochs[e], loc_offset - e * loc_change, $
            string(dist_epochs[e], format='(C(CYI4.4, "-", CMOI2.2, "-", CDI2.2, "  !Cdistortion correction  "))'), $
            alignment=1.0
  endfor

  query_cmd = 'select * from kcor_cal where cover="out" and diffuser="in" and calpol="out" and date_obs > "2014-01-01" order by date_obs;'
  flat_results = db->query(query_cmd)

  jds = kcor_dateobs2julian(flat_results.date_obs)

  window, xsize=1200, ysize=1000, title='Flat means', /free
  !p.multi = [0, 1, 2]
  device, decomposed=1

  preferred_exptime = 2.5

  cam0 = [[flat_results.mean_int_img0], [flat_results.mean_int_img1], [flat_results.mean_int_img2], [flat_results.mean_int_img3]]
  cam1 = [[flat_results.mean_int_img4], [flat_results.mean_int_img5], [flat_results.mean_int_img6], [flat_results.mean_int_img7]]
  cam0 = mean(cam0, dimension=2) * preferred_exptime / flat_results.exptime
  cam1 = mean(cam1, dimension=2) * preferred_exptime / flat_results.exptime

  raw_range = [0, 50000]

  plot, jds, cam0, /nodata, $
        xstyle=1, xtickformat='label_date', xtitle='Date', $
        ystyle=1, yrange=raw_range, ytitle='Flat mean', $
        color='000000'x, background='ffffff'x, $
        title='Flat mean by camera normalized to 2.5 msec'
  oplot, jds, cam0, color='ffff00'x, psym=4, symsize=0.25
  oplot, jds, cam1, color='0000ff'x, psym=4, symsize=0.25
  xyouts, 0.85, 0.95, /normal, 'camera 0', color='ffff00'x
  xyouts, 0.85, 0.94, /normal, 'camera 1', color='0000ff'x

  dist_epochs = [julday(6, 19, 2015, 0, 0, 0.0), $
                 julday(5, 22, 2017, 0, 0, 0), $
                 julday(3, 7, 2019, 0, 0, 0), $
                 julday(12, 16, 2019, 0, 0, 0)]
  loc_offset = 45000
  loc_change = 4000
  for e = 0L, n_elements(dist_epochs) - 1L do begin
    plots, dblarr(2) + dist_epochs[e], raw_range, color='0000c0'x, linestyle=2
    xyouts, dist_epochs[e], loc_offset - e * loc_change, $
            string(dist_epochs[e], format='(C(CYI4.4, "-", CMOI2.2, "-", CDI2.2, "  !Cdistortion correction  "))'), $
            alignment=1.0, color='000000'x
  endfor

  percent_diff = 100.0 * (cam0 - cam1) / cam0
  plot, jds, percent_diff, $
        xstyle=1, xtickformat='label_date', xtitle='Date', $
        ystyle=1, yrange=percent_diff_range, ytitle='Flat % difference', $
        color='000000'x, background='ffffff'x, $
        psym=4, symsize=0.25
        title='Flat mean % difference from camera 0'
  plots, [jds[0], jds[-1]], fltarr(2), color='c0c0c0'x

  loc_offset = 25.0
  loc_change = 4.0
  for e = 0L, n_elements(dist_epochs) - 1L do begin
    plots, dblarr(2) + dist_epochs[e], percent_diff_range, color='0000c0'x, linestyle=2
    xyouts, dist_epochs[e], loc_offset - e * loc_change, $
            string(dist_epochs[e], format='(C(CYI4.4, "-", CMOI2.2, "-", CDI2.2, "  !Cdistortion correction  "))'), $
            alignment=1.0, color='000000'x
  endfor

  !p.multi = 0

  save, sci_results, flat_results, filename='kcor-camera-differences.sav'
end


; main-level example

date = '20250322'
run = kcor_run(date, $
               config_filename=filepath('kcor.production.cfg', $
                                        subdir=['..', '..', '', 'kcor-config'], $
                                        root=mg_src_root()))

db = kcordbmysql(logger_name=log_name)
db->connect, config_filename=run->config('database/config_filename'), $
             config_section=run->config('database/config_section'), $
             status=status, error_message=error_message

kcor_cam_difference, db, run=run

obj_destroy, db
obj_destroy, run

end
