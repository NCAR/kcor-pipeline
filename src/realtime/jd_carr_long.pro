PRO jd_carr_long, JD_in, carr_test, Lo

;--------------------------------------------------- 
; Given julian date, return carrington rotation and 
; longitude
;--------------------------------------------------- 
JD = double(JD_in) - 2440000.0D0


;print,'jd_carr : jd = ',jd


JD_CR0 = -41859.899931D0
num_rot = (JD-JD_CR0)/27.2753D0

if (num_rot ge 1000.0D0) then carr_increm = 1000.0D0 else $
if (num_rot ge 100.0D0) then carr_increm = 100.0D0 else $
if (num_rot ge 10.0D0) then carr_increm = 10.0D0 else $
if (num_rot ge 1.0D0) then carr_increm = 1.0D0 else $
CARR_CM = 0.0D0

carr_test = carr_increm
JD_test = carr_jd_fn(double(carr_test),0.0D0)

while (JD_test le JD) do begin

 num_rot = (double(JD)-double(JD_test))/double(27.2753) 

 if (num_rot ge 1000.0D0) then carr_increm = 1000.0D0 else $
 if (num_rot ge 100.0D0) then carr_increm = 100.0D0 else $
 if (num_rot ge 10.0D0) then carr_increm = 10.0D0 else $
 if (num_rot ge 0.0D0) then carr_increm = 1.0D0 

  
 carr_test = carr_test + carr_increm
 JD_test = carr_jd_fn(double(carr_test),0.0D0)

endwhile

Lo = jd_lo_fn(JD)
Bo = jd_bo_fn(JD)
pred_carr=carr_jd_fn(carr_test,Lo)

del_JD = abs(JD-pred_carr)
if (del_JD gt 20.0) then begin 

  if (JD-pred_carr lt 0.0D0) then carr_test = carr_test - 1.0D0 else $
  carr_test = carr_test + 1.0D0

endif

; print,carr_test,Lo,Bo

caldat,(JD+2440000.0D0),mmm,ddd,yyy
dayfr = JD-long(JD) + 0.5D0
if (dayfr ge 1.0D0) then dayfr = dayfr - 1.0D0

; print,JD,JD+2440000.0D0,mmm,ddd,yyy,dayfr,format='(f14.7,1x,f14.5,1x,i2,1x,i2,1x,i4,1x,f10.3)'

return

end



