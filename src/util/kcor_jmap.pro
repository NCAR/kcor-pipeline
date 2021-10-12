; docformat = 'rst'

;+
; Read KCor level 2 data files to retrieve data for a J-map.
;
; :Returns:
;   `fltarr(n_l2_files, n_heights)``
;
; :Params:
;   angle : in, required, type=float
;     position angle to calculate J-map at, 0.0 for up, 90.0 for left, 180.0
;     for down, and 270.0 for right
;
; :Keywords:
;   width : in, optional, type=float, default=5.0
;     width of the sector around `angle` to use
;   times : out, optional, type=fltarr(n_l2_files)
;     set to a named variable to retrieve the date/times for the given level 2
;     files
;-
function kcor_jmap, angle, l2_files, width=width, times=times, verbose=verbose
  compile_opt strictarr

  n_l2_files = n_elements(l2_files)
  _width = n_elements(width) eq 0L ? 5.0 : width
  n_heights = 100

  if (arg_present(times)) then begin
    times = strmid(file_basename(l2_files), 0, 15)
  endif

  xsize = 1024
  ysize = 1024
  x = rebin(reform(findgen(xsize) - (xsize - 1) / 2.0, xsize, 1), xsize, ysize)
  y = rebin(reform(findgen(ysize) - (ysize - 1) / 2.0, 1, ysize), xsize, ysize)
  all_angles = rot(atan(y, x) * !radeg, - angle - 90.0)

  wedge_indices = where(abs(all_angles) lt _width / 2.0, n_wedge)

  r = shift(dist(xsize, ysize), (xsize - 1) / 2.0, (ysize - 1) / 2.0)

  jmap = fltarr(n_l2_files, n_heights)
  for f = 0L, n_l2_files - 1L do begin
    if (keyword_set(verbose)) then print, file_basename(l2_files[f]), format='(%"Reading %s...")'
    im = readfits(l2_files[f], header, /silent)
    r_sun = sxpar(header, 'R_SUN')
    h = histogram(r[wedge_indices], min=r_sun, nbins=n_heights, reverse_indices=ri)
    for h = 0L, n_heights - 1L do begin
      if (ri[h] ne ri[h + 1]) then begin
        jmap[f, h] = mean(im[wedge_indices[ri[ri[h] : ri[h+1]-1]]])
      endif
    endfor
  endfor

  return, jmap
end


; main-level example program

angle = 15.0
date = '20211003'
root = '/hao/dawn/Data/KCor/raw'
l2_files = file_search(filepath('*_l2_nrgf.fts.gz', subdir=[date, 'level2'], root=root), count=n_l2_files)
jmap = kcor_jmap(angle, l2_files, /verbose, times=times)
mg_image, bytscl(jmap), /new, title=string(angle, date, format='(%"J-map at %0.1f deg for %s")')

end

