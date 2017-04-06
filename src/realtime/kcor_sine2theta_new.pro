; docformat = 'rst'

;+
; Fit function of the form:
;
; $$a_0 sin(2 \theta + a_1)$$
;
; :Params:
;   degrees : in, required, type=fltarr
;     value to evaluate fit function at
;   a : in, required, type=fltarr
;     coefficients in fit function
;   radavg : out, optional, type=fltarr(5)
;     evaluation of fit function at `degrees` with the coefficients provided by
;     `a`
;   pder : out, optional, type=fltarr(5)
;     set to a named variable to retrieve partial derivatives with respect to
;     `a[0]`, `a[1]`, ...
;-
pro kcor_sine2theta_new, degrees, a, radavg, pder
  compile_opt strictarr

  ; fit function of the form: 
  ;   a0*sin(2*theta + a1) = a0 * (sin(2*theta)cos(a1) + cos(2*theta)sin(a1))

  y = 2.0 * degrees + a[1]

  radavg = a[0] * sin(y)

  num  = n_elements(degrees)
  pder = fltarr(num, 2)

  if n_params() ge 3 then begin
    pder[*, 0] = sin(y)
    pder[*, 1] = (- sin(2.0 * degrees) * sin(a[1]) +  cos(2.0 * degrees) * cos(a[1])) * a[0]
  endif
end
