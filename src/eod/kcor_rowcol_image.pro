; docformat = 'rst'

;+
; Create median row/col images of raw data.
;
; :Keywords:
;   run : in, required, type=object
;     KCor run object
;-
pro kcor_rowcol_image_l0, run=run
  compile_opt strictarr

  raw_basedir = run->config('processing/raw_basedir')
  files = file_search(filepath('*_kcor.fts.gz', $
                               subdir=[run.date, 'level0'], $
                               root=raw_basedir), $
                      count=n_files)
  if (n_files eq 0L) then begin
    mg_log, 'no L0 files', name='kcor/eod', /warn
    return
  endif

  nx = 1024
  ny = 1024

  medrows0 = fltarr(n_files, ny)
  medrows1 = fltarr(n_files, ny)

  medcols0 = fltarr(nx, n_files)
  medcols1 = fltarr(nx, n_files)

  for f = 0L, n_files - 1L do begin
    kcor_read_rawdata, files[f], image=im, header=header, $
                       repair_routine=run->epoch('repair_routine')
    exposure = sxpar(header, 'EXPTIME')

    corona0 = kcor_corona(reform(im[*, *, *, 0]))
    corona1 = kcor_corona(reform(im[*, *, *, 1]))

    medrows0[f, *] = median(corona0, dimension=1)
    medrows1[f, *] = median(corona1, dimension=1)

    medcols0[*, f] = median(corona0, dimension=2)
    medcols1[*, f] = median(corona1, dimension=2)
  endfor

  pdir = filepath('p', subdir=run.date, root=raw_basedir)

  medrows0_filename = filepath(string(run.date, $
                                      format='(%"%s.kcor.l0.medrows.cam0.gif")'), $
                               root=pdir)
  medrows1_filename = filepath(string(run.date, $
                                      format='(%"%s.kcor.l0.medrows.cam1.gif")'), $
                               root=pdir)

  medcols0_filename = filepath(string(run.date, $
                                      format='(%"%s.kcor.l0.medcols.cam0.gif")'), $
                               root=pdir)
  medcols1_filename = filepath(string(run.date, $
                                      format='(%"%s.kcor.l0.medcols.cam1.gif")'), $
                               root=pdir)

  min = 0.0
  max = run->epoch('corona_max') * exposure

  write_gif, medrows0_filename, bytscl(medrows0, min=min, max=max)
  write_gif, medrows1_filename, bytscl(medrows1, min=min, max=max)

  write_gif, medcols0_filename, bytscl(medcols0, min=min, max=max)
  write_gif, medcols1_filename, bytscl(medcols1, min=min, max=max)
end


;+
; Create median row/col images of L2 data.
;
; :Keywords:
;   run : in, required, type=object
;     KCor run object
;-
pro kcor_rowcol_image_l2, run=run
  compile_opt strictarr

  raw_basedir = run->config('processing/raw_basedir')
  files = file_search(filepath('*_kcor_l2.fts.gz', $
                               subdir=[run.date, 'level2'], $
                               root=raw_basedir), $
                      count=n_files)
  if (n_files eq 0L) then begin
    mg_log, 'no L2 files', name='kcor/eod', /warn
    return
  endif

  nx = 1024
  ny = 1024

  medrows = fltarr(n_files, ny)
  medcols = fltarr(nx, n_files)

  meanrows = fltarr(n_files, ny)
  meancols = fltarr(nx, n_files)

  for f = 0L, n_files - 1L do begin
    kcor_read_rawdata, files[f], image=im, $
                       repair_routine=run->epoch('repair_routine')

    medrows[f, *] = median(im, dimension=1)
    medcols[*, f] = median(im, dimension=2)

    meanrows[f, *] = mean(im, dimension=1)
    meancols[*, f] = mean(im, dimension=2)
  endfor

  pdir = filepath('p', subdir=run.date, root=raw_basedir)

  medrows_filename = filepath(string(run.date, $
                                     format='(%"%s.kcor.l2.medrows.gif")'), $
                              root=pdir)
  medcols_filename = filepath(string(run.date, $
                                     format='(%"%s.kcor.l2.medcols.gif")'), $
                              root=pdir)

  meanrows_filename = filepath(string(run.date, $
                                      format='(%"%s.kcor.l2.meanrows.gif")'), $
                               root=pdir)
  meancols_filename = filepath(string(run.date, $
                                      format='(%"%s.kcor.l2.meancols.gif")'), $
                               root=pdir)

  write_gif, medrows_filename, bytscl(medrows)
  write_gif, medcols_filename, bytscl(medcols)

  write_gif, meanrows_filename, bytscl(meanrows)
  write_gif, meancols_filename, bytscl(meancols)
end


;+
; Create median row/col images of L0 and L2 data.
;
; :Keywords:
;   run : in, required, type=object
;     KCor run object
;-
pro kcor_rowcol_image, run=run
  compile_opt strictarr

  if (run->config('eod/produce_rowcol_images')) then begin
    mg_log, 'starting...', name='kcor/eod', /info
  endif else begin
    mg_log, 'skipping row/col images', name='kcor/eod', /info
    goto, done
  endelse

  mg_log, 'creating L0 rowcol images...', name='kcor/eod', /info
  kcor_rowcol_image_l0, run=run

  mg_log, 'creating L2 rowcol images...', name='kcor/eod', /info
  kcor_rowcol_image_l2, run=run

  done:
  mg_log, 'done', name='kcor/eod', /info
end


; main-level example

date = '20131027'

run = kcor_run(date, $
               config_filename=filepath('kcor.reprocess.cfg', $
                                        subdir=['..', '..', 'config'], $
                                        root=mg_src_root()))
kcor_rowcol_image, run=run

obj_destroy, run

end
