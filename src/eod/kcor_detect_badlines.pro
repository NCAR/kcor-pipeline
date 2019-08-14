; docformat = 'rst'

;+
; Find bad lines raw images.
;
; :Keywords:
;   run : in, required, type=object
;     KCor run object
;-
pro kcor_detect_badlines, run=run
  compile_opt strictarr

  logger_name = string(run.mode, format='(%"kcor/%s")')

  mg_log, 'starting', name=logger_name, /info

  basename = '*_kcor.fts.gz'
  raw_basedir = run->config('processing/raw_basedir')

  pattern = filepath(basename, subdir=[run.date, 'level0'], root=raw_basedir)
  filenames = file_search(pattern, count=n_filenames)

  cam0_badlines = mg_defaulthash(default=0L)
  cam1_badlines = mg_defaulthash(default=0L)
  n_checked_images = 0L

  for f = 0L, n_filenames - 1L do begin
    im = float(readfits(filenames[f], /silent))

    corona0 = kcor_corona(im[*, *, *, 0])
    corona1 = kcor_corona(im[*, *, *, 1])

    if (median(im) gt 10000.0) then continue
    if (median(corona0) gt 200.0 || median(corona1) gt 200.0) then continue

    n_checked_images += 1L

    cam0 = kcor_find_badlines_camera(corona0)
    cam1 = kcor_find_badlines_camera(corona1)

    for i = 0L, n_elements(cam0) - 1L do cam0_badlines[cam0[i]] += 1
    for i = 0L, n_elements(cam1) - 1L do cam1_badlines[cam1[i]] += 1
  endfor

  mg_log, 'checked %d out of %d L0 files', n_checked_images, n_filenames, $
          name=logger_name, /info

  if (cam0_badlines->count() gt 0L) then begin
    mg_log, 'cam0 bad lines:', name=logger_name, /warn
  endif
  foreach count, cam0_badlines, line do begin
    mg_log, '%d: %d times (%0.1f%%)', $
            line, count, 100.0 * count / n_checked_images, $
            name=logger_name, /warn
  endforeach

  if (cam1_badlines->count() gt 0L) then begin
    mg_log, 'cam1 bad lines:', name=logger_name, /warn
  endif
  foreach count, cam1_badlines, line do begin
    mg_log, '%d: %d times (%0.1f%%)', $
            line, count, 100.0 * count / n_checked_images, $
            name=logger_name, /warn
  endforeach

  obj_destroy, [cam0_badlines, cam1_badlines]
  mg_log, 'done', name=logger_name, /info
end


; main-level example program

date = '20190508'

run = kcor_run(date, $
               config_filename=filepath('kcor.latest.cfg', $
                                        subdir=['..', '..', 'config'], $
                                        root=mg_src_root()))
kcor_detect_badlines, run=run

obj_destroy, run

end
