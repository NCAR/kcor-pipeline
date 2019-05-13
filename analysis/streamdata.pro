;;; This is a very quick program to look through the kcor raw binary
;;; stream images.
;;;
;;; Edit this code for your special case.
;;; orginal code to read binary data from 
;;; Alice Lecinski 2012 Jan 25
;;;
;;; Modified: Burkepile

;;;; added codeto eliminate outliers

;   DATA ARE LOCATED ON:  /hao/mlsodata1/Data/KCor/raw/20181203/stream_data/184832raw

cd , '/hao/sunrise/Data/KCor/raw/2018/20181203/stream_data/184832raw'

clist='imlist'

pixx = 1024
piyy = 1024
nframe = 495  

;avgimg=dblarr(pixx,piyy,4,2)
singleimg=fltarr(pixx,piyy,nframe)
state0=fltarr(pixx,piyy,nframe)
state1=fltarr(pixx,piyy,nframe)
state2=fltarr(pixx,piyy,nframe)
state3=fltarr(pixx,piyy,nframe)

avgall=dblarr(pixx,piyy)

;   ****************************************
;  Logic for READING IMAGE AS SIGNED integer:
;   ****************************************
     img0 = intarr(pixx,piyy)  &  intarr_read = 1
     img1 = intarr(pixx,piyy)  &  intarr_read = 1
     img2 = intarr(pixx,piyy)  &  intarr_read = 1
     img3 = intarr(pixx,piyy)  &  intarr_read = 1

filenm=' '

openr,13,clist

for i=0, nframe-1 do begin 

    readf,13,filenm
    openr,1,filenm & readu,1,img0 & close,1 
    fimg0= float(img0)
;    avgimg(*,*,0,0) = fimg0 + avgimg(*,*,0,0)
    state0(*,*,i) = fimg0

    readf,13,filenm
    openr,1,filenm & readu,1,img1 & close,1 
    fimg1= float(img1) 
;    avgimg(*,*,1,0) = fimg1 + avgimg(*,*,1,0)
    state1(*,*,i) = fimg1

    readf,13,filenm
    openr,1,filenm & readu,1,img2 & close,1 
    fimg2= float(img2)
;    avgimg(*,*,2,0) = fimg2 + avgimg(*,*,2,0)
    state2(*,*,i) = fimg2

    readf,13,filenm
    openr,1,filenm & readu,1,img3 & close,1 
    fimg3= float(img3)
;    avgimg(*,*,3,0) = fimg3 + avgimg(*,*,3,0)
    state3(*,*,i) = fimg3

    singleimg(*,*,i) = sqrt( (fimg0 -fimg3)^2 + (fimg1 - fimg2)^2 )

    endfor
close,13


state00a=mean(state0, dim=3)
state11a=mean(state1, dim=3)    
state22a=mean(state2, dim=3)
state33a=mean(state3, dim=3)


corona_mean  = sqrt( (state00a - state33a)^2 + (state22a - state11a)^2 )


state00=median(state0, dim=3)
state11=median(state1, dim=3)    
state22=median(state2, dim=3)
state33=median(state3, dim=3)


corona_median = sqrt((state00  - state33)^2  + (state22  - state11)^2 )


window,0,xs=1024,ys=1024,retain=2
loadct,0
wset,0
tv, bytscl(corona_median^.5,0,5)

window,1,xs=1024,ys=1024,retain=2
wset,1
tv, bytscl(corona_mean^.5,0,5)

;print, 'done mean and median'


;stop


;dark =readfits('/hao/mlsodata1/Data/KCor/raw/20181204/level0/20181204_192310_kcor.fts.gz',hdr)
;dark =float(dark)
;dark= (reform(dark(*,*,0,0))+ reform(dark(*,*,1,0))+reform(dark(*,*,2,0))+ reform(dark(*,*,3,0)))*.250

;image= readfits('/hao/mlsodata1/Data/KCor/raw/20181203/level0/20181203_175353_kcor.fts.gz', hdu1)
;image=float(image)
;image=reform(image(*,*,0,0))

;image_dark = image-dark

;image_ave = state00a*16.
;image_ave_dark = image_ave -dark*490./512.

;window, 2, retain=2
;!p.multi=[0,1,2]
;plot, image(50:150, 512), psym=10
;oplot, image_ave(50:150, 512), psym=10, color=90

;plot, image_dark(50:150, 512), psym=10
;plot, image_ave_dark(50:150, 512), psym=10


;stop

; use median value to find signa 
; select pixels inside sigma 


newstate00=fltarr(pixx,piyy)
newstate11=fltarr(pixx,piyy)
newstate22=fltarr(pixx,piyy)
newstate33=fltarr(pixx,piyy)

mask00=fltarr(pixx,piyy)
mask11=fltarr(pixx,piyy)
mask22=fltarr(pixx,piyy)
mask33=fltarr(pixx,piyy)

; find the outliers 

; this uses 4 sigma, 
; 4sigma = 4./44., where 44e- is the camera gain per photon
; this can be made larger or smaller 
; 4 seems to be a reasonable number considering that some pixels are noisy

ss=4./44.

; if more than 10% of the frames are rejected, the code does not do anything,
; i.e. makes an average over all frames
; this may be too conservative for days with a lot of aerosols
; I tried to use 5% and was not removing all aerosols
; Hopefully we do not need to make the % of pixels rejected bigger or thr smaller 

thr =nframe*.90

for j=0,pixx-1 do begin 
for i=0,piyy-1 do begin

pick0 = where (abs(state0(i,j,*)-state00(i,j)) lt ss*sqrt(state00(i,j)*44.), npick0)
if npick0 gt thr  then newstate00(i,j)=mean( state0(i,j, pick0)) else $
newstate00(i,j)=state00a(i,j)
mask00(i,j)=npick0

pick1 = where (abs(state1(i,j,*)-state11(i,j)) lt ss*sqrt(state11(i,j)*44.),npick1)
if npick1 gt thr  then newstate11(i,j)=mean( state1(i,j, pick1)) else $
newstate11(i,j)=state11a(i,j)
mask11(i,j)=npick1

pick2 = where (abs(state2(i,j,*)-state22(i,j)) lt ss*sqrt(state22(i,j)*44.), npick2)
if npick2 gt thr  then newstate22(i,j)=mean( state2(i,j, pick2)) else $
newstate22(i,j)=state22a(i,j)
mask22(i,j)=npick2

pick3 = where (abs(state3(i,j,*)-state33(i,j)) lt ss*sqrt(state33(i,j)*44.), npick3)
if npick3 gt thr  then newstate33(i,j)=mean( state3(i,j, pick3)) else $
newstate33(i,j)=state33a(i,j)

mask33(i,j)=npick3

endfor
endfor

;need to add logic to retain CMEs
;if pick# has more than 4 consecutive indices do not through those indices away
;assume assume an aersols is visible in less than 5 frames


corona_new  = sqrt( (newstate00 - newstate33)^2 + (newstate22 - newstate11)^2 )

wset,0
loadct,0
tv, bytscl(corona_mean^.5,0,6)
wset,1
tv, bytscl(corona_new^.5,0,6)

print, 'all done' 

;FOR DEBUG
;display pixels where outliers where not eliminated:
;this includes the inner annulus around the occulter and a few very
;noisy pixels

;test=fltarr(pixx,piyy)
;pixel_unchanged=where(mask00 lt thr or mask11 lt thr or mask22 lt thr or mask33 lt thr)
;test(pixel_unchanged)=1
;tvscl, test


stop

end
