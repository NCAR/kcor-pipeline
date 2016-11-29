pro roll_funct, xx, m, out, pder
;
;
if n_params() gt 2 then begin
    pder = fltarr(n_elements(xx), n_elements(m))
    pder(*,0) = sin((xx+M(1))/365.25*!pi*2)
    pder(*,1) = m(0)*cos((xx+m(1))/365.25*!pi*2) * ( 1. / 365.25*2*!pi*2 )
    pder(*,2) = sin((xx+m(3))/365.25*m(5)*!pi*2)
    pder(*,3) = m(2)*cos((xx+m(3))/365.25*m(5)*!pi*2) * ( 1. / 365.25*m(5)*!pi*2 )
    pder(*,4) = 1
    pder(*,5) = cos((xx+m(3))/365.25*m(5)*!pi*2) * ( -1. / 365.25*m(5)^2*!pi*2 )
endif

;0.3*sin((xx+80)/365.25*!pi*2) + 0.3*sin((xx+80)/365.25*2*!pi*2) - 0.08
out = m(0)*sin((xx+M(1))/365.25*!pi*2) + m(2)*sin((xx+m(3))/365.25*m(5)*!pi*2) + m(4)
end

