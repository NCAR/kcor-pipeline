PRO  test_comb, file=file, cunit=cunit, plot=plot

default, plot, 1

   ; ---------------------
   ;  SET DIMENSIONS
   ; ---------------------
    xsize = 1024L
    ysize = 1024L

if not keyword_set (file) then $
file ='20150317_225555_kcor.fts.gz'


print, 'file used: ', file 

 image=readfits(file, header)
 img = double(image)

   ; --------------------------------
   ;  SOLAR RADIUS, P and B ANGLE
   ; -------------------------------
  
   dateobs = SXPAR (header, 'DATE-OBS')
   ephem = pb0r (dateobs, /earth)
   pangle = ephem (0)      
   bangle = ephem (1)
   radsun = ephem (2)    ; arcmin

   print, dateobs

   ; --------------------------------
   ;  PLATESCALE AND OCCULTER ID 
   ; --------------------------------

   platescale = 5.643			; arcsec/pixel.
   occulter_id = ''
   occulter_id = fxpar (header, 'OCCLTRID')
   occulter = strmid (occulter_id, 3, 5)
   occulter = float (occulter)
   IF (occulter eq 1018.0) THEN occulter = 1018.9
   IF (occulter eq 1006.0) THEN occulter = 1006.9

   radius_guess=occulter/platescale

; read gain with no occulter in 
; this is a placeholder
gain_no_occulter=fltarr(xsize, ysize)
gain_no_occulter(*)=1300.

if not keyword_set (cunit) then $
cunit = ncdf_open('20150315_202646_kcor_cal_1.0ms.ncdf')

ncdf_varget, cunit, 'Dark', dark_alfred
ncdf_varget, cunit, 'Gain', gain_alfred
ncdf_varget, cunit, 'Modulation Matrix', mmat
ncdf_varget, cunit, 'Demodulation Matrix', dmat
ncdf_close, cunit

; set negative values in gain to value in gain_negative
gain_negative = -1000
gain_alfred (WHERE (gain_alfred le 0, /NULL)) = gain_negative

for b = 0, 1 do begin
    gain_temp = double(reform(gain_alfred (*, *, b)))
;     plot, gain_temp(*,1000)
   filter = mean_filter(gain_temp, 5, 5, invalid = gain_negative , missing=1)
   bad = WHERE (gain_temp eq gain_negative, nbad)
   if nbad gt 0 then begin 
      gain_temp(bad) = filter(bad)
      gain_alfred (*, *, b) = gain_temp
;      oplot, gain_temp(*,1000), color=100, line=2, thick=2
      wait, 1 
   endif
endfor
gain_temp = 0


   window, 0, xs = xsize, ys = ysize, retain = 2
   radius_guess = 178.

   center0_info_gain = kcor_find_image (gain_alfred(*,*,0), radius_guess)
   center1_info_gain = kcor_find_image (gain_alfred(*,*,1), radius_guess)

if plot eq 1 then begin

      loadct, 0
      tv, bytscl(gain_alfred(*,*,0), 0, 3000)
      loadct, 39
      draw_circle,  center0_info_gain(0), center0_info_gain(1), center0_info_gain(2), /dev, color= 250    

      loadct, 0
      print, ' CENTER FOR GAIN 0: ', center0_info_gain
      wait, 1 
      loadct, 0
      tv, bytscl(gain_alfred(*,*,1), 0, 3000)
      loadct, 39
      draw_circle,  center1_info_gain(0), center1_info_gain(1), center1_info_gain(2), /dev, color= 250    
      loadct, 0
      print, ' CENTER FOR GAIN 1:', center1_info_gain
      wait, 1 
endif



; define arrays for gain 

   gxx0 = findgen(xsize,ysize)mod(xsize) - center0_info_gain(0)
   gyy0 = transpose(findgen(ysize,xsize)mod(ysize) ) - center0_info_gain(1)
   gxx0 = double(gxx0) &  gyy0 = double(gyy0)
   grr0 = sqrt(gxx0^2. + gyy0^2.)  

   gxx1 = findgen(xsize,ysize)mod(xsize) - center1_info_gain(0)
   gyy1 = transpose(findgen(ysize,xsize)mod(ysize) ) - center1_info_gain(1)
   gxx1 = double(gxx1) &  gyy1 = double(gyy1)
   grr1 = sqrt(gxx1^2. + gyy1^2.)  

;   gainshift = fltarr (xsize,ysize, 2)
    img_new = img 

  
cal_data = dblarr (xsize, ysize, 2, 3)
cal_data_new =dblarr (xsize, ysize, 2, 3)


 
;  FIND CENTER FOR CAMERA 0
    
      center0_info_img  = kcor_find_image (img (*, *, 0, 0),  radius_guess, /center_guess)
      xctr0 = center0_info_img(0)
      yctr0 = center0_info_img(1) 
      radius_0 = center0_info_img(2)

      xx0 = findgen(xsize,ysize)mod(xsize) - xctr0   
      yy0 = transpose(findgen(ysize,xsize)mod(ysize) ) - yctr0
      xx0 = double(xx0)  &  yy0 = double(yy0)
      rr0 = sqrt(xx0^2. + yy0^2.)
      theta0 = (atan(-yy0,-xx0)) 
      theta0  = theta0 + !pi

;      pick0 = where(rr0 le radius_0 and rr0 ge 3)
;      mask_occulter0 = fltarr(xsize, ysize)
;      mask_occulter0 (*)=1.
;      mask_occulter0(pick0) = 0.0 
;      for s = 0,3 do img(*,*, s, 0) =  img(*,*, s,0)*mask_occulter0

if plot eq 1 then begin 
      tv, bytscl(img(*,*, 0,0), 0, 20000)
      loadct, 39
      draw_circle, xctr0, yctr0, radius_0, /dev, color=250
      loadct, 0
      print, 'CENTER FOR CAMERA 0 ', center0_info_img
      wait, 1     
  endif


;  FIND CENTER FOR CAMERA 1

      center1_info_img  = kcor_find_image (img (*, *, 0, 1),  radius_guess, /center_guess)
      xctr1 = center1_info_img(0)  
      yctr1 = center1_info_img(1)  
      radius_1 = center1_info_img(2)

      xx1 = findgen(xsize,ysize)mod(xsize) - xctr1  
      yy1 = transpose(findgen(ysize,xsize)mod(ysize) ) - yctr1
      xx1=double(xx1) &  yy1=double(yy1)
      rr1 = sqrt(xx1^2. + yy1^2.)
      theta1  = (atan(-yy1,-xx1)) 
      theta1  = theta1 + !pi

      pick1 = where(rr1 le radius_1 or rr1 ge 2.9*radius_1)
      mask_occulter1 = fltarr(xsize, ysize)
      mask_occulter1 (*) = 1.
      mask_occulter1(pick1) = 0.0
;      for s = 0,3 do img(*,*, s, 1 ) =  img(*,*, s, 1)*mask_occulter1

if plot eq 1 then begin 
      tv, bytscl(img(*,*, 0,1), 0, 20000)
      loadct, 39
      draw_circle, xctr1, yctr1, radius_1, /dev, color=250
      loadct, 0
      print, 'CENTER FOR CAMERA 1 ', center1_info_img
      wait, 1 
endif

;   build new gain to account for shift 

;    replace = where(rr0 gt radius_0 -1. and grr0 le center0_info_gain(2) +2. , nrep)
;    if nrep gt 0 then gain0(replace) = 1350. ; gain_no_occulter(replace)
;    replace = where(rr1 gt radius_1 -1. and grr1 le center1_info_gain(2) +2. , nrep)
;    if nrep gt 0 then  gain1(replace) = 1260; gain_no_occulter(replace)
;

; for now use gainshift to fill mising region

;       tv, bytscl(gain_alfred(*,*,0), 0, 3000)
;       tv, bytscl(gain_alfred(*,*,1), 0, 3000)

    
; replace data where we do not have the gain, i.e. pixels under the occulter in the gain, 
; with gainshifted  --- we will use the reference gain with no occulter in the future.

    replace = where(rr0 gt radius_0 - 3. and grr0 le center0_info_gain(2) + 3. , nrep)
    if nrep gt 0 then begin 
      gain_temp =  gain_alfred (*, *, 0)
      gain_replace =   shift (gain_alfred (*, *, 0), xctr0 - center0_info_gain(0), yctr0 - center0_info_gain(1) )
      gain_temp(replace) = gain_replace(replace) ;gain_no_occulter0(replace)    
      print, 'correcting gain 0 for shift'
if plot eq 1 then begin 
      tv, bytscl(gain_temp , 0, 3000)
      wait = 1
endif
      gain_alfred (*, *, 0) = gain_temp
    endif

    replace = where(rr1 gt radius_1 - 3. and grr1 le center1_info_gain(2) + 3. , nrep)
    if nrep gt 0 then  begin 
      gain_temp =  gain_alfred (*, *, 1)
      gain_replace =  shift (gain_alfred (*, *, 1), xctr1 - center1_info_gain(0), yctr1 - center1_info_gain(1) )
      gain_temp(replace) = gain_replace(replace) ; gain_no_occulter1(replace)      
      print, 'correcting gain 1 for shift'
if plot eq 1 then begin 
      tv, bytscl(gain_temp , 0, 3000)
      wait, 1        
endif
      gain_alfred (*, *, 1) = gain_temp
    endif

    gain_temp=0
    gain_replace=0


;--- APPLY DARK AND FLAT-FIELD CORRECTION 
;  set negative values to zero

  for b = 0, 1 do  begin
      for s = 0, 3 do begin 
         img_new(*, *, s, b) =  img(*, *, s, b)  - dark_alfred(*, *, b)
         img_temp = reform(img_new(*, *, s, b))
         img_temp(WHERE (img_temp le 0, /NULL)) = 0
         img_new(*,*,s,b) = img_temp
           img_new(*, *, s, b) =    img_new(*, *, s, b) / gain_alfred(*, *, b)
      endfor 
   endfor
   img_temp =0 

  print, ' applying demodulation'

;--- APPLY DEMODULATION MATRIX TO GET I, Q, U images from each camera ---

   for b = 0, 1 do begin     
      for y = 0, 1023 do begin
         for x = 0, 1023 do begin
            cal_data (x,y,b,*) = reform (dmat(x,y,b,*, *))##reform(img_new(x,y,*,b))
        endfor
      endfor
   endfor   


  print, ' find center for images after distorsion' 

;--- FIND CENTER FOR IMAGES AFTER DISTORSION CORRECTION 
; find shift between the two IMAGES 

   image0 = reform (img (*,*,0,0))
   image0 = reverse (image0, 2)
   image1 = reform (img (*,*,0,1))

   restore, '/home/iguana/idl/kcor/dist_coeff.sav'
   dat1 = image0 
   dat2 = image1 
   apply_dist, dat1, dat2, dx1_c, dy1_c, dx2_c, dy2_c
   image0 = dat1
   image1 = dat2

pause


  ;--- CAMERA 0:

   center0_info_new = kcor_find_image (image0, radius_guess, /center_guess)
   xctr0    = center0_info_new (0)
   yctr0    = center0_info_new (1)
   radius_0 = center0_info_new (2)

if plot eq 1 then begin 
   tv, bytscl(image0, 0, 20000)
   loadct, 39
   draw_circle, xctr0, yctr0, radius_0, /dev, color=250
   loadct, 0
   print, 'CENTER FOR CAMERA 0 ', center0_info_new
   wait, 1     
endif


   ;--- CAMERA 1:

   center1_info_new = kcor_find_image (image1, radius_guess, /center_guess)
   xctr1    = center1_info_new (0)
   yctr1    = center1_info_new (1)
   radius_1 = center1_info_new (2)

   xx1 = findgen(xsize,ysize)mod(xsize) - xctr1  
   yy1 = transpose(findgen(ysize,xsize)mod(ysize) ) - yctr1
   xx1=double(xx1) &  yy1=double(yy1)
   rad1 = sqrt(xx1^2. + yy1^2.)
   theta1  = (atan(-yy1,-xx1)) 
   theta1  = theta1 + !pi

if plot eq 1 then begin 
   tv, bytscl(image1, 0, 20000)
   loadct, 39
   draw_circle, xctr1, yctr1, radius_1, /dev, color=250
   loadct, 0
   print, 'CENTER FOR CAMERA 1 ', center1_info_new
   wait, 1     
endif

radius = (radius_0 + radius_1)*0.5

; to shift camera 0 to canera 1 
deltax =  xctr1  - xctr0 
deltay =  yctr1  - yctr0 


print, 'combine beams'

; TEST TO COMBINE BEAMS

   for s = 0, 2 do begin
      cal_data(*, *, 0, s) = reverse(cal_data(*, *, 0, s), 2, /overwrite)
  endfor

   restore, '/home/iguana/idl/kcor/dist_coeff.sav'

   for s = 0, 2 do begin
      dat1 = cal_data (*, *, 0, s)
      dat2 = cal_data (*, *, 1, s)
      apply_dist, dat1, dat2, dx1_c, dy1_c, dx2_c, dy2_c
      cal_data (*, *, 0, s) = dat1
      cal_data (*, *, 1, s) = dat2      
  endfor

 cal_data_combined = dblarr(xsize, ysize,3)
   for s = 0, 2 do begin
      cal_data_combined(*,*,s) = ( fshift (cal_data(*, *, 0, s), deltax, deltay) + cal_data(*, *, 1, s) )*0.5
   endfor
 
tv, bytscl(cal_data_combined(*,*,0), 0, 100)  
draw_circle, xctr1, yctr1, radius_1, /dev, color=0



phase=-17/!radeg
phase=0.0


         qmk4 = - cal_data_combined (*, *, 1) * sin (2.*theta1+ phase) $
	        + cal_data_combined (*, *, 2) * cos (2.*theta1+ phase)
         qmk4 = -1.0 * qmk4

         umk4 =   cal_data_combined (*, *, 1) * cos (2.*theta1+ phase) $
	        + cal_data_combined (*, *, 2) * sin (2.*theta1+ phase)


         intensity = cal_data_combined (*, *, 0)
        
tv, bytscl(umk4, -0.5, 0.5)

print, 'finished combined beams'


; this shift the images in the middle of the array and puts north up
; if shift_center is set to 1 

shift_center = 0
if shift_center eq 1 then begin

   cal_data_combined_center = dblarr(xsize, ysize, 3)

   FOR s = 0, 2 DO BEGIN 
      cal_data_new (*, *, 0, s) = rot (reverse (cal_data (*, *, 0, s), 1), $
                                   pangle, 1, xsize-1-xctr0, yctr0, cubic=-0.5)
      cal_data_new (*, *, 1, s) = rot (reverse (cal_data(*, *, 1, s), 1), $
                                  pangle, 1, xsize-1-xctr1, yctr1, cubic=-0.5)

     cal_data_combined_center(*, *, s) = (cal_data_new(*, *, 0, s) + cal_data_new(*, *, 1, s))*0.5
   ENDFOR 
 

    xx1 = findgen (xsize, ysize) mod (xsize) - 511.5 
    yy1 = transpose (findgen (ysize, xsize) mod (ysize) ) - 511.5
    xx1 = double (xx1) &  yy1 = double (yy1)  
    rad1 = sqrt ( xx1^2. + yy1^2. )  
    theta1  = (atan(-yy1,-xx1)) 
    theta1  = theta1 + !pi
    theta1 = rot(reverse(theta1), pangle, 1)
    xctr1 =  511.5  & yctr1 =  511.5 

print, 'finished  combined beams center'

window, 1, xs = xsize, ys = ysize, retain = 2
wset,1
tv, bytscl(cal_data_combined_center(*,*,0), 0, 100)
draw_circle,  xctr1, yctr1, radius, /dev, color=0
 
wset,1

         qmk4 = - cal_data_combined_center (*, *, 1) * sin (2.*theta1+ phase) $
	        + cal_data_combined_center (*, *, 2) * cos (2.*theta1+ phase)
         qmk4 = -1.0 * qmk4

         umk4 =   cal_data_combined_center (*, *, 1) * cos (2.*theta1+ phase) $
	        + cal_data_combined_center (*, *, 2) * sin (2.*theta1+ phase)

         intensity = cal_data_combined_center (*, *, 0)

tv, bytscl(umk4, -0.5, 0.5)


endif

        
print, ' apply sky_polarization removal'


   ; -------------------------------------------------------------------------
   ;  SKY POLARIZATION REMOVAL ON COORDINATE TRANSFORMED DATA ---
   ;
   ; -------------------------------------------------------------------------

   r_init=1.8
   rnum=7

   radscan = fltarr(rnum)
   amplitude1 =  fltarr(rnum)
   phase1 = fltarr(rnum)
 
;   numdeg=360
;   numdeg=180
    numdeg = 90
    stepdeg = 360/numdeg
    degrees = findgen(numdeg)*stepdeg + 0.5*stepdeg  
    degrees = double(degrees)/!radeg
    
  a = dblarr (2)   ;  coefficients for sine(2*theta) fit
  weights = fltarr (numdeg)
  weights(*)= 1.0

   angle_ave_u   = dblarr (numdeg)
   angle_ave_q   = dblarr (numdeg)
 

!p.multi=[0,2,2]
!p.charsize=1.5
!y.style=1


;-- Initialize guess for parameters
;  as we loop we will use the parameters from the previous fit as a guess 

;  fit in U and Q   
;   a(0) = 0.012
;   a(1) = 0.25
 

;  fit in U/I and Q/I
   a(0) = 0.0033
   a(1) = 0.14

factor=0.95
bias = 0.0005

   FOR  ii =0, rnum-1 do begin 
  
   angle_ave_u(*)=0d0
   angle_ave_q(*)=0d0

 ; Use solar radius, radsun*60 = radius in arcsec
 ; KCor platescale = 5.643 arcsec / pixel

   radstep=0.15
   r_in  = (r_init+ii*radstep) 
   r_out = (r_init+ii*radstep+radstep) 
   print, ' annulus radii: ', r_in, r_out
   r_in =r_in * radsun*60. / 5.643
   r_out =r_out * radsun*60. / 5.643
   radscan(ii)= (r_in+r_out)/2.

   ; Extract annulus and average all heights at stepdeg increments 
   ; around the sun.

;  make new theta arrays in degrees

   theta1_deg=theta1*!radeg

; define U/I and Q/I
   umk4_int = umk4/intensity
   qmk4_int = qmk4/intensity


  j=0
   FOR i = 0, 360 - stepdeg, stepdeg do begin 
   angle=float(i)
   pick1 = where(rr1 ge r_in and rr1 le r_out and theta1_deg ge angle and theta1_deg lt angle + stepdeg, nnl1) 
   if nnl1 gt 0 then begin 
   angle_ave_u(j) = mean( umk4_int(pick1) )
   angle_ave_q(j) = mean( qmk4_int(pick1) )
   endif
   j=j +1
   ENDFOR 

   sky_polar_cam1 = curvefit (degrees, double(angle_ave_u), weights, a, $
                              FUNCTION_NAME = 'sine2theta_new')

   print, 'fit coeff : ' , a(0), a(1)*!radeg
   amplitude1(ii)=a(0)
   phase1(ii)=a(1)
   mini=-0.15
   maxi= 0.15
if plot eq 1 then begin 
   loadct, 39 
   plot,  degrees*!radeg,  angle_ave_u, thick=2, title='U', ystyle=1
   oplot, degrees*!radeg, sky_polar_cam1, color=100, thick=5
   oplot,  degrees*!radeg, a(0)*factor*sin(2.0*degrees+a(1)), lines=2,thick=5, color=50
   wait,1
   plot,  degrees*!radeg, angle_ave_q, thick=2, title='Q', ystyle=1
   oplot, degrees*!radeg, a(0)*sin(2.0*degrees -90./!radeg + a(1)) , color=100, thick=5
   oplot, degrees*!radeg, a(0)*factor*sin(2.0*degrees -90./!radeg + a(1)) -bias ,  lines=2, color=50, thick=5
   wait, 0.4
   loadct, 0 
pause
endif

ENDFOR


mean_phase1 = mean(phase1)
;radial_amplitude1 = interpol(amplitude1, radscan, rr1,/spline)
;radial_amplitude1 = interpol(amplitude1, radscan, rr1, /quadratic)
;force the fit to be a straight line
 afit_amplitude = poly_fit(radscan, amplitude1, 1, afit)
 radial_amplitude1 = interpol(afit, radscan, rr1, /quadratic)


if plot eq 1 then begin 
plot, rr1(*,500)*5.643/(radsun*60.), radial_amplitude1(*,500), xtitle='distance (solar radii)', $
ytitle='amplitude', title='CAMERA 1'
oplot, radscan*5.643/(radsun*60.), amplitude1, psym=2
wait,1
endif

radial_amplitude1 = reform(radial_amplitude1, xsize, ysize)
if plot eq 1 then tvscl, radial_amplitude1
wait, 1

   sky_polar_u1 = radial_amplitude1 * sin (2.0*theta1 + mean_phase1) 
   sky_polar_q1 = radial_amplitude1 * sin (2.0*theta1 - 90./!radeg + mean_phase1 ) - bias


    qmk4_new = qmk4  - factor*sky_polar_q1*intensity
    umk4_new = umk4  - factor*sky_polar_u1*intensity 


if plot eq 1 then begin 
tv, bytscl(qmk4_new, -1,1)
   draw_circle, xctr1, yctr1, radius_1, thick=4, color=0,  /dev
for i=0, rnum-1 do draw_circle, xctr1, yctr1, radscan(i), /dev
for ii=0,numdeg-1 do plots, [xctr1,  xctr1+500*cos(degrees(ii))], [yctr1, yctr1+500*sin(degrees(ii))], /dev
wait,1
endif


print, ' finished sky polarization removal'

print,'pausing'
pause

   corona0 = sqrt(qmk4^2 + umk4^2)                   ; add beams U and Q - with no sky polarizatio correction - linear pol
   corona2 = sqrt(qmk4_new^2 + umk4_new^2)           ; add beams U and Q - with sky polarizatio correction - linear pol
   corona =  sqrt(qmk4_new^2)                        ; add beams only Q - with sky polarizatio correction pB

    r_in = fix (occulter / platescale) + 2.
    r_out = 504.0
    bad = where(rad1 lt r_in or rad1 ge r_out) 
    corona(bad)=0
    corona2(bad)=0
    corona0(bad)=0
    wset,0
    tv, bytscl(sqrt(corona), 0., 1.5)

print,'pausing'
pause

wait,1
  
   lct, '/hao/acos/sw/colortable/quallab_ver2.lut'      ; color table.
   tvlct, red, green, blue, /get
   mini  = 0.00  ; 
   maxi = 1.20   ; 

   test = (corona+0.03)^0.8
   test(bad)=0
   tv, bytscl (test,  min = mini, max = maxi)


print, 'finished'

stop

end


