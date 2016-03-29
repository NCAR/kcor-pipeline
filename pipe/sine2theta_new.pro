

pro sine2theta_new, degrees, a, radavg, pder

; fit function of the form; a0*sin(2*theta + a1) = a0 * (sin(2*theta)cos(a1) + cos(2*theta)sin(a1))

y = 2.*degrees + a(1)

radavg = a(0)*sin(y) 

num=n_elements(degrees)
pder = fltarr(num,2)

IF N_PARAMS() GE 3 THEN BEGIN
  pder(*,0) = sin(y)
  pder(*,1) = (-sin(2*degrees)*sin(a(1)) +  cos(2*degrees)*cos(a(1))) *a(0)
ENDIF


end

