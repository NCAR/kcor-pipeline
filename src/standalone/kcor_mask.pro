; docformat = 'rst'

;+
; Create FOV mask for MLSO/COSMO K-coronagraph.
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;
; :Author:
;   Andrew Stanger
;
; :History:
;   29 October 2014
;-
pro kcor_mask, run=run
  compile_opt strictarr

  ; mask file name
  maskfile = filepath('kcor_mask.img', root=mg_src_root())

  ; image dimensions
  xdim = 1024
  ydim = 1024

  ; image center
  xcen = xdim * 0.5 - 0.5
  ycen = ydim * 0.5 - 0.5

  ; FOV limits
  occulter_size = 991.6   ; use smallest occulter.
  rmin = occulter_size / run->epoch('plate_scale') + 5.0
  rmax = 504.0

  mask = fltarr(xdim, ydim) + 1.0

  for ix = 0, xdim - 1 do begin
    xdist = ix - xcen
    for iy = 0, ydim -1 do begin
      ydist = iy - ycen
      r = sqrt(xdist * xdist + ydist * ydist)
      if (r lt rmin or r gt rmax) then mask[ix, iy] = 0.0
    endfor
  endfor

  openw, umask, maskfile, /get_lun
  writeu, umask, mask
  free_lun, umask
end
