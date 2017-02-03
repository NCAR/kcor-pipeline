; docformat = 'rst'

;+
; Function to use coefficients from surf_fit and create polynomial surface.
;
; :Returns:
;   fltarr the same size as `coord_x`
;-
function kcor_eval_surf, coef, coord_x, coord_y
  compile_opt strictarr

  fit = coord_x * 0.0

  s = size(coef)
  degree = s[1] - 1   ; determine degree of fit

  ; compute fit surface from coefficients

  fit += coef[0, 0]   ; constant term
  for ix = 1, degree do fit += coef[ix, 0] * coord_x^ix
  for iy = 1, degree do fit += coef[0, iy] * coord_y^iy
  ; changed index order (gdt)
  for iy = 1, degree do begin
    for ix = 1, degree do begin
      fit += coef[ix, iy] * coord_x^ix * coord_y^iy
    endfor
  endfor

  return, fit
end
