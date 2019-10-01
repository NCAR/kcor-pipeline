pro kcor_find_gain_outliers, filename, $
                             outliers0=outliers0, outliers1=outliers1, $
                             gain=gain, $
                             n=n
  compile_opt strictarr

  gain = mg_nc_getdata(filename, 'Gain')

  maskfile = filepath('kcor_mask.img', $
                      subdir=['..', 'src', 'realtime'], $
                      root=mg_src_root())
  nx   = 1024
  ny   = 1024
  mask = fltarr(nx, ny)
  openr, lun, maskfile, /get_lun
  readu, lun, mask
  free_lun, lun

  mask_indices = where(mask, n_mask_indices)

  cam0 = gain[*, *, 0]
  cam1 = gain[*, *, 1]

  median0 = median(cam0[mask_indices])
  median1 = median(cam1[mask_indices])
  print, median0, median1, format='(%"medians cam0: %0.2f, cam1: %0.2f")'
  mean0 = mean(cam0[mask_indices])
  mean1 = mean(cam1[mask_indices])

  stddev0 = stddev(cam0[mask_indices])
  stddev1 = stddev(cam1[mask_indices])
  print, stddev0, stddev1, format='(%"std dev cam0: %0.2f, cam1: %0.2f")'
  stddev0 = 500.0
  stddev1 = 500.0
  _n = n_elements(n) eq 0L ? 3.0 : n

  outliers0 = where(((cam0 gt (median0 + _n * stddev0)) $
                    or (cam0 lt (median0 - _n * stddev0))) and mask, n_outliers0, /null)

  outliers1 = where(((cam1 gt (median1 + _n * stddev1)) $
                    or (cam1 lt (median1 - _n * stddev1))) and mask, n_outliers1, /null)
end


; main-level example program

calib_dir = '/hao/sunset/Data/KCor/calib_files.gains'
basename = '20190727_185733_kcor_cal_v21_1.6.15*_2.500ms.ncdf'
;basename = '20160821_185127_kcor_cal_v10.1_1.6.15*_1.000ms.ncdf'
filename = filepath(basename, root=calib_dir)
n = 1.0
kcor_find_gain_outliers, filename, $
                         outliers0=outliers0, outliers1=outliers1, $
                         gain=gain, $
                         n=n

outliers0_mask = bytarr(1024, 1024)
outliers1_mask = bytarr(1024, 1024)
outliers0_mask[outliers0] = 1B
outliers1_mask[outliers1] = 1B
mg_image, bytscl(outliers0_mask), /new, $
          title=string(n_elements(outliers0), n, $
                       format='(%"Cam 0 outliers (%d outliers @ %0.1f std dev)")')
mg_image, bytscl(outliers1_mask), /new, $
          title=string(n_elements(outliers1), n, $
                       format='(%"Cam 1 outliers (%d outliers @ %0.1f std dev)")')


mg_image, bytscl(gain[*, *, 0], 0.0, 5000.0), /new, title='Cam 0 gain'
mg_image, bytscl(gain[*, *, 1], 0.0, 5000.0), /new, title='Cam 1 gain'

end
