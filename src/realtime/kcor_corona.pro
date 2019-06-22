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

  return, sqrt((im[*, *, 0] - im[*, *, 3])^2 + (im[*, *, 1] - im[*, *, 2])^2)
end
