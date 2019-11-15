; docformat = 'rst'

function kcor_plot_badlines_median_partition, x, ind, values
  compile_opt strictarr

  new_x = x
  new_x[*] = !values.f_nan
  new_x[ind] = values

  return, new_x
end


;+
; Make diagnostic plots of the bad line finding.
;-
pro kcor_plot_badlines_medians, datetime, cam0_medians, cam1_medians, threshold, $
                                filename, histogram_filename, $
                                n_skip=n_skip
  compile_opt strictarr

  _n_skip = n_elements(n_skip) eq 0L ? 0L : n_skip
  _cam0_medians = cam0_medians[_n_skip:-1 - _n_skip]
  _cam1_medians = cam1_medians[_n_skip:-1 - _n_skip]
  rows0 = lindgen(n_elements(_cam0_medians)) + _n_skip
  rows1 = lindgen(n_elements(_cam1_medians)) + _n_skip

  datetime_tokens = strsplit(datetime, '_', /extract)
  date = datetime_tokens[0]
  time = datetime_tokens[1]

  original_device = !d.name
  set_plot, 'Z'
  device, get_decomposed=original_decomposed
  device, set_resolution=[1000, 800], $
          decomposed=0

  tvlct, 0, 0, 0, 255
  tvlct, 255, 255, 255, 0
  over_color = 254
  tvlct, 'ff'x, '8c'x, '00'x, over_color
  grid_color = 253
  tvlct, 'a0'x, 'a0'x, 'a0'x, grid_color
  tvlct, r, g, b, /get

  font = -1

  s32 = sqrt(3.0) / 2.0
  x = [- s32, s32, 0.0, - s32]
  y = [- 0.5, - 0.5, 1.0, - 0.5] + 0.5
  usersym, x, y, /fill
  symsize = 0.75
  over_symsize = 1.5
  annotation_charsize = 1.0

  gap = threshold * 0.0375

  !p.multi = [0, 1, 2]

  yrange = [0.0, threshold * 1.05]
  over_indices0 = where(_cam0_medians gt threshold, complement=under_indices0, /null)
  over_indices1 = where(_cam1_medians gt threshold, complement=under_indices1, /null)

  under_cam0_medians = kcor_plot_badlines_median_partition(_cam0_medians, $
                                                           under_indices0, $
                                                           _cam0_medians[under_indices0])
  over_cam0_medians = kcor_plot_badlines_median_partition(_cam0_medians, $
                                                          over_indices0, $
                                                          threshold)

  plot, rows0, under_cam0_medians, psym=1, symsize=symsize, $
        xstyle=9, ystyle=9, yrange=yrange, $
        title=string(date, time, $
                     format='(%"%s %s camera 0 median of column convolutions")'), $
        xtitle='Row', ytitle='Median', $
        font=font
  oplot, rows0, over_cam0_medians, psym=8, symsize=over_symsize, color=over_color
  oplot, rows0, fltarr(n_elements(_cam0_medians)) + threshold, linestyle=2, color=grid_color
  for o = 0L, n_elements(over_indices0) - 1L do begin
    xyouts, over_indices0[o], threshold - gap, $
            string(_cam0_medians[over_indices0[o]], format='(%"%0.2f")'), $
            font=font, alignment=0.5, charsize=annotation_charsize
    xyouts, over_indices0[o], threshold - 2 * gap, $
            string(over_indices0[o] + _n_skip, format='(%"%d")'), $
            font=font, alignment=0.5, charsize=annotation_charsize
  endfor


  under_cam1_medians = kcor_plot_badlines_median_partition(_cam1_medians, $
                                                           under_indices1, $
                                                           _cam1_medians[under_indices1])
  over_cam1_medians = kcor_plot_badlines_median_partition(_cam1_medians, $
                                                          over_indices1, $
                                                          threshold)

  plot, rows1, under_cam1_medians, psym=1, symsize=symsize, $
        xstyle=9, ystyle=9, yrange=yrange, $
        title=string(date, time, $
                     format='(%"%s %s camera 1 median of column convolutions")'), $
        xtitle='Row', ytitle='Median', $
        font=font
  oplot, rows1, over_cam1_medians, psym=8, symsize=over_symsize, color=over_color
  oplot, fltarr(n_elements(_cam1_medians)) + threshold, linestyle=2, color=grid_color
  for o = 0L, n_elements(over_indices1) - 1L do begin
    xyouts, over_indices1[o], threshold - gap, $
            string(_cam1_medians[over_indices1[o]], format='(%"%0.2f")'), $
            font=font, alignment=0.5, charsize=annotation_charsize
    xyouts, over_indices1[o], threshold - 2 * gap, $
            string(over_indices1[o] + _n_skip, format='(%"%d")'), $
            font=font, alignment=0.5, charsize=annotation_charsize
  endfor

  im = tvrd()
  write_gif, filename, im, r, g, b

  !p.multi = [0, 1, 2]

  yrange = [1.0e-1, 1024.0]
  usersym, [-1.0, 1.0, 1.0, -1.0, -1.0], 0.25 * [-1.0, -1.0, 1.0, 1.0, -1.0], /fill
  symsize = 1.25
  nbins = 63
  max = threshold * 1.05

  h0 = histogram(_cam0_medians, min=0.0, max=max, nbins=nbins, locations=locs0)
  !null = where(_cam0_medians gt max, n_over_max0)
  bin_size0 = locs0[1] - locs0[0]
  plot, locs0, h0, /nodata, $
        /ylog, xstyle=1, ystyle=1, yticklen=0.01, $
        xrange=[locs0[0], locs0[-1] + bin_size0], yrange=yrange, $
        font=font, $
        title=string(date, time, format='(%"%s %s camera 0 histogram")'), $
        xtitle='Threshold', ytitle='Number of rows'
  for i = 0L, n_elements(locs0) - 2L do begin
    oplot, fltarr(2) + locs0[i + 1L], yrange, linestyle=2, color=grid_color
  endfor
  oplot, locs0 + 0.5 * bin_size0, h0, psym=8, symsize=symsize
  oplot, fltarr(2) + threshold, yrange, color=over_color, thick=2.0

  usersym, [-0.5, 1.0, -0.5, -0.5], s32 * [-1, 0, 1, -1], /fill
  oplot, [locs0[-1] + 0.5 * bin_size0], [n_over_max0], color=over_color, $
         psym=8, symsize=over_symsize

  usersym, [-1.0, 1.0, 1.0, -1.0, -1.0], 0.25 * [-1.0, -1.0, 1.0, 1.0, -1.0], /fill

  h1 = histogram(_cam1_medians, min=0.0, max=max, nbins=nbins, locations=locs1)
  !null = where(_cam1_medians gt max, n_over_max1)
  bin_size1 = locs1[1] - locs1[0]
  plot, locs1, h1, /nodata, $
        /ylog, xstyle=1, ystyle=1, yticklen=0.01, $
        xrange=[locs1[0], locs1[-1] + bin_size1], yrange=yrange, $
        psym=1, symsize=symsize, $
        font=font, $
        title=string(date, time, format='(%"%s %s camera 1 histogram")'), $
        xtitle='Threshold', ytitle='Number of rows'
  for i = 0L, n_elements(locs1) - 2L do begin
    oplot, fltarr(2) + locs1[i + 1L], yrange, linestyle=2, color=grid_color
  endfor
  oplot, locs1 + 0.5 * bin_size1, h1, psym=8, symsize=symsize
  oplot, fltarr(2) + threshold, yrange, color=over_color, thick=2.0

  usersym, [-0.5, 1.0, -0.5, -0.5], s32 * [-1, 0, 1, -1], /fill
  oplot, [locs1[-1] + 0.5 * bin_size1], [n_over_max1], color=over_color, $
         psym=8, symsize=over_symsize

  im = tvrd()
  write_gif, histogram_filename, im, r, g, b

  !p.multi = 0
  set_plot, original_device
  device, decomposed=original_decomposed
end
