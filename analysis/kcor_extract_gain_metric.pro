; docformat = 'rst'

function kcor_extract_gain_metric, cal_filename
  compile_opt strictarr

  norm = 1.0e-6

  ; read gain
  cal_id = ncdf_open(cal_filename)
  ncdf_varget, cal_id, 'Gain', gain

  gain_id = ncdf_varid(cal_id, 'Gain')
  ncdf_attget, cal_id, gain_id, 'RCAM x-center', frcam_x
  ncdf_attget, cal_id, gain_id, 'RCAM y-center', frcam_y
  ncdf_attget, cal_id, gain_id, 'RCAM radius', frcam_r
  ncdf_attget, cal_id, gain_id, 'TCAM x-center', ftcam_x
  ncdf_attget, cal_id, gain_id, 'TCAM y-center', ftcam_y
  ncdf_attget, cal_id, gain_id, 'TCAM radius', ftcam_r

  gain *= norm
  ncdf_close, cal_id

  gain_centering = [[frcam_x, frcam_y, frcam_r], [ftcam_x, ftcam_y, ftcam_r]]

  gain_norm_stddev = fltarr(2)
  gain_stddev = fltarr(2)

  r_out = 504.0   ; from the epochs file, never changes
  overmask = 4.0

  for c = 0, 1 do begin
    mask = kcor_geometry_mask(gain_centering[0, c], $
                              gain_centering[1, c], $
                              gain_centering[2, c] + overmask, $
                              r_out)
    annulus_indices = where(mask gt 0L, /null)

    camera_gain = reform(gain[*, *, c])
    gain_stddev[c] = stddev(camera_gain[annulus_indices])
    gain_norm_stddev[c] = gain_stddev[c] / median(camera_gain[annulus_indices])
  endfor

  return, gain_norm_stddev
end


; main-level example program

cal_dir = '/hao/dawn/Data/KCor/calib_files'

cal_filenames = file_search(filepath('*.ncdf', root=cal_dir), count=n_cal_files)

output_filename = 'calfiles_quality.csv'

if (~file_test(output_filename, /regular)) then begin
  openw, lun, output_filename, /get_lun
  for c = 0L, n_cal_files - 1L do begin
    printf, lun, file_basename(cal_filenames[c]), $
            kcor_extract_gain_metric(cal_filenames[c]), $
            format='%s, %f, %f'
  endfor
  free_lun, lun
endif

data = read_csv(output_filename)
filenames = data.field1
rcam_metric = data.field2
tcam_metric = data.field3

years = long(strmid(filenames, 0, 4))
months = long(strmid(filenames, 4, 2))
days = long(strmid(filenames, 6, 2))
jds = julday(months, days, years, 0.0D, 0.0D, 0.0D)

month_ticks = mg_tick_locator([jds[0], jds[-1]], $
                              max_ticks=12, ticks=xticks, minor=xminor, $
                              /months)

!null = label_date(date_format='%Y-%N')
plot, jds, rcam_metric, /nodata, $
      xstyle=1, xtickformat='label_date', xtitle='Date', $
      xtickv=month_ticks, xticks=n_elements(month_ticks) - 1L, xminor=n_minor, $
      ystyle=1, yrange=[0.0, 0.1], ytitle='Metric', $
      title='Gain quality metric (std/median) [Green=RCAM, Magenta=TCAM]'
oplot, jds, rcam_metric, psym=4, symsize=0.5, color='00ff00'x
oplot, jds, tcam_metric, psym=4, symsize=0.5, color='ff00ff'x

end
