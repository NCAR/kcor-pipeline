; docformat = 'rst'

;+
; Analyze realtime processing time/image from::
;
;   grep time/image *.realtime.log > filename
;
; :Params:
;   filename : in, required, type=string
;     filename containing output from grep
;-
pro kcor_times, filename
  compile_opt strictarr

  n_lines = file_lines(filename)
  times = fltarr(n_lines)
  jds = dblarr(n_lines)

  line = ''
  openr, lun, filename, /get_lun
  for i = 0L, n_lines - 1L do begin
    readf, lun, line
    tokens = strsplit(line, /extract)
    times[i] = float(tokens[5])
    t = tokens[1]
    d = (strsplit(tokens[0], ':', /extract))[1]
    hour  = long(strmid(t, 0, 2))
    min   = long(strmid(t, 3, 2))
    sec   = long(strmid(t, 6, 2))
    year  = long(strmid(d, 0, 4))
    month = long(strmid(d, 5, 2))
    day   = long(strmid(d, 8, 2))
    if (year gt 2020) then jds[i] = !values.f_nan else begin
      jds[i] = julday(month, day, year, hour, min, sec)
    endelse
    ; print, year, month, day, hour, min, sec, $
    ;        format='(%"%04d-%02d-%02dT%02d-%02d-%02d")'
  endfor
  free_lun, lun

  zero_indices = where(times eq 0.0, n_zeros)
  if (n_zeros gt 0L) then times[zero_indices] = !values.f_nan

  window, /free, xsize=1200, ysize=400, $
          title=string(file_basename(filename), format='(%"%s")')

  !null = label_date(date_format='%d %M %Y')
  plot, jds, times, psym=3, charsize=1.25, $
        color='000000'x, background='ffffff'x, $
        title='Time/file in realtime processing', $
        xtickformat='label_date', xstyle=9, xtitle='Date of processing', $
        ystyle=1, ytitle='Time/file (seconds)', yrange=[0.0, 40.0]
  oplot, jds, fltarr(n_lines) + 15.0, color='0000ff'x
end


; main-level example

kcor_times, '2021-kcor-times.txt'

end
