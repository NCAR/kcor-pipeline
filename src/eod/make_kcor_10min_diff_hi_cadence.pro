;  docformat = 'rst'

;+
;  0) Goal: Create running differenced images every 30 seconds with images 10 minutes apart in time.
;     NOTE:  K-COr data cadence is 15 seconds (with no data gaps). 
;  1) Create averaged images from list of KCor level 2 pB fits data,
;     Current version is set to average up to 2 images if they are taken ~< 16 sec apart
;  2) generate subtractions every 30 sec from averages that are >= 10 minutes apart in time.
;  3) check subtractions for quality by checking azimutal scan intensities at 1.15 Rsun 
;  5) save each subtraction as an annotated gif image with quality value in filename
;  6) add option to smooth images (in case data are very noisey)

;  Complications come in bookkeeping to account for any data gaps (i.e. images not available every 15 s)
;  We are creating running differences with cadence very close to image cadence of telescope. Any
;  data gap (as small as one missing image) affects the data handling logic.
;
;  J. Burkepile
;  Jan 2023
;  Based on my code from 2018 that produced running diferences every 5 minutes.
;  History:
;  june-july 2023 [JB] Fix bugs in handling any possible data gap, i.e. gaps as small as 1 missing image. 
;  
;
;  SUBROUTINES used:
;     tscan.pro to do quality control check  ; A. Stanger code
;     rcoord.pro    ; A. Stanger
;     blint.pro	    ; A. Stanger
;     kcor_suncir_nolog to draw circle and position angle locations  ; A. Stanger code, modified M. Galloy
;     fits routines:  read_fits, fxpar 
;     date_julian   ;  convert to julian date
;
;  SYNTAX: make_kcor_10min_diff_hi_cadence,'list'
;-
;  


pro make_kcor_10min_diff_hi_cadence,list,smoothit=smoothit

;  Set up variables and arrays needed
l2_file=''      ; foreground fits image for subtraction
base_file=''    ; background fits image for subtraction
fits_file = ''  ; name of created subtraction fits image
gif_file = ''  ; name of created subtraction gif image
red=bytarr(256) ; for color table
green=bytarr(256) ; for color table
blue=bytarr(256) ; for color table



date_julian = dblarr(4)

; SET up julian date intervals for averaging, creating subtractions,
; and how often subtractions are created.
; Currently: 	average 2 images over a maximum of 30 seconds
; 		create a subtraction image every  minute	
;  		create subtractions using averaged images 10 minutes apart
;         ***   K-Cor images are not exactly 15 seconds apart; the average cadence is 15.0112 sec.

; ** NOTE: 15.011 seconds in julian date units = 1.7374130e-4
; ** NOTE: 30 seconds in julian date units = 3.4722e-04   ; provides 2 image average
; ** NOTE: 1 minute  in julian date units = 0.69444e-03    
; ** NOTE: 2 minutes in julian date units = 1.38889e-03
; ** NOTE: 5 minutes in julian date units = 3.47222e-03
; ** NOTE:10 minutes in julian date units = 6.94445e-03
;

;  Set up for 16 second avgs and ~30.02 second cadence subtractions

avgnum = 2  ; maximum number of images to average; depends on cadence of subtractions

;avginterval = double(1.85185e-04)       ; ~16 seconds in julian units ; maximum 2 image average / 30 sec cadence
;time_between_subs = double(0.34722e-03) ; 
;subinterval = 6.94445e-03      ; 10 minutes in julian units

avginterval = double(15.999984/3600./24.)       ; ~16 seconds in julian units ; maximum 2 image average / 30 sec cadence
time_between_subs = double(29.999808000000002/3600./24.) ; 
subinterval = double(600.00048000000004/3600./24.)      ; 10 minutes in julian units

bkdimgnum = 40 ;  size of bkd image stack depends on cadence of subtractions, i.e. time_between_subs

imgsave= fltarr(1024,1024,avgnum)
aveimg = fltarr(1024,1024)
bkdimg = fltarr(1024,1024,bkdimgnum)
bkdtime=dblarr(bkdimgnum)
filetime = strarr(bkdimgnum)
timestring= ' '  ; use to format bkd time for gif image annotation
savefilename = ''
avgimghr0 = '  ' 
avgimghr1 = '  ' 
avgimgmnt0 = '  ' 
avgimgmnt1 = '  ' 
avgimgsec0 = '  ' 
avgimgsec1 = '  ' 
imgtime = strarr(avgnum)

subimg = fltarr(1024,1024)


GET_LUN, ULIST
CLOSE,ULIST
imglist = list

OPENR, ULIST, imglist

; set up counting variables

avgcount=0   ; keep track of number of averaged images 
bkdcount=0   ; keep track of number of background images up to 12 for stack storage
imgcount=0   ; keep track of number of images read 
subtcount = 0 ; has a subtraction image been created?
stopavg = 0  ; set to 1 if images are more than 2 minutes apart (stop averaging)
newsub = 0
datagap = 0


;-----------------------------------------------------------
; Read in images and generate subtractions ~10 minutes apart
;-----------------------------------------------------------

while (not EOF(ULIST) ) DO BEGIN ;{

numavg = 0

for i = 0,avgnum-1 do begin   ; read in up to 2 images, get time, and average if images < 16 sec apart

   if (datagap eq 1) then begin  ; Already have an image from previous loop as first image
      i = 1
      datagap = 0
   endif

   readf,ULIST,l2_file
   img=readfits(l2_file,header,/silent,/noscale)
   if keyword_set(smoothit) then img=smooth(img,2)
   imgsave(*,*,i) = float(img)

;-----------------------------------------
; scaling information for quality scans
;-----------------------------------------

   rsun= fxpar (header, 'RSUN_OBS')         ; solar radius [arcsec/Rsun]
   level = fxpar (header, 'LEVEL')
   IF (level eq 'l1') THEN rsun= fxpar (header, 'RSUN') ; older processing version  
   cdelt1   = fxpar (header, 'CDELT1')       ; resolution   [arcsec/pixel]
   pixrs = rsun / cdelt1
   r_photo = rsun/cdelt1
   xcen     = fxpar (header, 'CRPIX1')       ; X center
   ycen     = fxpar (header, 'CRPIX2')       ; Y center
   roll = 0.


;-----------------------------------------
; Find image time 
;-----------------------------------------

   date_obs = fxpar(header, 'DATE-OBS')   ; yyyy-mm-ddThh:mm:ss
   date     = strmid (date_obs,  0,10)          ; yyyy-mm-dd

;-----------------------------
;--- Extract fields from DATE_OBS.
;-----------------------------
   yr   = strmid (date_obs,  0, 4)
   mon  = strmid (date_obs,  5, 2)
   dy    = strmid (date_obs,  8, 2)
   hr   = strmid (date_obs, 11, 2)
   mnt = strmid (date_obs, 14, 2)
   sec = strmid (date_obs, 17, 2)
   imgtime(i) =  string(format='(a2,a2,a2)',hr,mnt,sec)

;-----------------------------
; Convert strings to integers
;-----------------------------

   year   = fix (yr)
   month  = fix (mon)
   day    = fix (dy)
   hour   = fix (hr)
   minute = fix (mnt)
   second = fix (sec)

;-----------------------------
;find julian day
;-----------------------------

   date_julian(i) = julday(month,day,year,hour,minute,second)

   if (i eq 0) then begin ;{
      aveimg = imgsave(*,*,0)
      avgimghr0  = hr
      avgimgmnt0 = mnt
      avgimgsec0 = sec
      savefilename = l2_file
      goodheader = header  ; follow protocoal for all KCor processed data
                           ;  that use filename and start time as start of first image scan
      numavg = 1
   endif  ;}

;  --------------------------------------------------------------------------------
;  Once we have read more than one image we check that images are <= 30 seconds apart
;  ** NOTE: 30 secondsin julian date units = 0.34722e-03
;  If images are <= 30 seconds apart we average them together
;  If images are > 30 secs   apart we stop averaging, save avg. image and make a subtraction
;  --------------------------------------------------------------------------------

   if (i gt 0) then begin ;{

       difftime = date_julian(i) - date_julian(0)

       if (difftime le avginterval) then begin ;{ 
            aveimg = aveimg + imgsave(*,*,i)
            if (i eq 1) then begin 
              avgimghr1 = hr
              avgimgmnt1 = mnt
              avgimgsec1 = sec
            endif
	    numavg = numavg + 1
       endif ;}

       if (difftime gt avginterval) OR (numavg eq avgnum) then begin ;{
          stopavg = 1  ; set flag to stop averaging
       endif ;}

      
   endif ;}

   if (stopavg eq 1) then break

endfor

   i = i-1

   stopavg = 0

; -----------------------------------------
; Make averaged image
; -----------------------------------------

   aveimg = aveimg/float(numavg)
   avgcount = avgcount + 1
   bkdcount = bkdcount + 1

; ------------------------------------------------------------------
;  Build up a stack of up to 20 averaged images to use as future background images
;  Next add later images to stack until we have 20 unique images in stack
;  Latest time is put into stack(0), oldest time is in bottom of stacker index = bkdimgnum - 1
; ------------------------------------------------------------------

; FIRST LOOP TO BUILD UP BACKGROUND IMAGE STACK: Initialize the stack with the first image only

   if (bkdcount eq 1) then begin ;{
      time_since_sub = date_julian(i)  
         for j = 0,bkdimgnum-1 do begin
            bkdimg(*,*,j) = aveimg
            bkdtime(j) = date_julian(0)
	    filetime(j) = imgtime(0)
         endfor
   endif ;}

;TODO:
;CHECK IN THESE 2 STACKS IF IMAGE TIME IS ALREADY IN THE STACK

   if (bkdcount gt 1 AND subtcount eq 0) then begin ;{
      counter = bkdimgnum - 2
      for k = 0,counter do begin   
         bkdtime(counter+1-k)= bkdtime(counter-k)
         bkdimg(*,*,counter+1-k) = bkdimg(*,*,counter-k)
         filetime(counter+1-k) = filetime(counter-k)
      endfor
      bkdimg(*,*,0) = aveimg          ; Copy current image into 0 position (latest time)
      bkdtime(0) = date_julian(i)
      filetime(0) = imgtime(i)
   endif ;}


    if (subtcount ge 1) then begin
       counter = bkdimgnum - 2
       for k = 0,counter do begin   
         bkdtime(counter+1-k)= bkdtime(counter-k)
         bkdimg(*,*,counter+1-k) = bkdimg(*,*,counter-k)
         filetime(counter+1-k) = filetime(counter-k)
       endfor
	bkdimg(*,*,0) = newbkdimg0
	bkdtime(0) = newbkdtime0
	filetime(0) = newfiletime0
     endif

;   print,filetime
;   print,imgtime(i) ,bkdcount
 
; IF CONDITIONS ARE MET THEN MAKE A SUBTRACTION
; 
;   create a subtraction image IF current image is 
;   at least 30 sec from previous subtraction and there is an available  bkd image >=10 minutes earlier. 

;   First check under conditions with no data gaps: 

;  if (numavg ge avgnum AND date_julian(i)-time_since_sub ge time_between_subs) then begin 
  if (numavg le avgnum AND date_julian(i)-time_since_sub ge time_between_subs) then begin 
     for j = 0,bkdimgnum-1 do begin
        if (date_julian(i)-bkdtime(j) ge subinterval AND newsub eq 0) then begin  
           subimg = aveimg - bkdimg(*,*,j)
           newsub = 1  ;  Need to write a new subtraction image
	   subtcount = subtcount + 1
	   time_since_sub = date_julian(i)
	   timestring = filetime(j)     ; bkd time for gif annotation and fits metadata
           newbkdimg0 = aveimg    ; save current image as the new bkd image 
           newbkdtime0 = date_julian(i) ; save current time as the new time of bkd image 
	   newfiletime0 = imgtime(i)
 	endif 
     endfor
   endif 



;   ----------------------------------------------------------------------------------
;   If a subtraction image was created save:

;   1) perform a quality control check using an azimuthal scan at 1.15 solar radii
;    and checking the absolute values of the intensities. Flag the filenames with: good, pass, bad
;   2) Create annotation for the gif image
;   3) Create gif and fits image of the subtraction
;   ----------------------------------------------------------------------------------

;   ----------------------------------------------------------------------------------
;   1) SET UP SCAN PARAMETERS and perform quality control scan on subtraction image: 
;   ----------------------------------------------------------------------------------

  thmin = 0.
  thmax = 359.
  thinc = 0.5
  radius = 1.15
  pointing_ck = 0
  good_value = 100
  pass_value = 250


  if (newsub eq 1) then begin ;{  
  
  print,'make new subtraction'

      tscan,savefilename, subimg, pixrs,roll, xcen, ycen, thmin, thmax, thinc, radius, scan, scandx, ns
;      tscan,l2_file, subimg, pixrs,roll, xcen, ycen, thmin, thmax, thinc, radius, scan, scandx, ns

      for i = 0, ns - 1 do begin
           if (abs(scan(i)) gt 1.e-8) then pointing_ck = pointing_ck + 1
      endfor

;   ----------------------------------------------------------------------------------
;   2) Create annotation for gif image
;   ----------------------------------------------------------------------------------
;-------------------------------------------
; Get time of first image used in the average  
; This follows protocol for all KCor data   
;-------------------------------------------

   date_obs    = strmid (savefilename,  0,15)          ; yyyymmdd_hhmmss

;-----------------------------
;--- Extract fields from DATE_OBS.
;-----------------------------
   yr   = strmid (date_obs,  0, 4)
   mon  = strmid (date_obs,  4, 2)
   dy    = strmid (date_obs,  6, 2)
   hr   = strmid (date_obs, 9, 2)
   mnt = strmid (date_obs, 11, 2)
   sec = strmid (date_obs, 13, 2)

;-----------------------------
; Convert strings to integers
;-----------------------------

   year   = fix (yr)
   month  = fix (mon)
   day    = fix (dy)
   hour   = fix (hr)
   minute = fix (mnt)
   second = fix (sec)

    ; convert month from integer to name of month
    name_month = (['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', $
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'])[month - 1]

    date_img = dy + ' ' + name_month + ' ' + yr + ' ' $
               + hr + ':' + mnt + ':'  + sec

    ; compute DOY [day-of-year]
    mday      = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
    mday_leap = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]   ; leap year

    if ((year mod 4) eq 0) then begin
      doy = (mday_leap[month - 1] + day)
    endif else begin
      doy = (mday[month - 1]) + day
    endelse


;   ----------------------------------------------------------------------------------
;   3) Create gif and fits images
;   ----------------------------------------------------------------------------------

    set_plot,'Z'
    device, set_resolution=[1024, 1024], decomposed=0, set_colors=256, $
            z_buffering=0
    loadct,0
    tvlct,red,green,blue,/get

;  ****************************
;  IMPORTANT - FOR PIPELINE
;   use display_min = -1.e-8 
;   AND display_max = 2.e-8 
;   as the default in the pipeline
;  ***************************

    display_min = -5.e-09
    display_max =  5.e-08


    tv,bytscl((subimg),display_min,display_max)

    xyouts, 4, 990, 'MLSO/HAO/KCOR', color=255, charsize=1.5, /device
    xyouts, 4, 970, 'K-Coronagraph', color=255, charsize=1.5, /device
    xyouts, 512, 1000, 'North', color=255, charsize=1.2, alignment=0.5, $
            /device
    xyouts, 1018, 995, string(format='(a2)', dy) + ' ' $
              + string(format='(a3)', name_month) $
              + ' ' + string(format = '(a4)', yr), $
            /device, alignment=1.0, $
            charsize=1.5, color=255
    xyouts, 1010, 975, 'DOY ' + string(format='(i3)', doy), /device, $
            alignment=1.0, charsize=1.5, color=255

    if (datagap eq 2) then begin  ;   only 2nd image used in average:
       xyouts, 1018, 955, string(format='(a2)', avgimghr2) + ':' $
                         + string(format = '(a2)', avgimgmnt2) $
                         + ':' + string(format='(a2)', avgimgsec2) + ' UT', $
            /device, alignment=1.0, charsize=1.5, color=255
    endif else begin    
       xyouts, 1018, 955, string(format='(a2)', hr) + ':' $
                         + string(format = '(a2)', mnt) $
                         + ':' + string(format='(a2)', sec) + ' UT', $
            /device, alignment=1.0, charsize=1.5, color=255
    endelse
    xyouts, 1010, 935, 'MINUS', /device, alignment=1.0, charsize=1.5, color=255
    xyouts, 1018, 915, string(format='(a2)', strmid(timestring,0,2)) + ':' $
                         + string(format = '(a2)', strmid(timestring,2,2)) $
                         + ':' + string(format='(a2)', strmid(timestring,4,2)) + ' UT', $
            /device, alignment=1.0, charsize=1.5, color=255

 
   
    xyouts, 22, 512, 'East', color=255, charsize=1.5, alignment=0.5, $
            orientation=90., /device
    xyouts, 1012, 512, 'West', color=255, charsize=1.5, alignment=0.5, $
            orientation=90., /device
    xyouts, 4, 46, 'Subtraction', color=255, charsize=1.5, /device
    xyouts, 4, 26, string(format='("min/max: ", e10.2, ", ", e10.2)',display_min,display_max), $
            color=255, charsize=1.5, /device
    xyouts, 1018, 6, 'Circle = photosphere.', $
            color=255, charsize=1.5, /device, alignment=1.0

    ; image has been shifted to center of array
    ; draw circle at photosphere
    kcor_suncir_nolog, 1024,1024,511.5, 511.5, 0, 0, r_photo, 0.0

;   Add AVGTIME0 keyword to fits header that contains times of images used to generate the average

; set default for label

    label = 'Default label'
    IF (avgnum eq 2) then label = string(format='(a2,":",a2,":",a2," ",a2,":",a2,":",a2)',avgimghr0,$
     avgimgmnt0, avgimgsec0,avgimghr1,avgimgmnt1, avgimgsec1)
    
    IF (avgnum eq 1) and (datagap eq 1) then label = string(format='(a2,":",a2,":",a2)',avgimghr0,$
     avgimgmnt0, avgimgsec0)
    
    IF (avgnum eq 1) and (datagap eq 2) then label = string(format='(a2,":",a2,":",a2)',avgimghr1,$
     avgimgmnt1, avgimgsec1)
    
     fxaddpar, goodheader,'AVGTIME0', label,' Img times used in avg'

      device,decomposed = 1 
      save=tvrd()
      if (pointing_ck le good_value) then gif_file = strmid(savefilename, 0, 20) + '_minus_' + timestring + '_good.gif'
      if (pointing_ck gt good_value AND pointing_ck le pass_value) then gif_file = strmid(savefilename, 0, 20) + '_minus_' + timestring + '_pass.gif'
      if (pointing_ck gt pass_value) then gif_file = strmid(savefilename, 0, 20) + '_minus_' + timestring + '_bad.gif'
      write_gif, gif_file, save

      name= strmid(savefilename, 0, 20)
      if (pointing_ck le good_value) then fits_file= string(format='(a20,"_minus_",a6,"_good.fts")',name,timestring)
      if (pointing_ck gt good_value AND pointing_ck le pass_value) then fits_file= string(format='(a20,"_minus_",a6,"_pass.fts")',name,timestring)
      if (pointing_ck gt pass_value) then fits_file= string(format='(a20,"_minus_",a6,"_bad.fts")',name,timestring)


      writefits,fits_file,subimg,goodheader,/silent

   IF (datagap eq 2) then datagap = 0

; Under following conditions need to save image 2 for next average image loop
   if (datagap eq 1 OR newsub eq 0) then begin 
         goodheader = header
	 savefilename = l2_file
	 aveimg = imgsave(*,*,1)
	 imgtime(0) = imgtime(1)
	 date_julian(0) = date_julian(1)
	 avgimghr0 = avgimghr1
	 avgimgmnt0 = avgimgmnt1
	 avgimgsec0 = avgimgsec1
   endif


      newsub = 0

  endif ;}



endwhile ;}

;*******************************************************************************
; end of WHILE loop
;*******************************************************************************


end
