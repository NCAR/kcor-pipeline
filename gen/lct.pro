; docformat = 'rst'

;+
; Load colormap from disk file.
;
; Color table is stored as ASCII numbers [0-255]; each line: index, R, G, B.
;
; :Examples:
;   For example, try::
;
;     lct, 'grey.lut'
;
; :Params:
;   lutname : in, required, type=string
;     filename of lookup table file with the color table stored as ASCII values
;     [0-255] where each line is: index, R, G, B.
;
; :Author:
;   Andrew L. Stanger	HAO/NCAR
;
; :History:
;   19 Apr 1995 IDL procedure created.
;   15 Jun 2015 Use get_lun.
;-
pro lct, lutname
  compile_opt strictarr
  common colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr

  ; declare storage variables

  index  = bytarr(256)
  r_orig = bytarr(256)
  g_orig = bytarr(256)
  b_orig = bytarr(256)

  c = 0B
  r = 0B
  g = 0B
  b = 0B

  ; read colormap from ASCII file with the format:
  ;   (4I4), index, red, green, blue
  openr, lun, lutname, /get_lun

  for i = 0, 255 do begin
    readf, lun, c, r, g, b
    index[i]  = c
    r_orig[i] = r
    g_orig[i] = g
    b_orig[i] = b
  endfor

  free_lun, lun

  tvlct, r_orig, g_orig, b_orig

  r_curr = r_orig
  g_curr = g_orig
  b_curr = b_orig
end
