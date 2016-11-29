;+ IDL PROCEDURE
;
; NAME		ftscan_kcor.pro
;
; PURPOSE	Perform a K-coronagraph azimuthal scan
;		using a FITS image [cartesian coord].
;
; SYNTAX	ftscan_kcor, fits_file, radius, thmin, thmax, thinc
;
; PARAMETERS	REQUIRED:
;		fits_file	name of FITS file.
;		radius		radius value [Rsun units]
;		thmin		beginning angle [degrees]
;		thmax		ending    angle [degrees]
;		thinc		angle increment [degrees]
;
;		OPTIONAL:
;		ymin		Y-axis minimum value
;		ymax		Y-axis maximum value
;		text		write scan values to a text file.
;
; EXT.ROUTINES	tscan.pro	Performs azimuthal (theta) scan.
; 		lct.pro		loads a color table from an ASCII file.
;		rcoord.pro	converts between [r,th] and [x,y] coordinates.
;
; NOTE 		This procedure works best in private colormap mode (256 levels).
;
; AUTHOR	Andrew L. Stanger   HAO/NCAR   08 Feb 2001
;
; HISTORY	 7 Jun 2001 Adapt for SOHO/LASCO C2 (French version).
;		11 Nov 2015 Adapt for kcor.
;-

PRO ftscan_kcor, fits_file, radius, thmin, thmax, thinc, ymin=ymin, ymax=ymax, $
		 text=text

;-------------------------
; Default variable values.
;-------------------------

stars = '***'
date_obs = ''
time_obs = ''

ftspos   = STRPOS (fits_file, '.fts')
basename = STRMID (fits_file, 0, ftspos)
print, 'basename: ', basename

;--------------------------
; Read FITS image & header.
;--------------------------

img = readfits (fits_file, hdu, /noscale)

imin = min (img, max=imax)
print, 'imin/imax: ', imin, imax

;---------------------------------
; Get parameters from FITS header.
;---------------------------------

telescop = fxpar (hdu, 'TELESCOP')	; Telescope name
instrume = fxpar (hdu, 'INSTRUME')	; Instrument name
date_obs = fxpar (hdu, 'DATE-OBS')	; observation date
xdim     = fxpar (hdu, 'NAXIS1')	; X dimension
ydim     = fxpar (hdu, 'NAXIS2')	; Y dimension
xcen     = fxpar (hdu, 'CRPIX1')	; X center
ycen     = fxpar (hdu, 'CRPIX2')	; Y center
object   = fxpar (hdu, 'OBJECT')	; object observed
bunit    = fxpar (hdu, 'BUNIT')		; Brightness unit  (e.g., Bsun)
cdelt1   = fxpar (hdu, 'CDELT1')	; resolution   [arcsec/pixel]
bscale   = fxpar (hdu, 'BSCALE')	; physical = data * bscale + bzero
bzero    = fxpar (hdu, 'BZERO')
datamin  = fxpar (hdu, 'DATAMIN', count=qdatamin) ; Data    minimum intensity.
datamax  = fxpar (hdu, 'DATAMAX', count=qdatamax) ; Data    maximum intensity.
dispmin  = fxpar (hdu, 'DISPMIN', count=qdispmin) ; Display minimum intensity.
dispmax  = fxpar (hdu, 'DISPMAX', count=qdispmax) ; Display maximum intensity.
dispexp  = fxpar (hdu, 'DISPEXP', count=qdispexp) ; Display exponent.
roll     = fxpar (hdu, 'INST_ROT')	; instrument rotation angle (degrees).
rsun     = fxpar (hdu, 'RSUN')		; solar radius [arcsec/Rsun]

xcen = xcen - 1.0	; FITS keyword origin = 1.  IDL index origin = 0.
ycen = ycen - 1.0	; FITS keyword origin = 1.  IDL index origin = 0.

pixrs    = rsun / cdelt1
type_obs = object

dateobs = strmid (date_obs,  0, 10)	; yyyy-mm-dd
timeobs = strmid (date_obs, 11,  8)	; hh:mm:ss

if (bscale EQ 1.0) then bscale = 0.001
img = img * bscale + bzero

print, 'bscale/bzero: ', bscale, bzero
print, 'datamin/datamax: ', datamin, datamax
print, 'dispmin/dispmax,dispexp: ', dispmin, dispmax, dispexp
print, 'roll:  ', roll
print, 'pixrs: ', pixrs

if (qdispmin GT 0) then dmin = dispmin
if (qdispmax GT 0) then dmax = dispmax
if (qdispexp GT 0) then dexp = dispexp

if (xcen LT 0.0) then xcen = (xdim - 1) / 2.0
if (ycen LT 0.0) then ycen = (ydim - 1) / 2.0

ylab = type_obs + ' [' + bunit + ']'

print, 'date_obs: ', date_obs
print, 'time_obs:  ', time_obs
print, 'xdim/ydim: ', xdim, ydim
print, 'xcen/ycen: ', xcen, ycen
print, 'pixrs:     ', pixrs

;-------------------------------------
; Convert numerical values to strings.
;-------------------------------------

srad   = STRING (radius, forMAT='(F5.2)')
srad   = STRTRIM (srad, 2)
sthmin = STRING (thmin, forMAT='(F7.2)')
sthmin = STRTRIM (sthmin, 2)
sthmax = STRING (thmax, forMAT='(F7.2)')
sthmax = STRTRIM (sthmax, 2)

;---------------
; Do theta scan.
;---------------

tscan, namimg, img, pixrs, roll, xcen, ycen,	$
       thmin, thmax, thinc, radius,			$
       scan, scandx, ns

if (KEYWORD_SET (text)) then	$
begin
  text_file = basename + '_r' + srad + '_plot.txt'
  close,  11
  openw,  11, text_file
  printf, 11, fits_file, '   Azimuthal scan   ', srad, ' Rsun'

  for i = 0, ns - 1 do		$
    printf, 11, 'scandx: ', scandx [i], ' degrees   scan: ', scan [i], $
                ' pB [B/Bsun]'
  close, 11
end

;-------------------------------------------
; Reduce image size for display (if needed).
;-------------------------------------------

sizemax = 1024
sizeimg = SIZE (img)

WHILE (sizeimg [1] GT sizemax OR sizeimg [2] GT sizemax) do	$
    begin
    img  = REBIN (img, xdim/2, ydim/2)
    xdim = xdim / 2
    ydim = ydim / 2
    xcen = xcen / 2.0
    ycen = ycen / 2.0
    pixrs   = pixrs / 2.0
    sizeimg = SIZE (img)
    end

;---------------------------
; Establish graphics device.
;---------------------------

;SET_PLOT, 'X'
;DEVICE, PSEUdo_COLOR=8
;WINDOW, xsize=xdim, ysize=ydim, retain=2

SET_PLOT, 'Z'
DEVICE, set_resolution= [1024, 1024], set_colors=256, z_buffering=0

;------------------
; Load color table.
;------------------

lct, '/home/stanger/color/bwcp.lut'
lct, '/home/stanger/color/bwy.lut'
lct, '/home/stanger/color/dif.lut'
lct, '/hao/acos/sw/colortable/quallab.lut'

redlut   = bytarr (256)
greenlut = bytarr (256)
bluelut  = bytarr (256)

;---------------------------------------
; Color LUT designations for annotation.
;---------------------------------------

red    = 254
green  = 253
blue   = 252
grey   = 251
yellow = 250

;--------------------------
; Read color lookup tables.
;--------------------------

tvlct, redlut, greenlut, bluelut, /get		; Read color table into arrays.

;print, redlut
;print, greenlut
;print, bluelut

;---------------
; Display image.
;---------------

imin = MIN (img, max=imax)
dmin = 0.0
dmax = 1.2
dexp = 0.7

;imgb = BYTSCL (img, min=imin, max=imax, top=249)
;imgb = BYTSCL (img, min=dispmin, max=dispmax, top=249)
;imgb = BYTSCL (img, min=-35, max=35)

imgb = BYTSCL (img^dexp, min=dmin, max=dmax, top=249)
TV, imgb

;-------------
; Label image.
;-------------

xyouts,        2, ydim-15, fits_file, /device,       color=green, charsize=1.2
xyouts,        2, ydim-30, telescop,  /device,       color=green, charsize=1.2
xyouts, xdim-110, ydim-15, dateobs,   /device,       color=green, charsize=1.2
xyouts, xdim-110, ydim-30, timeobs + ' UT', /device, color=green, charsize=1.2
xyouts,        2,  20, srad + ' Rsun', /device,      color=red,   charsize=1.2
xyouts,        2,   5, sthmin + ' - ' + sthmax + ' deg.', 	$
	/device, color=red, charsize=1.2

;--------------------------
; Plot theta scan on image.
;--------------------------

th = thmin - thinc
for i = 0, ns - 1 do	$
   begin ;{
   th = th + thinc
   ierr = rcoord (radius, th, x, y, 1, roll, xcen, ycen, pixrs)
   ixg = FIX (x + 0.5)
   iyg = FIX (y + 0.5)
   PLOTS, [ixg, ixg], [iyg, iyg],         /device, color=red
   PLOTS, [ixg-1, ixg+1], [iyg-1, iyg+1], /device, color=red
   PLOTS, [ixg-1, ixg+1], [iyg,   iyg  ], /device, color=red
   PLOTS, [ixg-1, ixg+1], [iyg+1, iyg-1], /device, color=red
   PLOTS, [ixg,   ixg  ], [iyg+1, iyg-1], /device, color=red
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
; Read annotated image into 2D array.
;------------------------------------

img_plot = TVRD ()
gif_file = basename + '_r' + srad + '_img.gif'
print, 'gif_file: ', gif_file

;------------------------------------
; Save annotated image to a GIF file.
;------------------------------------

WRITE_GIF, gif_file, img_plot, redlut, greenlut, bluelut

;-------------------
; Y-axis plot range.
;-------------------

yminset = 0
ymaxset = 0
if (~KEYWORD_SET (ymin)) then ymin = min (scan)
if (~KEYWORD_SET (ymax)) then ymax = max (scan)

print, 'ymin/ymax: ', ymin, ymax
print, 'yrange: ', ymin, ymax

;-------------------------------
; Plot theta scan to a GIF file.
;-------------------------------

gif_file  = basename + '_r' + srad + '_plot.gif'
print, 'plot name: ', gif_file
SET_PLOT, 'Z'
DEVICE, set_resolution=[1440, 768], decomposed=0, set_colors=256, $
        z_buffering=0

PLOT, scandx, scan,				$
      background=255, color=0, charsize=1.0,	$
      title = 'Theta Scan ' + fits_file + ' ' + srad + ' Rsun',	$
      xtitle = 'Position Angle',		$
      ytitle = ylab, yrange = [ymin, ymax]


img_disp = TVRD ()
WRITE_GIF, gif_file, img_disp
DEVICE, /close

;--------------------------------------
; Plot theta scan to a postscript file.
;--------------------------------------

ps_file  = basename + '_r' + srad + '_plot.ps'
print, 'ps_file: ', ps_file
SET_PLOT, 'PS'
DEVICE, filename=ps_file

PLOT, scandx, scan,				$
      title = 'Theta Scan ' + fits_file + ' ' + srad + ' Rsun',		$
      xtitle = 'Position Angle',		$
      ytitle = ylab,		$
      yrange = [ymin, ymax]

DEVICE, /close

SET_PLOT, 'X'

end
