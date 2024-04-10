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
function kcor_check_angles_mod, angle, angles
  compile_opt strictarr

  ; instead of just mod, get a number between 0.0 and 180.0 and then choose
  ; closest, 0.0 or 180.0
  diff = abs(angle - angles) mod 180.0
  return, diff < abs(diff - 180)
end


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
;   optional_angles : in, required, type=fltarr
;     the optional angles
;   angles : in, required, type=fltarr
;     angles measured
;
; :Keywords:
;   tolerance : in, optional, type=float, default=0.1
;     allowable difference between required angle and measured angle
;-
function kcor_check_angles, required_angles, optional_angles, angles, $
                            tolerance=tolerance, $
                            logger_name=logger_name
  compile_opt strictarr

  _tolerance = n_elements(tolerance) eq 0L ? 0.1 : tolerance  ; degrees

  for a = 0L, n_elements(required_angles) - 1L do begin
    !null = where(kcor_check_angles_mod(required_angles[a], angles) lt _tolerance, n_angles)
    if (n_angles eq 0L) then begin
      mg_log, 'missing required angle: %0.2f', required_angles[a], $
              name=logger_name, /debug
      return, 0B
    endif
  endfor

  for a = 0L, n_elements(angles) - 1L do begin
    !null = where(kcor_check_angles_mod(angles[a], optional_angles) lt _tolerance, n_optional_angles)
    !null = where(kcor_check_angles_mod(angles[a], required_angles) lt _tolerance, n_required_angles)
    if (n_optional_angles eq 0L && n_required_angles eq 0L) then begin
      mg_log, 'cal angle %0.2f not required or optional', angles[a], $
              name=logger_name, /debug
      return, 0B
    endif
  endfor

  return, 1B
end


; main-level example program
required_angles = [0.0, 45.0, 90.0, 135.0]
angles = [-0.02, 0.0, 0.02, 22.48, 22.5, 22.52, 44.98, 45.0, 45.02, $
          89.98, 90.0, 90.02, 134.98, 135.0, 135.02, 179.98, 180.0, 180.01]
print, kcor_check_angles(required_angles, $
                         required_angles + 22.5, $
                         angles)

angles = [0.0, 22.5, 45.0, 90.0, 135.0, 22.4]
print, kcor_check_angles(required_angles, $
                         required_angles + 22.5, $
                         angles)

end
