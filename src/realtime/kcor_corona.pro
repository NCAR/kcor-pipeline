; docformat = 'rst'

;+
; Calculate the corona.
;
; :Returns:
;   fltarr(nx, ny)
;
; :Params:
;   im : in, required, type="fltarr(nx, ny, 4)"
;     image data for one camera
;-
function kcor_corona, im
  compile_opt strictarr

  _im = float(im)
  return, sqrt((_im[*, *, 0] - _im[*, *, 3])^2 + (_im[*, *, 1] - _im[*, *, 2])^2)
end
