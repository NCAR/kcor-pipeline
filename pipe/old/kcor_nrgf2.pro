;+
;-------------------------------------------------------------------------------
; NAME:
;   kcor_nrgf2
;
; PURPOSE:
;   Apply NRG (normalized, radially-graded) filter to kcor an image list,
;   using a cadence of 2 minutes.
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
;   15 May 2015 Adapt from "kcor_nrgfs.pro".  Add 2-minute time cadence logic.
;   26 May 2015 use Joan's modifications to mask the image & cause the
;               occulter region to be black.
;   07 Jul 2015 Add polar grid in occulter region.
;   15 Jul 2015 Add /NOSCALE keyword to readfits.
;-------------------------------------------------------------------------------
;-

pro kcor_nrgf2, fits_list

TIC
GET_LUN, ULIST

nfiles = 0
fits_file = ''

;-------------------------------------------------------------------------------
; File loop.
;-------------------------------------------------------------------------------

OPENR, ULIST, fits_list
WHILE (not EOF (ULIST)) DO $
BEGIN ;{
   nfiles += 1
   readf, ULIST, fits_file 
   img      = readfits (fits_file, hdu, /NOSCALE, /SILENT)

   xdim     = sxpar (hdu, 'NAXIS1')
   ydim     = sxpar (hdu, 'NAXIS2')
   xcen     = (xdim / 2.0) - 0.5
   ycen     = (ydim / 2.0) - 0.5
   date_obs = sxpar (hdu, 'DATE-OBS')	; yyyy-mm-ddThh:mm:ss
   
   ;--- Extract date and time from FITS header.
   
   year   = strmid (date_obs, 0, 4)
   month  = strmid (date_obs, 5, 2)
   day    = strmid (date_obs, 8, 2)
   hour   = strmid (date_obs, 11, 2)
   minute = strmid (date_obs, 14, 2)
   second = strmid (date_obs, 17, 2)
   m2     = strmid (date_obs, 15, 1)
   sec    = fix (second)

   ;--- Select the first image every 2 minutes:
   ;
   ;    Skip images whose least significant minute digit is odd.
   ;    Skip image unless the seconds are <= 15.

   IF (m2 EQ '1' OR m2 EQ '3' OR m2 EQ '5' OR m2 EQ '7' OR m2 EQ '9') THEN $
      CONTINUE
   IF (sec GT 14) THEN CONTINUE
   print, 'sec: ', sec
   
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
   
   radius_guess = 178
   img_info = kcor_find_image (img, radius_guess)
   xc   = img_info (0)
   yc   = img_info (1)
   r    = img_info (2)
   arcpix = 5.643		; arcsec / pixel = platescale
   
   rocc    = occulter / arcpix		; occulter radius [pixels].
   r_photo = rsun / arcpix		; photosphere radius [pixels]
   r0      = rocc + 2			; add 2 pixels for inner FOV.
   ;r0      = (960.0 * 1.05) / arcpix
   
   print, 'rsun     [arcsec]: ', rsun 
   print, 'occulter [arcsec]: ', occulter
   print, 'rocc     [pixels]: ', rocc
   print, 'r0       [pixels]: ', r0
   
   ;--- Compute normalized, radially-graded filter.
   
   for_nrgf, img, xcen, ycen, r0, imgflt
   
   imin = min (imgflt)
   imax = max (imgflt)
   cmin = imin / 2.0 
   cmax = imax / 2.0
   cmin = imin
   cmax = imax
   
   if (imin LT 0.0) then $
   begin ;{
      amin = abs (imin)
      amax = abs (imax)
      if (amax GT amin) then max = amax else max = amin
   end   ;}
   
   print, 'imin/imax: ', imin, imax
   print, 'cmin/cmax: ', cmin, cmax
   
   ;-----------------------------
   ; Use mask to build gif image.
   ;-----------------------------

   ; Set image dimensions.

   xsize = LONG (xdim)
   ysize = LONG (ydim)
   xx1   = findgen (xsize, ysize) mod (xsize) - 511.5
   yy1   = transpose (findgen (ysize, xsize) mod (ysize)) - 511.5
   xx1   = double (xx1)
   yy1   = double (yy1)
   rad1  = sqrt (xx1^2.0 + yy1^2.0)

   r_in  = fix (rocc) + 5.0	; inner radius
   r_out = 504.0		; outer radius

   dark = where (rad1 LT r_in OR rad1 GE r_out)
   imgflt (dark) = -10.0

   ;----------------
   ; Graphics setup.
   ;----------------
   
   set_plot, 'Z'
   device, set_resolution = [xdim, ydim], $
           decomposed=0, set_colors=256, z_buffering=0
   erase
   
   ;set_plot, 'X'
   ;device, decomposed = 1
   ;window, xsize = xdim, ysize = ydim, retain = 2
   
   ;--- Load color table.
   
   lct,   '/hao/acos/sw/idl/color/quallab.lut'    ; color table.
   tvlct, red, green, blue, /get
   
   ;----------------------------
   ; Display image and annotate.
   ;----------------------------
   
   tv, bytscl (imgflt, cmin, cmax, top=249)
   
   xyouts, 4, 990, 'HAO/MLSO', color = 255, charsize = 1.5, /device
   xyouts, 4, 970, 'K-Coronagraph', color = 255, charsize = 1.5, /device

   xyouts, 512, 1000, 'North', color = 255, charsize = 1.2, alignment = 0.5, $
   	            /device
   xyouts, 22, 512, 'East', color = 255, charsize = 1.2, alignment = 0.5, $
                    orientation = 90., /device
   xyouts, 512, 12, 'South', color = 255, charsize = 1.2, alignment = 0.5, $
   	            /device
   xyouts, 1012, 512, 'West', color = 255, charsize = 1.2, alignment = 0.5, $
                      orientation = 90., /device

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
   xyouts, 4, 6, 'Intensity: normalized, radially-graded filter', $
                 color = 255, charsize = 1.2, /device
   xyouts, 1018, 6, 'circle: photosphere.', $
                    color = 255, charsize = 1.2, /device, alignment = 1.0

   ;--- Image has been shifted to center of array.
   ;--- Draw circle at photosphere.
   
;   tvcircle, r_photo, 511.5, 511.5, color = 255, /device

   suncir_kcor, xdim, ydim, xcen, ycen, 0, 0, r_photo, 0.0
   
   ;--------------------------------------
   ; Save displayed image into a GIF file.
   ;--------------------------------------

   save     = tvrd ()
   fts_loc = strpos (fits_file, '.fts')
   gif_file = strmid (fits_file, 0, fts_loc) + '_nrgf.gif'
   
   print, 'gif_file: ', gif_file
   
   write_gif, gif_file, save, red, green, blue
END   ;}
;-------------------------------------------------------------------------------
; End of file loop.
;-------------------------------------------------------------------------------

CLOSE, ULIST
FREE_LUN, ULIST

total_time = TOC ()
loop_time  = total_time / nfiles
print, 'loop_time: ', loop_time, ' total_time: ', total_time

end
