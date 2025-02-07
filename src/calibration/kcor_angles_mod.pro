; docformat = 'rst'

;+
; Find positive distance between `angle` and `angles` mod 180.0, i.e., so the
; distance between 179.98 and 0.0 should be 0.02.
;
; :Returns:
;   `fltarr` of distances
;
; :Params:
;   angle : in, required, type=float
;     angle to test
;   angles : in, required, type=fltarr
;     array of angles to test against
;-
function kcor_angles_mod, angle, angles
  compile_opt strictarr

  ; instead of just mod, get a number between 0.0 and 180.0 and then choose
  ; closest, 0.0 or 180.0
  diff = abs(angle - angles) mod 180.0
  return, diff < abs(diff - 180)
end
