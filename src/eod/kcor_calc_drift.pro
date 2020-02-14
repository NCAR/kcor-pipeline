; docformat = 'rst'

;+
; Calculate the drift in RA and DEC.
;
; :Params:
;   times : in, required, type=fltarr
;     time in decimal hours
;   ra_offset : in, required, type=fltarr
;     RA offset
;   dec_offset : in, required, type=fltarr
;     DEC offset
;
; :Keywords:
;   ra_drift : out, optional, type=fltarr
;     RA correction
;   dec_drift : out, optional, type=fltarr
;     DEC correction
;-
pro kcor_calc_drift, times, ra_offset, dec_offset, $
                     ra_drift=ra_drift, dec_drift=dec_drift
  compile_opt strictarr

  n_files = n_elements(times)

  bi = kcor_find_basefiles(ra_offset, dec_offset, count=n_basefiles)

  ra_drift  = fltarr(n_files)
  dec_drift = fltarr(n_files)

  ; calculate drift before first base file
  if (bi[0] gt 0L) then begin
    ra_drift[0:bi[0]]  = ra_offset[0:bi[0]]  - ra_offset[bi[0]]
    dec_drift[0:bi[0]] = dec_offset[0:bi[0]] - dec_offset[bi[0]]
  endif

  ; calculate drifts between base files
  for b = 0L, n_basefiles - 2L do begin
    ; calculate slope between the two base files
    ra_m = (ra_offset[bi[b]] - ra_offset[bi[b + 1]]) / (times[bi[b]] - times[bi[b + 1]])
    dec_m = (dec_offset[bi[b]] - dec_offset[bi[b + 1]]) / (times[bi[b]] - times[bi[b + 1]])

    ; drift is difference between linearly interpolated value and actual value
    ra_drift[bi[b]:bi[b + 1]] $
        = ra_m * (times[bi[b]:bi[b+1]] - times[bi[b]]) $
            + ra_offset[bi[b]] - ra_offset[bi[b]:bi[b + 1]]
    dec_drift[bi[b]:bi[b + 1]] $
        = dec_m * (times[bi[b]:bi[b+1]] - times[bi[b]]) $
            + dec_offset[bi[b]] - dec_offset[bi[b]:bi[b + 1]]
  endfor

  ; TODO: calculate drift after last base file (use a model?)
end


; main-level example program

;ra_offsets  = [ 15.0,  15.0,  20.0,  25.0,  25.0,  25.0,  25.0,  25.0, $
;                15.0,  15.0,  20.0,  30.0,  30.0,  30.0,  30.0,  30.0, $
;                15.0,  15.0,  20.0,  25.0,  25.0]
;dec_offsets = [-15.0, -20.0, -20.0, -20.0, -20.0, -20.0, -20.0, -20.0, $ 
;               -15.0, -20.0, -20.0, -25.0, -25.0, -25.0, -25.0, -25.0, $
;               -15.0, -20.0, -20.0, -20.0, -20.0]
;times = findgen(n_elements(ra_offsets))

filename = 'save_sgs_info.txt'
n = file_lines(filename)
lines = strarr(n)
openr, lun, filename, /get_lun
readf, lun, lines
free_lun, lun

str_times = strarr(n)
ra_offsets = fltarr(n)
dec_offsets = fltarr(n)

for r = 0L, n - 1L do begin
  tokens = strsplit(lines[r], /extract)
  str_times[r] = tokens[0]
  ra_offsets[r] = float(tokens[1])
  dec_offsets[r] = float(tokens[2])
endfor

times = fltarr(n)
for r = 0L, n - 1L do begin
  hour = float(strmid(str_times[r], 11, 2))
  min  = float(strmid(str_times[r], 14, 2))
  sec  = float(strmid(str_times[r], 17, 2))
  times[r] = hour + (min + sec / 60.0) / 60.0
endfor

kcor_calc_drift, times, ra_offsets, dec_offsets, $
                 ra_drift=ra_drift, dec_drift=dec_drift

end
