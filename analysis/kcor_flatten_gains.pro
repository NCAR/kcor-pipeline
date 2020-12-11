; docformat = 'rst'

;+
; Try to x-shift flats for a given day to make them flat.
;-
pro kcor_flatten_gains, date, $
                        cam0_xrange=cam0_xrange, $
                        cam1_xrange=cam1_xrange, $
                        run=run
  compile_opt strictarr
;  on_error, 2

  print, date, format='(%"analyzing flats for %s")'
  year = strmid(date, 0, 4)
  month = strmid(date, 4, 2)
  day = strmid(date, 6, 2)
  datetime = string(year, month, day, format='(%"%s-%s-%sT00:00:00")')

  run.time = datetime

  _cam0_xrange = n_elements(cam0_xrange) gt 0L ? cam0_xrange :  [0, 0]
  _cam1_xrange = n_elements(cam1_xrange) gt 0L ? cam1_xrange :  [0, 0]

  ; find flat files
  cal_catalog_filename = filepath('calibration_files.txt', $
                                  subdir=date, $
                                  root=run->config('processing/process_basedir'))
  if (~file_test(cal_catalog_filename, /regular)) then begin
    message, string(date, format='(%"no cal files for %s")')
  endif
  n_cal_files = file_lines(cal_catalog_filename)
  if (n_cal_files eq 0L) then message, string(date, format='(%"no cal files for %s")')

  cal_catalog_lines = strarr(n_cal_files)
  openr, lun, cal_catalog_filename, /get_lun
  readf, lun, cal_catalog_lines
  free_lun, lun

  cal_filenames = strarr(n_cal_files)
  is_flat = bytarr(n_cal_files)
  is_dark = bytarr(n_cal_files)

  for i = 0L, n_cal_files - 1L do begin
    line = cal_catalog_lines[i]
    tokens = strsplit(line, /extract, count=n_tokens)
    cal_filenames[i] = tokens[0]
    is_flat[i] = tokens[6] eq 'out' && tokens[8] eq 'in' && tokens[10] eq 'out'
    is_dark[i] = tokens[6] eq 'in'
  endfor

  dark_indices = where(is_dark, n_darks)
  print, n_darks, format='(%"found %d darks...")'

  flat_indices = where(is_flat, n_flats)
  print, n_flats, format='(%"found %d flats...")'

  cal_filenames = filepath(cal_filenames, $
                           subdir=[date], $
                           root=run->config('processing/raw_basedir'))
  if (~file_test(cal_filenames[0], /regular)) then begin
    cal_filenames = filepath(cal_filenames, $
                             subdir=[date, 'level0'], $
                             root=run->config('processing/raw_basedir'))
    if (~file_test(cal_filenames[0], /regular)) then begin
      message, 'cannot find cal files'
    endif
  endif


  gain_norm_stddev = fltarr(2)
  d = shift(dist(1024, 1024), 512, 512)
  annulus_indices = where(d lt 500 and d gt 200, n_annulus)

  device, decomposed=0
  loadct, 0

  original_xshift = run->epoch('xshift_camera')

  for cam0_xshift = _cam0_xrange[0], _cam0_xrange[1] do begin
    for cam1_xshift = _cam1_xrange[0], _cam1_xrange[1] do begin
      xshift = original_xshift + [cam0_xshift, cam1_xshift]
      print, xshift, format='(%"-- trying xshift: [%d, %d]")'

      dark = fltarr(1024, 1024, 2)
      flat = fltarr(1024, 1024, 2)

      for f = 0L, n_darks - 1L do begin
        kcor_read_rawdata, cal_filenames[dark_indices[f]], image=im, header=header, $
                           xshift=xshift
        kcor_correct_camera, im, header, run=run, logger_name='kcor/cal'

        dark += mean(im, dimension=3)
      endfor

      for f = 0L, n_flats - 1L do begin
        kcor_read_rawdata, cal_filenames[flat_indices[f]], image=im, header=header, $
                           xshift=xshift
        kcor_correct_camera, im, header, run=run, logger_name='kcor/cal'

        transmission = run->epoch(sxpar(header, 'DIFFSRID'))
        flat += mean(im, dimension=3)
      endfor

      dark /= n_darks
      flat /= n_flats
      gain = (flat - dark) / transmission

      for c = 0, 1 do begin
        camera_gain = reform(gain[*, *, c])
        gain_norm_stddev[c] = stddev(camera_gain[annulus_indices]) $
                                / median(camera_gain[annulus_indices])
      endfor
      print, gain_norm_stddev, format='(%"   cam 0: %0.4f, cam 1: %0.4f")'

      gain_range = [0.0, 2500.0]
      charsize = 1.15
      y = 512  ; height of gain profile

      window, xsize=800, ysize=800, $
              title=string(xshift, format='(%"xshift: [%d, %d]")'), $
              /free
      !p.multi = [0, 1, 2]
      for c = 0, 1 do begin
        plot, gain[*, y, c], $
              title=string(date, c, $
                           format='(%"Profile of dark corrected gain on %s for camera %d")'), $
              xstyle=1, $
              xtitle='Column [pixels]', $
              yrange=gain_range, ystyle=1, $
              ytitle='Gain value [B/Bsun]', $
              background=255, color=0, charsize=charsize, psym=3
        xyouts, 0.125, 0.5 - 0.5 * c + 0.10, /normal, $
                string(gain_norm_stddev[c], format='(%"std dev / median: %0.4f")'), $
                charsize=charsize, color=0
      endfor
      !p.multi = 0
    endfor
  endfor
end


; main-level example program

date = '20201009'
config_filename = filepath('kcor.latest.cfg', $
                           subdir=['..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)

mg_log, logger=logger, name='kcor/cal'
logger->setProperty, level=3

kcor_flatten_gains, date, $
                    cam1_xrange=[-8, 6], $
                    run=run

obj_destroy, run

end
