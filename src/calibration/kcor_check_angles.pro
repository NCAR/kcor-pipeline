; docformat = 'rst'

;+
; Determine if all of the required angles are present in the given angles (mod
; 180 degrees) to a given tolerance.
;
; :Returns:
;   1B if required angles are present, 0B if not
;
; :Params:
;   required_angles : in, required, type=fltarr
;     the required angles
;   angles : in, required, type=fltarr
;     angles measured
;
; :Keywords:
;   tolerance : in, optional, type=float, default=0.1
;     allowable difference between required angle and measured angle
;-
function kcor_check_angles, required_angles, angles, tolerance=tolerance
  compile_opt strictarr

  _tolerance = n_elements(tolerance) eq 0L ? 0.1 : tolerance  ; degrees

  for a = 0L, n_elements(required_angles) - 1L do begin
    !null = where(abs((required_angles[a] - angles) mod 180.0) lt _tolerance, n_angles)
    if (n_angles eq 0L) then return, 0B
  endfor

  return, 1B
end
