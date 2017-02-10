;+
;-------------------------------------------------------------------------------
; NAME:
;   kcor_nrgfs
;
; PURPOSE:
;   Apply NRG (normalized, radially-graded) filter to a list of kcor images.
;
; INPUTS:
;   fits_list:	list file containing kcor L1 fits files
;
; OUTPUTS:
;   gif files
;
; AUTHOR:
;   Andrew L. Stanger   HAO/NCAR
;   14 Apr 2015
;   20 Apr 2015 input is a list file, instead of a single fits file name.
;   19 May 2015 use Joan's modifications to mask the image and cause the
;               occulter region to be black.
;   29 May 2015 Add polar grid pattern.
;   15 Jul 2015 Add /NOSCALE keyword to readfits.
;   02 Mar 2016 Generate a 16 bit fits nrgf image in addition to a gif.
;-------------------------------------------------------------------------------
;-

pro kcor_nrgfs, fits_list

GET_LUN, ULIST

fnum = 0
fits_file = ''

;-----------
; File loop.
;-----------

OPENR, ULIST, fits_list
WHILE (not EOF (ULIST)) DO $
BEGIN ;{
   readf, ULIST, fits_file 

   ;--- Read L1 FITS file.

   img      = readfits (fits_file, hdu, /NOSCALE, /SILENT)
   fts_loc  = strpos (fits_file, '.fts')
   
   xdim       = sxpar (hdu, 'NAXIS1')
   ydim       = sxpar (hdu, 'NAXIS2')
   xcen       = xdim / 2.0 - 0.5
   ycen       = ydim / 2.0 - 0.5
   date_obs   = sxpar (hdu, 'DATE-OBS')	; yyyy-mm-ddThh:mm:ss
   platescale = sxpar (hdu, 'CDELT1')	; arcsec/pixel
   
   ;--- Extract date and time from FITS header.
   
   year   = strmid (date_obs, 0, 4)
   month  = strmid (date_obs, 5, 2)
   day    = strmid (date_obs, 8, 2)
   hour   = strmid (date_obs, 11, 2)
   minute = strmid (date_obs, 14, 2)
   second = strmid (date_obs, 17, 2)
   
   odate   = strmid (date_obs, 0, 10)	; yyyy-mm-dd
   otime   = strmid (date_obs, 11, 8)	; hh:mm:ss
   
   ;--- Convert month from integer to name of month.
   
   IF (month EQ '01') THEN name_month = 'Jan'
   IF (month EQ '02') THEN name_month = 'Feb'
   IF (month EQ '03') THEN name_month = 'Mar'
   IF (month EQ '04') THEN name_month = 'Apr'
   IF (month EQ '05') THEN name_month = 'May'
   IF (month EQ '06') THEN name_month = 'Jun'
   IF (month EQ '07') THEN name_month = 'Jul'
   IF (month EQ '08') THEN name_month = 'Aug'
   IF (month EQ '09') THEN name_month = 'Sep'
   IF (month EQ '10') THEN name_month = 'Oct'
   IF (month EQ '11') THEN name_month = 'Nov'
   IF (month EQ '12') THEN name_month = 'Dec'
   
   ;--- Determine DOY.
   
   mday      = [0,31,59,90,120,151,181,212,243,273,304,334]
   mday_leap = [0,31,60,91,121,152,182,213,244,274,305,335] ;leap year
   
   IF ((fix(year) mod 4) EQ 0) THEN $
      doy = (mday_leap(fix(month)-1) + fix(day))$
   ELSE $
      doy = (mday (fix (month) - 1) + fix (day))
   
   rsun = sxpar (hdu, 'RSUN')		; radius of photosphere.
   
   ; ----------------------
   ; Find size of occulter.
   ; ----------------------
   ; One occulter has 4 digits; Other two have 5.
   ; Only read in 4 digits to avoid confusion.
   
   occulter_id = ''
   occulter_id = sxpar (hdu, 'OCCLTRID')
   occulter = strmid (occulter_id, 3, 5)
   occulter = float (occulter)
   IF (occulter eq 1018.0) THEN occulter = 1018.9
   IF (occulter eq 1006.0) THEN occulter = 1006.9
   
   ;--- Find occulter size (pixels).

   radius_guess = 178
   img_info = kcor_find_image (img, radius_guess)
   xc   = img_info (0)
   yc   = img_info (1)
   r    = img_info (2)
   
   rocc    = occulter / platescale		; occulter radius [pixels].
   r_photo = rsun / platescale			; photosphere radius [pixels]
   r0      = rocc + 2				; add 2 pixels for inner FOV.
   ;r0      = (rsun * 1.05) / platescale
   
   cneg = FIX (ycen - r_photo)
   cpos = FIX (ycen + r_photo)

   print, 'rsun     [arcsec]: ', rsun 
   print, 'occulter [arcsec]: ', occulter
   print, 'rocc     [pixels]: ', rocc
   print, 'r0       [pixels]: ', r0
   
   ;------------------------------------------------
   ; Create NRG (normalized, radially-graded) image.
   ;------------------------------------------------
   
   for_nrgf, img, xcen, ycen, r0, imgflt
   
;   imin = min (imgflt)
;   imax = max (imgflt)
;
;   print, 'imin/imax: ', imin, imax
;
;   cmin = imin / 2.0 
;   cmax = imax / 2.0
;   cmin = imin
;   cmax = imax

   cmin = -2.0
   cmax =  4.0

   print, 'cmin/cmax: ', cmin, cmax

;   if (imin LT 0.0) then $
;   begin ;{
;      amin = abs (imin)
;      amax = abs (imax)
;      if (amax GT amin) then max = amax else max = amin
;   end   ;}
   
   
   ;-----------------------------
   ; Use mask to build GIF image.
   ;-----------------------------

   ;--- Create masking arrays.

   xx1   = findgen (xdim, ydim) mod (xdim) - xcen
   yy1   = transpose (findgen (ydim, xdim) mod (ydim)) - ycen 
   xx1   = double (xx1)
   yy1   = double (yy1)
   rad1  = sqrt (xx1^2.0 + yy1^2.0)

   ;--- Set limits for masking.

   r_in  = fix (occulter / platescale) + 5.0
   r_out = 504.0

   dark = where (rad1 LT r_in OR rad1 GE r_out)
   imgflt (dark) = -10.0	; Set areas outside annulus to -10.

   ;-----------------
   ; Graphics device.
   ;-----------------
   
   set_plot, 'Z'
   device, set_resolution = [1024, 1024], $
           decomposed=0, set_colors=256, z_buffering=0
   erase
   
   ;set_plot, 'X'
   ;device, decomposed = 1
   ;window, xsize = xdim, ysize = xdim, retain = 2
   
   ;--- Load color table.
   
   lct,   '/hao/acos/sw/idl/color/quallab.lut'    ; color table.
   tvlct, red, green, blue, /get
   
   ;----------------------------
   ; Display image and annotate.
   ;----------------------------
   
   tv, bytscl (imgflt, cmin, cmax, top=249)
   
   xyouts, 4, 990, 'HAO/MLSO/Kcor', color = 255, charsize = 1.5, /device
   xyouts, 4, 970, 'K-Coronagraph', color = 255, charsize = 1.5, /device

;   xyouts, 512, 1000, 'North', color = 255, charsize = 1.2, alignment = 0.5, $
;   	            /device
;   xyouts, 22, 512, 'East', color = 255, charsize = 1.2, alignment = 0.5, $
;                    orientation = 90., /device
;   xyouts, 512, 12, 'South', color = 255, charsize = 1.2, alignment = 0.5, $
;   	            /device
;   xyouts, 1012, 512, 'West', color = 255, charsize = 1.2, alignment = 0.5, $
;                      orientation = 90., /device


   xyouts, 505, cpos-24, 'N', color=254, charsize=1.5, /device
   xyouts, cneg+12, 505, 'E', color=254, charsize=1.5, /device
   xyouts, 506, cneg+12, 'S', color=254, charsize=1.5, /device
   xyouts, cpos-24, 505, 'W', color=254, charsize=1.5, /device

   xyouts, 1018, 995, string (format = '(a2)', day) + ' ' + $
                      string (format = '(a3)', name_month) +  ' ' + $
                      string (format = '(a4)', year), /device, alignment = 1.0,$
                      charsize = 1.2, color = 255
   xyouts, 1010, 975, 'DOY ' + string (format = '(i3)', doy), /device, $
                      alignment = 1.0, charsize = 1.2, color = 255
   xyouts, 1018, 955, string (format = '(a2)', hour) + ':' + $
                      string (format = '(a2)', minute) + ':' + $
   	           string(format = '(a2)', second) + ' UT', /device, $
                      alignment = 1.0, charsize = 1.2, color = 255

   xyouts, 4, 46, 'Level 1 data', color = 255, charsize = 1.2, /device
   xyouts, 4, 26, 'min/max: ' + string (format = '(f4.1)', cmin) + ', ' $
                              + string (format = '(f4.1)', cmax), $
   	          color = 255, charsize = 1.2, /device
   xyouts, 4, 6, 'Intensity: normalized, radially-graded', $
                 color = 255, charsize = 1.2, /device
   xyouts, 1018, 6, 'circle: photosphere', $
                    color = 255, charsize = 1.2, /device, alignment = 1.0

   ;--- Image has been shifted to center of array.
   ;--- Draw circle at photosphere.
   
;   tvcircle, r_photo, xcen, ycen, color = 255, /device

   suncir_kcor, xdim, ydim, xcen, ycen, 0, 0, r_photo, 0.0
   
   ;--------------------------------------
   ; Save displayed image into a GIF file.
   ;--------------------------------------

   save     = tvrd ()
   gif_file = strmid (fits_file, 0, fts_loc) + '_nrgf.gif'
   
   print, 'gif_file:  ', gif_file
   
   write_gif, gif_file, save, red, green, blue

   ;-------------------------------
   ; Create short integer RG image.
   ;-------------------------------

   bscale = 0.001
   simg = fix (imgflt * 1000.0)	; convert RG image to short integer.
   datamin = min (simg) * bscale
   datamax = max (simg) * bscale
   dispmin = cmin
   dispmax = cmax

   ;---------------------------------------------
   ; Modify the FITS header for an NRG fits image.
   ;---------------------------------------------

   rhdu = hdu
   fxaddpar, rhdu, 'LEVEL',  'L1NRGF', $
                             ' Level 1 Normalized Radially-Graded Intensity'
   fxaddpar, rhdu, 'BSCALE', bscale, $
                           ' Normalized Radially-Graded H.Morgan+S.Fineschi', $
                              format = '(f10.3)'
   fxaddpar, rhdu, 'DATAMIN', datamin, ' minimum value of  data', $
                              format = '(f10.3)'
   fxaddpar, rhdu, 'DATAMAX', datamax, ' maximum value of  data', $
                              format = '(f10.3)'
   fxaddpar, rhdu, 'DISPMIN', dispmin, ' minimum value for display', $
                              format = '(f10.3)'
   fxaddpar, rhdu, 'DISPMAX', dispmax, ' maximum value for display', $
                              format = '(f10.3)'
   fxaddpar, rhdu, 'DISPEXP', 1, ' exponent value for display (d=b^dispexp)', $
                              format = '(f10.3)'

   ;---------------------
   ; Write NRG fits file.
   ;---------------------

   fts_loc   = strpos (fits_file, '.fts')
   rfts_file = strmid (fits_file, 0, fts_loc) + '_nrgf.fts'

   print, 'rfts_file: ', rfts_file

   writefits, rfts_file, simg, rhdu

END   ;}

CLOSE, ULIST
FREE_LUN, ULIST

end
