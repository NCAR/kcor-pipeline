; docformat = 'rst'

;+
; Find indices of anomalous lines.
;
; :Returns:
;   `lonarr` of indices, `!null` if none
;
; :Params:
;   im : in, required, type="fltarr(nx, ny, 4)"
;     image for one camera to check
;-
function kcor_detect_badlines_find, im
  compile_opt strictarr

  meds = median(im, dimension=1)

  n = 5
  kernel = fltarr(n) - 1.0 / (n - 1)
  kernel[n / 2] = 1.0

  ; number of lines to skip at the top and bottom of the image
  n_skip = 3

  diffs = convol(meds[n_skip:-n_skip-1], kernel, /edge_truncate)
  bad_lines = where(diffs gt 25.0, n_bad_lines, /null)
  if (n_bad_lines gt 0L) then bad_lines += n_skip

  return, bad_lines
end


;+
; Find bad lines raw images.
;
; :Keywords:
;   run : in, required, type=object
;     KCor run object
;-
pro kcor_detect_badlines, run=run
  compile_opt strictarr

  mg_log, 'starting', name='kcor/eod', /info

  basename = '*_kcor.fts.gz'
  raw_basedir = run->config('processing/raw_basedir')

  pattern = filepath(basename, subdir=[run.date, 'level0'], root=raw_basename)
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

    cam0 = kcor_detect_badlines_find(corona0)
    cam1 = kcor_detect_badlines_find(corona1)

    for i = 0L, n_elements(cam0) - 1L do cam0_badlines[cam0[i]] += 1
    for i = 0L, n_elements(cam1) - 1L do cam1_badlines[cam1[i]] += 1
  endfor

  if (cmd0_badlines->count() gt 0L) then begin
    mg_log, 'cam0 bad lines:', name='kcor/eod', /warn
  endif
  foreach count, cam0_badlines, line do begin
    mg_log, '%d: %d times', line, count, name='kcor/eod', /warn
  endforeach

  if (cmd1_badlines->count() gt 0L) then begin
    mg_log, 'cam1 bad lines:', name='kcor/eod', /warn
  endif
  foreach count, cam1_badlines, line do begin
    mg_log, '%d: %d times (%0.1f%%)', $
            line, count, 100.0 * count / n_checked_images, $
            name='kcor/eod', /warn
  endforeach

  obj_destroy, [cmd0_badlines, cmd1_badlines]
  mg_log, 'done', name='kcor/eod', /info
end


; main-level example program

raw_basename = '/hao/mlsodata1/Data/KCor/raw'

dates = file_search(filepath('2019????', root=raw_basename), count=n_dates)
months = ['03', '04', '05', '06']

openw, lun, 'bad_lines.txt', /get_lun

for d = 0L, n_dates - 1L do begin
  ;n_wrong_cam0_lines = 0L
  ;n_wrong_cam1_lines = 0L

  date = file_basename(dates[d])

  month = strmid(date, 4, 2)
  if (n_elements(where(month eq months, /null)) eq 0L) then continue

  basename = '*_kcor.fts.gz'

  pattern = filepath(basename, subdir=[date, 'level0'], root=raw_basename)
  filenames = file_search(pattern, count=n_filenames)

  printf, lun, date, n_filenames, format='(%"%s (%d files)")'
  print, date, n_filenames, format='(%"### %s (%d files)")'

  cam0_badlines = mg_defaulthash(default=0L)
  cam1_badlines = mg_defaulthash(default=0L)

  for f = 0L, n_filenames - 1L do begin
    print, f + 1, n_filenames, file_basename(filenames[f]), $
           format='(%"%d/%d: %s")'
    ;printf, lun, file_basename(filenames[f]), format='(%"%s:")'
    im = float(readfits(filenames[f], /silent))
    ;printf, lun, median(im), format='(%"  median: %0.1f")'

    kcor_detect_badlines, im, cam0=cam0, cam1=cam1, error=error, lun=lun

    for i = 0L, n_elements(cam0) - 1L do begin
      cam0_badlines[cam0[i]] += 1
    endfor

    for i = 0L, n_elements(cam1) - 1L do begin
      cam1_badlines[cam1[i]] += 1
    endfor

    if (0) then begin
      if (n_elements(cam0) gt 0L) then begin
        printf, lun, strjoin(strtrim(cam0, 2), ', '), format='(%"  cam0 bad lines: %s")'
      endif
      if (n_elements(cam1) gt 0L) then begin
        printf, lun, strjoin(strtrim(cam1, 2), ', '), format='(%"  cam1 bad lines: %s")'
      endif
    endif

    ;if (error eq 0 && n_elements(cam0) ne 0) then begin
    ;  printf, lun, strjoin(strtrim(cam0, 2), ', '), $
    ;          format='(%"  wrong cam0 bad lines: %s")'
    ;  n_wrong_cam0_lines += 1
    ;endif
    ;if (error eq 0 && (n_elements(cam1) ne 1 || cam1[0] ne 752)) then begin
    ;  printf, lun, n_elements(cam1) eq 0L ? 'none' : strjoin(strtrim(cam1, 2), ', '), $
    ;          format='(%"  wrong cam1 bad lines: %s")'
    ;  n_wrong_cam1_lines += 1
    ;endif
  endfor

  ;printf, lun, n_wrong_cam0_lines, format='(%"wrong cam0 bad lines: %d")'
  ;printf, lun, n_wrong_cam1_lines, format='(%"wrong cam1 bad lines: %d")'

  printf, lun, '  cam0 bad lines:'
  foreach count, cam0_badlines, line do begin
    printf, lun, line, count, format='(%"    %d: %d times")'
  endforeach

  printf, lun, '  cam1 bad lines:'
  foreach count, cam1_badlines, line do begin
    printf, lun, line, count, format='(%"    %d: %d times")'
  endforeach

  flush, lun
endfor

free_lun, lun

end
