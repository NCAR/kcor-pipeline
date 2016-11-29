;  author: burkepile

pro sine2theta,degrees,a,radavg,pder

y = 2.*degrees/57.2957795 + a(1)
radavg = a(0)*sin(y) + a(2)
;radavg = a(0)*sin(y) + a(2)*degrees/57.2957795

pder = fltarr(360,3)

IF N_PARAMS() GE 4 THEN BEGIN
  pder(*,0)= sin(y)
  pder(*,1)= a(0)*cos(y)
  pder(*,2) = 1. 

;  pder(*,2) = degrees/57.2957795
ENDIF


end

