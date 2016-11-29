;+ IDL PROCEDURE
;
; NAME		frscan_kcor.pro
;
; PURPOSE	Perform a Mk4 rpb radial scan using a FITS image [cartesian].
;
; SYNTAX	frscan_kcor, fits_file, angle, radmin, radmax, radinc
;
; PARAMETERS	fits_file	name of FITS file.
;		angle		position angle [degrees CCW from solar North]
;		radmin		beginning radius [Rsun]
;		radmax		ending    radius [Rsun]
;		radinc		angle increment  [Rsun]
; OPTIONAL
;		ymin		Y-axis minimum value
;		ymax		Y-axis maximum value
;		text		Write scan data to a text file.
;		ps		Option to write plot to a postscript file.
;
; EXT.ROUTINES	rscan.pro	Performs radial scan.
; 		lct.pro		loads a color table from an ASCII file.
;		rcoord.pro	converts between [r,th] and [x,y] coordinates.
;
; NOTE 		This procedure works best in private colormap mode (256 levels).
;
; AUTHOR	Andrew L. Stanger   HAO/NCAR   03 Aug 2001
;
; 05 Nov 2015 [ALS] Adapt for use with kcor.
;-

PRO frscan_kcor, fits_file, angle, radmin, radmax, radinc, $
                 ymin=ymin, ymax=ymax, text=text, ps=ps

;-------------------------
; Default variable values.
;-------------------------

stars = '***'
date_obs = ''
time_obs = ''
ftspos   = STRPOS (fits_file, '.fts')
basename = STRMID (fits_file, 0, ftspos)
print, 'basename: ', basename

;------------------
; Load color table.
;------------------
lct, '/home/stanger/color/bwcp.lut'
lct, '/home/stanger/color/bwy.lut'
lct, '/hao/acos/sw/colortable/quallab.lut'

;---------------------------
; Color designations in LUT.
;---------------------------

yellow = 250
grey   = 251
blue   = 252
green  = 253
red    = 254
white  = 255

;--------------------------
; Read color lookup tables.
;--------------------------

redlut   = bytarr (256)
greenlut = bytarr (256)
bluelut  = bytarr (256)

tvlct, redlut, greenlut, bluelut, /get		; Read color table into arrays.

;--------------------------
; Read FITS image & header.
;--------------------------

img = readfits (fits_file, hdu, /noscale)

;---------------------------------
; Get parameters from FITS header.
;---------------------------------

telescop = fxpar (hdu, 'TELESCOP')	; Telescope name
instrume = fxpar (hdu, 'INSTRUME')	; Instrument name
date_obs = fxpar (hdu, 'DATE-OBS')	; observation date
xdim     = fxpar (hdu, 'NAXIS1')	; X dimension
ydim     = fxpar (hdu, 'NAXIS2')	; Y dimension
bzero    = fxpar (hdu, 'BZERO')		; brightness offset.
bscale   = fxpar (hdu, 'BSCALE')	; brightness scaling factor.
xcen     = fxpar (hdu, 'CRPIX1')	; X center
ycen     = fxpar (hdu, 'CRPIX2')	; Y center
cdelt1   = fxpar (hdu, 'CDELT1')	; resolution   [arcsec/pixel]
roll     = fxpar (hdu, 'INST_ROT')	; rotation angle [degrees]
rsun     = fxpar (hdu, 'RSUN')		; solar radius [arcsec/Rsun]
dispmin  = fxpar (hdu, 'DISPMIN', count=qdispmin)	; display min value.
dispmax  = fxpar (hdu, 'DISPMAX', count=qdispmax)	; display max value.
dispexp  = fxpar (hdu, 'DISPEXP', count=qdispexp)	; display exponent.

dateobs = strmid (date_obs,  0, 10)	; yyyy-mm-dd
timeobs = strmid (date_obs, 11,  8)	; hh:mm:ss

print, 'date_obs: ', date_obs
print, 'dateobs:  ', dateobs
print, 'timeobs:  ', timeobs

xcen -= 1	; FITS keyword value has origin = 1.  IDL index origin = 0.
ycen -= 1	; FITS keyword value has origin = 1.  IDL index origin = 0.
IF (xcen LT 0.0) then xcen = (xdim - 1) / 2.0
IF (ycen LT 0.0) then ycen = (ydim - 1) / 2.0

if (bscale EQ 1.0) then bscale = 0.001	; BSCALE incorrect for L1 < 15 Jul 2015.
img = img * bscale + bzero

datamin = min (img)
datamax = max (img)
pixrs   = rsun / cdelt1 
print, 'pixrs: ', pixrs

;-------------------------------------
; Convert numerical values to strings.
;-------------------------------------

sangle  = STRING  (angle, forMAT='(F7.2)')
sangle  = STRTRIM (sangle, 2)
sradmin = STRING  (radmin, forMAT='(F4.2)')
sradmin = STRTRIM (radmin, 2)
sradmax = STRING  (radmax, forMAT='(F4.2)')
sradmax = STRTRIM (sradmax, 2)
sradmin = STRTRIM (STRING (radmin, format='(f4.2)'), 2)

;----------------
; Do radial scan.
;----------------

rscan, namimg, img, pixrs, roll, xcen, ycen,		$
       radmin, radmax, radinc, angle,			$
       scan, scandx, ns

;for i = 0, ns-1  do	$
;print, 'scandx: ', scandx [i], '  scan: ', scan [i]

;-------------------------------------------------------
; If 'text' keyword set, write scan values to a text file.
;-------------------------------------------------------

if (KEYWORD_SET (text)) then	$
begin ;{
   text_file  = basename + '_pa' + sangle + '.txt'
   close,  11
   openw,  11, text_file
   printf, 11, fits_file, '   Radial Scan   ', sangle, ' degrees'

   for i = 0, ns - 1 do		$
      printf, 11, 'scandx: ', scandx [i], ' Rsun   scan: ', scan [i], $
                  ' pB [B/Bsun]'
   close, 11
end   ;}

;-------------------------------------------
; Reduce image size for display (if needed).
;-------------------------------------------

print, 'xdim/ydim: ', xdim, ydim

sizemax = 1024			; maximum image size: 1024x1024 pixels.
sizeimg = SIZE (img)		; get image size.

WHILE (sizeimg [1] GT sizemax OR sizeimg [2] GT sizemax) do	$
begin ;{
   img = REBIN (img, xdim/2, ydim/2)
   xdim = xdim / 2
   ydim = ydim / 2
   xcen = xcen / 2.0
   ycen = ycen / 2.0
   pixrs = pixrs / 2.0
   sizeimg = SIZE (img)
end   ;}

;---------------
; Display image.
;---------------

imin = MIN (img, max=imax)
SET_PLOT, 'Z'
DEVICE, set_resolution=[xdim, ydim], set_colors=256, z_buffering=0

dmin = 0.0
dmax = 1.2
dexp = 0.7
if (qdispmin NE 0) then dmin = dispmin
if (qdispmax NE 0) then dmax = dispmax
if (qdispexp NE 0) then dexp = dispexp

;WINDOW, xsize=xdim, ysize=ydim
;imgb = BYTSCL (img, min=imin, max=imax, top=249)
;imgb = BYTSCL (img, min=dispmin, max=dispmax, top=249)
;imgb = BYTSCL (img^0.7, min=0, max=1.2, top=249)

imgb = BYTSCL (img^dexp, min=dmin, max=dmax, top=249)
TV, imgb

;-------------
; Label image.
;-------------

XYOUTS,        5, ydim-15, fits_file,       /device, color=green,  charsize=1.2
XYOUTS,        5, ydim-35, telescop,        /device, color=green,  charsize=1.2
XYOUTS, xdim-110, ydim-15, dateobs,         /device, color=green,  charsize=1.2
XYOUTS, xdim-110, ydim-35, timeobs + ' UT', /device, color=green,  charsize=1.2
XYOUTS,        5,  25, sangle + ' deg',     /device, color=red,    charsize=1.2
XYOUTS,        5,   5, sradmin + ' - ' + sradmax + ' Rsun', 	$
	/device, color=red, charsize=1.2

;---------------------------
; Plot radial scan on image.
;---------------------------

radius = radmin - radinc
for i = 0, ns - 1 do	$
begin ;{
   radius = radius + radinc
   ierr = rcoord (radius, angle, x, y, 1, roll, xcen, ycen, pixrs)
   ixg = FIX (x + 0.5)
   iyg = FIX (y + 0.5)
;   PLOTS, [ixg, ixg], [iyg, iyg], /device, color=red
   PLOTS, [ixg-1, ixg+1], [iyg-1, iyg-1], /device, color=red
   PLOTS, [ixg-1, ixg+1], [iyg,   iyg  ], /device, color=red
   PLOTS, [ixg-1, ixg+1], [iyg+1, iyg+1], /device, color=red
end ;}

;---------------------------------------------------------
; Draw a dotted circle (10 degree increments) at 1.0 Rsun.
;---------------------------------------------------------

th = -10.0
r  =   1.0
for i = 0, 360, 10 do	$
begin ;{
   th = th + 10.0
   ierr = rcoord (r, th, x, y, 1, roll, xcen, ycen, pixrs)
   ixg = FIX (x + 0.5)
   iyg = FIX (y + 0.5)
   PLOTS, [ixg, ixg], [iyg, iyg], /device, color=grey
end   ;}

;-------------------------------------------------
; Draw dots every 30 degrees from 0.2 to 1.0 Rsun.
;-------------------------------------------------

th = 0.0
for it = 0, 11 do	$
begin ;{
   r  =  -0.2
   for i = 0, 5 do		$
   begin ;{
      r = r + 0.2
      ierr = rcoord (r, th, x, y, 1, roll, xcen, ycen, pixrs)
      ixg = FIX (x + 0.5)
      iyg = FIX (y + 0.5)
      PLOTS, [ixg, ixg], [iyg, iyg], /device, color=grey
   end   ;}
   th += 30.0
end   ;}

;-------------------------------------------------
; Draw dots every 90 degrees from 0.1 to 1.0 Rsun.
;-------------------------------------------------

th = 0.0
for it = 0, 3 do	$
begin ;{
   r  =  0.1
   for i = 0, 9 do	$
   begin ;{
      r = r + 0.1 
      ierr = rcoord (r, th, x, y, 1, roll, xcen, ycen, pixrs)
      ixg = FIX (x + 0.5)
      iyg = FIX (y + 0.5)
      PLOTS, [ixg, ixg], [iyg, iyg], /device, color=yellow
   end   ;}
   th += 90.0
end   ;}

;------------------------------------
; Read displayed image into 2D array.
;------------------------------------

imgnew = TVRD ()
extpos = STRPOS (fits_file, ".fts")
gif_file = basename + '_pa' + sangle + '_img.gif'
print, 'gif_file: ', gif_file

;-------------------------
; Write GIF image to disk.
;-------------------------

WRITE_GIF, gif_file, imgnew, redlut, greenlut, bluelut

yminset = 0
ymaxset = 0
if (KEYWORD_SET (ymin)) then yminset = 1  else ymin = min (scan)
if (KEYWORD_SET (ymax)) then ymaxset = 1  else ymax = max (scan)

print, 'yminset, ymaxset: ', yminset, ymaxset
print, 'ymin/ymax: ', ymin, ymax

;---------------------------------------
; Plot radial scan & save to a GIF file.
;---------------------------------------

DEVICE, /close
SET_PLOT, 'Z'
DEVICE, set_resolution=[1440, 768], set_colors=256, z_buffering=0

gif_file  = STRMID (fits_file, 0, extpos) + '_pa' + sangle + '_plot.gif'
print, 'gif_file: ', gif_file

if (yminset OR ymaxset) then			$
begin
PLOT, scandx, scan,				$
      title = fits_file + ' Radial Scan @' + sangle + ' degrees',	$
      xtitle = 'Radius [Rsun]',			$
      ytitle = 'Pixel Magnitude',		$
      yrange = [ymin, ymax],ystyle=2,ylog=0
end						$
else						$
PLOT, scandx, scan,				$
      background=255, color=0, charsize=1.0,	$
      title = fits_file + ' Radial Scan @' + sangle + ' degrees',	$
      xtitle = 'Radius [Rsun]',			$
      ytitle = 'Pixel Magnitude', yrange = [ymin, ymax], ystyle=2, ylog=0

save = TVRD ()
WRITE_GIF, gif_file, save, redlut, greenlut, bluelut

DEVICE, /close

;--- Plot radial scan to a postscript file.

if (KEYWORD_SET (ps)) then $
begin ;{
   ps_file  = STRMID (fits_file, 0, extpos) + '_pa' + sangle + '_plot.ps'
   print, 'ps_file: ', ps_file
   SET_PLOT, 'PS'
   DEVICE, filename=ps_file

   if (yminset OR ymaxset) then			$
   begin
   print, 'yrange: ', ymin, ymax
   PLOT, scandx, scan,				$
         title = fits_file + ' Radial Scan @' + sangle + ' degrees',	$
         xtitle = 'Radius [Rsun]',			$
         ytitle = 'Pixel Magnitude',		$
         yrange = [ymin, ymax],ystyle=2,ylog=0

   end						$
   else						$
   PLOT, scandx, scan,				$
         title = fits_file + ' Radial Scan @' + sangle + ' degrees',	$
         xtitle = 'Radius [Rsun]',		$
         ytitle = 'Pixel Magnitude',yrange = [ymin, ymax], ystyle=2, ylog=0

   DEVICE, /close
end   ;}

SET_PLOT, 'X'

end
