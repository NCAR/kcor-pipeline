; docformat = 'rst'

;+
; Fit function of the form:
;
; $$a_0 \sin\left(2x - 2 \arcsin\left(\frac{a_1 \sin\left(a_3 - x\right)}{\sqrt{a_1^2 + a_2^3 - 2a_1 a_2 \cos\left(a_3 - x\right)}}\right) - a_4\right)$$
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
pro sine2theta_new, degrees, a, radavg, pder
  compile_opt strictarr

  ; some temporary variables
  c = a[1] * a[1] + a[2] * a[2] - 2.0 * a[1] * a[2] * cos(a[3] - x)
  t = a[1] * sin(a[3] - x)
  d = 2.0 * x - 2.0 * asin(t / sqrt(c)) - a[4]
  sin2theta = sin(d)

  radavg = a[0] * sin2theta

  if (n_params() ge 3) then begin
    pder = fltarr(n_elements(degrees), n_elements(a))

    ; more temporary variables for partial derivatives
    cos2theta = cos(d)
    s = - 2.0 * a[0] * cos2theta / sqrt(1 - t * t / c)
    sin3 = sin(a[3] - x)
    cos3 = cos(a[3] - x)

    pder[*, 0] = sin2theta
    pder[*, 1] = s * (sin3 * sqrt(c) - 2.0 * a[1] * sin3 * (a[1] - a[2] * cos3)/ sqrt(c)) / c
    pder[*, 2] = 2.0 * s * (a[1] * sin3 / sqrt(c) / 2.0) * (a[2] - a[1] * cos3)
    pder[*, 3] = s * (a[1] * cos3 * sqrt(c) - a[1] * sin3 / sqrt(c)) / c
    pder[*, 4] = - a[0] * cos2theta
  endif
end

