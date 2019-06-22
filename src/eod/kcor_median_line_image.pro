; docformat = 'rst'

pro kcor_median_line_image_l0, date, raw_basedir
  compile_opt strictarr


  files = file_search(filepath('*_kcor.fts.gz', $
                               subdir=[date, 'level0'], $
                               root=raw_basedir), $
                      count=n_files)

  nx = 1024
  ny = 1024

  medrows0 = fltarr(n_files, ny)
  medrows1 = fltarr(n_files, ny)

  medcols0 = fltarr(nx, n_files)
  medcols1 = fltarr(nx, n_files)

  for f = 0L, n_files - 1L do begin
    im = readfits(files[f], /silent)

    corona0 = kcor_corona(reform(im[*, *, *, 0]))
    corona1 = kcor_corona(reform(im[*, *, *, 1]))

    medrows0[f, *] = median(corona0, dimension=1)
    medrows1[f, *] = median(corona1, dimension=1)

    medcols0[*, f] = median(corona0, dimension=2)
    medcols1[*, f] = median(corona1, dimension=2)
  endfor

  medrows0_filename = string(date, format='(%"%s.kcor.l0.medrows.cam0.gif")')
  medrows1_filename = string(date, format='(%"%s.kcor.l0.medrows.cam1.gif")')

  medcols0_filename = string(date, format='(%"%s.kcor.l0.medcols.cam0.gif")')
  medcols1_filename = string(date, format='(%"%s.kcor.l0.medcols.cam1.gif")')

  min = 0.0
  max = 200.0

  write_gif, medrows0_filename, bytscl(medrows0, min=min, max=max)
  write_gif, medrows1_filename, bytscl(medrows1, min=min, max=max)

  write_gif, medcols0_filename, bytscl(medcols0, min=min, max=max)
  write_gif, medcols1_filename, bytscl(medcols1, min=min, max=max)
end


pro kcor_median_line_image_l1, date, raw_basedir
  compile_opt strictarr

  files = file_search(filepath('*_kcor_l1.5.fts.gz', $
                               subdir=[date, 'level1'], $
                               root=raw_basedir), $
                      count=n_files)

  nx = 1024
  ny = 1024

  medrows = fltarr(n_files, ny)
  medcols = fltarr(nx, n_files)

  for f = 0L, n_files - 1L do begin
    im = readfits(files[f], /silent)

    medrows[f, *] = median(im, dimension=1)
    medcols[*, f] = median(im, dimension=2)
  endfor

  medrows_filename = string(date, format='(%"%s.kcor.l1.medrows.gif")')
  medcols_filename = string(date, format='(%"%s.kcor.l1.medcols.gif")')

  min = 0.0
  max = 1.0e-8

  write_gif, medrows_filename, bytscl(medrows, min=min, max=max)
  write_gif, medcols_filename, bytscl(medcols, min=min, max=max)
end


pro kcor_median_line_image, date, raw_basedir
  compile_opt strictarr

;  kcor_median_line_image_l0, date, raw_basedir
  kcor_median_line_image_l1, date, raw_basedir
end


; main-level example

raw_basename = '/hao/mlsodata1/Data/KCor/raw'
date = '20190403'

kcor_median_line_image, date, raw_basename

end
