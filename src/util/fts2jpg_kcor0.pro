;+
; NAME	fts2jpg_kcor0.pro
;
; PURPOSE	Convert FITS images to JPEG format.
;		Default output resolution is 960x960 pixels.
;		Default color map is "quallab.lut".
;
; SYNTAX	fts2jpg_kcor0, fits_list
;		fts2jpg_kcor0, fits_list, color_lut, wmin=0, wmax=100, /label
;		fts2jpg_kcor0, fits_list, /grid
;		fts2jpg_kcor0, fits_list, size=512
;
;		fits_list: file containing a list of FITS images.
;		color_lut: file containing an ASCII color map [index, r, g, b]
;		wmin/wmax: min/max scaling range (maps to [0 --> 249])
;		label:     annotate image
;		grid:      draw a polar grid inside the occulting dis.
;
; PROCEDURES	lct		Load color table
;		suncir_mk4	Draw sun circle polar coordinate grid.
;		readfits	Read FITS image.
;		fxpar		Read a FITS keyword parameter.
;
; HISTORY	Andrew L. Stanger   HAO/NCAR   30 January 2001
; 28 Feb 2002: add wmin & wmax.
; 30 Apr 2003: add label keyword.
; 11 Feb 2004: Use congrid to resize input image to 512x512.
; 23 Nov 2004: add grid keyword; add size keyword.
;  6 Dec 2004: also draw the grid for mk3 images.
; 21 May 2015: kcor version derived from fts2jpg_mk4.pro.
; 15 Jun 2015: renamed to fts2jpg_kcor0.pro, to avoid conflict with the 
;              fancier version: "fts2jpg_kcor.pro".
;-

pro fts2jpg_kcor0, fits_list, color_lut, wmin=wmin, wmax=wmax,		$
				       label=label, grid=grid, size=size

; --- Set character font size.

cwidth  = 8
cheight = FIX ((cwidth * 1.5) + 0.5)

set_plot, 'X'
WINDOW, xsize=10, ysize=10
WDELETE, !d.window
DEVICE, SET_CHARACTER_SIZE = [cwidth, cheight]		; set character size.

month_name = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', $
	      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
CLOSE, 1
fits_name = ''
xdim_prev = 0
ydim_prev = 0
oxdim = 960			; Output x dimension
oydim = 960			; Output y dimension
mag   = 1.0
datamin = 0.0
datamax = 0.0
dispmin = 0.0
dsipmax = 0.0

; white  = 255
; red    = 254
; green  = 253
; blue   = 252
; grey   = 251
; yellow = 250
; black  =   0

red   = bindgen (256)
green = bindgen (256)
blue  = bindgen (256)

;--- Read first image in file list.
;--- Set the default output image size.

OPENR, 1, fits_list
   READF, 1, fits_name				; Get file name.
   fits_img  = readfits (fits_name, hdu)
   xdim      = fxpar (hdu, 'NAXIS1')
   ydim      = fxpar (hdu, 'NAXIS2')
   oxdim     = xdim
   oydim     = ydim
   xdim_prev = xdim
   ydim_prev = ydim
CLOSE, 1

IF (N_ELEMENTS (size) GT 0)  THEN	$
BEGIN ;{
   mag = float (size) / float (xdim)
   oxdim = size
   oydim = size
   print, 'oxdim/oydim: ', oxdim, oydim
   print, 'mag: ', mag
END   ;}

;SET_PLOT, 'Z'
;DEVICE, set_resolution = [oxdim, oydim], set_colors = 256, z_buffering = 0
;DEVICE, SET_CHARACTER_SIZE = [cwidth, cheight]		; set character size.

if (N_ELEMENTS (color_lut) GT 0) THEN	$
    lct, color_lut			$
ELSE					$
    lct,'/home/cordyn/color/quallab.lut'	; color table.

tvlct, red, green, blue, /get

;--- File list loop.

OPENR, 1, fits_list
WHILE (NOT EOF (1)) DO	$
BEGIN	;{

   ;--- Read FITS image header & pixel data.

   READF, 1, fits_name				; Get file name.
   print, 'FITS image: ', fits_name

   fits_img = readfits (fits_name, hdu, /noscale)

   ;--- Extract information from header.

   dispmin = MIN (fits_img, max=dispmax)
   roll = 0.0

   xdim     = fxpar (hdu, 'NAXIS1')
   ydim     = fxpar (hdu, 'NAXIS2')
   crpix1   = fxpar (hdu, 'CRPIX1') - 1		; IDL index origin = 0
   crpix2   = fxpar (hdu, 'CRPIX2') - 1		; IDL index origin = 0
   cdelt1   = fxpar (hdu, 'CDELT1')
   rsun     = fxpar (hdu, 'RSUN_OBS', count=qrsun)
   if (qrsun eq 0L) then rsun = fxpar (hdu, 'RSUN', count=qrsun)

;   roll     = fxpar (hdu, 'CROTA1')
   roll     = fxpar (hdu, 'INST_ROLL')
   origin   = fxpar (hdu, 'ORIGIN')
   telescop = fxpar (hdu, 'TELESCOP')
   date     = fxpar (hdu, 'DATE-OBS')	; yyyy-mm-ddThh:mm:ss
;   time     = fxpar (hdu, 'TIME-OBS')
   object   = fxpar (hdu, 'OBJECT')
;   type_obs = fxpar (hdu, 'TYPE-OBS')
;   dataform = fxpar (hdu, 'DATAFORM')
;   coordnam = fxpar (hdu, 'COORDNAM')
;   crradius = fxpar (hdu, 'CRRADIUS')
   bscale   = fxpar (hdu, 'BSCALE')
   bzero    = fxpar (hdu, 'BZERO')
   bunit    = fxpar (hdu, 'BUNIT')
;   datamin  = fxpar (hdu, 'DATAMIN')
;   datamax  = fxpar (hdu, 'DATAMAX')
;   dispmin  = fxpar (hdu, 'DISPMIN')
;   dispmax  = fxpar (hdu, 'DISPMAX')

   print, 'bscale/bzero: ', bscale, bzero

   type_obs = 'pB'
   coordnam = 'heliocentric'
   dataform = 'cartesian'
;   dataform = STRTRIM (STRLOWCASE (dataform), 2)
   dataform5 = STRMID (dataform, 0, 5)

   telescop = STRTRIM (telescop, 2)

;   pixrs = crradius
   pixrs = rsun / cdelt1	; pixels/Rsun.
   xcen  = crpix1
   ycen  = crpix2

   print, 'pixrs, xcen, ycen: ', pixrs, xcen, ycen

   year  = STRMID (date, 0, 4)
   month = STRMID (date, 5, 2)
   day   = STRMID (date, 8, 2)
   iyear = FIX (year)
   syear = STRTRIM (STRING (iyear), 2)
   iday  = FIX (day)
   sday  = STRTRIM (STRING (iday), 2)
   IF (iday LT 10)  THEN sday = ' ' + sday
   imonth = FIX (month)
   smonth = month_name [imonth - 1]
   smonth = STRUPCASE (smonth)
   smonth = STRTRIM (smonth, 2)
   sdate  = sday + ' ' +  smonth + ' ' + syear
;   sdate  = STRTRIM (sdate, 2)

   time  = STRMID (date, 11, 8)		; hh:mm:ss
   stime = time + ' UT'

   doy = day_of_year (iyear, imonth, iday)

   ;--- Set display minimum intensity.

   IF (N_ELEMENTS (wmin) GT 0) THEN	$
       imin = wmin			$
   ELSE					$
   BEGIN
       IF (dispmin LT 0.0) THEN						$
	   imin = FLOAT (FIX ((dispmin - bzero) / bscale - 0.5))	$
       ELSE								$
	   imin = FLOAT (FIX ((dispmin - bzero) / bscale + 0.5))
   END

   ;--- Set display maximum intensity.

   IF (N_ELEMENTS (wmax) GT 0) THEN	$
       imax = wmax			$
   ELSE					$
   BEGIN
       IF (dispmax LT 0.0) THEN						$
           imax = FLOAT (FIX ((dispmax - bzero) / bscale - 0.5))	$
       ELSE								$
           imax = FLOAT (FIX ((dispmax - bzero) / bscale + 0.5))
   END

;   dispmin = -1000
;   dispmax =  5000
;   print, FORMAT = '("dispmin/max: ", E10.3, E10.3)', dispmin, dispmax

   print, 'datamin/datamax: ', datamin, datamax
   print, 'dispmin/dispmax: ', dispmin, dispmax
   print, 'imin/imax:       ', imin, imax

   ;--- Perform intensity scaling.

;   fits_img = fits_img * bscale + bzero

   ;--- Determine output image magnification.

   IF (N_ELEMENTS (size) GT 0)  THEN	$
   BEGIN ;{
      mag = float (size) / float (xdim)
      oxdim = size
      oydim = size
      print, 'oxdim/oydim: ', oxdim, oydim
      print, 'mag: ', mag
   END   ;}

   ;--- Convert to byte pixels.

;   IF (xdim NE xdim_prev OR ydim NE ydim_prev) THEN	$
;      WINDOW, xsize=xdim, ysize=ydim

   IF (xdim NE xdim_prev OR ydim NE ydim_prev) THEN	$
   BEGIN
      print, 'All images in the file list MUST be the same size [xdim, ydim]'
      GOTO, done
   END

   byt_img = BYTSCL  (fits_img, min=imin, max=imax, top=249)

   ;--- Resize image (if needed). 

   IF (xdim NE oxdim) THEN 				$
   BEGIN						$
      tv_img  = CONGRID (byt_img, oxdim, oydim)		
      pixrs = pixrs * mag
      xcen  = crpix1   * mag
      ycen  = crpix2   * mag
   END							$
   ELSE							$
      tv_img = byt_img

   ;--- Display image.

   SET_PLOT, 'Z'
   DEVICE, set_resolution = [oxdim, oydim], set_colors = 256, z_buffering = 0
   DEVICE, SET_CHARACTER_SIZE = [cwidth, cheight]	; set character size.

   TV, tv_img

;   print, 'xdim/ydim: ', xdim, ydim

   ;--- Label image.

;   IF (KEYWORD_SET (label)) THEN	$
;   BEGIN ;{
;      IF (mag LT 0.45) THEN		$
;         cs = 0.8			$
;      ELSE				$
;      IF (mag LT 0.8) THEN		$
;	 cs = 1.0			$
;      ELSE				$
;         cs = 1.2

   IF (KEYWORD_SET (label)) THEN	$
   BEGIN ;{
      IF (oxdim LT 432) THEN		$
         cs = 0.8			$
      ELSE				$
      IF (oxdim LT 768) THEN		$
	 cs = 1.0			$
      ELSE				$
         cs = 1.2

      lm = FIX (cwidth * cs)

      print, 'oxdim: ', oxdim, ' mag: ', mag, ' cs: ', cs

;      IF (!version.os EQ 'IRIX')  THEN cs = 0.7
;      IF (!version.os EQ 'sunos') THEN cs = 0.7
;      IF (!version.os EQ 'linux') THEN cs = 0.7

      sorigin    = STRTRIM (origin, 2)
      stelescop  = STRTRIM (telescop, 2)
      stype_obs  = STRTRIM (type_obs, 2)
      sbunit     = STRTRIM (bunit, 2)
      sobject    = STRTRIM (object, 2)
      scoordnam  = STRTRIM (coordnam, 2)

      stelescop = STRUPCASE (stelescop)
      sobject   = STRUPCASE (sobject)

      stitle = sorigin + ' ' + stelescop + ' ' + stype_obs 
      stitle = 'MLSO ' + stelescop + ' ' + sbunit
      stitle = 'MLSO ' + stelescop + ' ' + stype_obs
      stitle = 'MLSO ' + stelescop + ' ' + sobject
      stitle = 'MLSO ' + stelescop 

      sobs  = sobject + ' ' + stype_obs

      clen_coord = STRLEN (scoordnam)
      clen_obs   = STRLEN (sobs)

      print, 'stitle: ', stitle
      print, 'clen_coord: ', clen_coord, ' lm: ', lm, clen_coord * lm
      print, 'clen_obs  : ', clen_obs,   ' lm: ', lm, clen_obs   * lm

      sdoy  = STRTRIM (STRING (doy), 2)
      IF (doy LT 100) THEN sdoy = ' ' + sdoy
      IF (doy LT 10)  THEN sdoy = ' ' + sdoy
      labeldoy = 'DOY: ' + sdoy

      swmin = STRTRIM (STRING (imin), 2)
      swmax = STRTRIM (STRING (imax), 2)
      sscale = 'Scaling: ' + swmin + ' to ' + swmax

;      IF (imin LT 0.0) THEN	$
;	 dmin = FLOAT (FIX ((imin - bzero) / bscale - 0.5))	$
;      ELSE							$
;	 dmin = FLOAT (FIX ((imin - bzero) / bscale + 0.5))
;      dmax = FLOAT (FIX ((imax - bzero) / bscale + 0.5))

;      dmin = imin * bscale + bzero
;      dmax = imax * bscale + bzero

      dmin = imin
      dmax = imax

      print, 'dmin/dmax:       ', dmin, dmax

;      sdmin = STRTRIM (STRING (dmin, FORMAT='(G9.2)'), 2)
;      sdmax = STRTRIM (STRING (dmax, FORMAT='(G9.2)'), 2)
;      sdmin = STRING (dmin, FORMAT='(F9.2)')
;      sdmax = STRING (dmax, FORMAT='(F9.2)')

      sdmin = STRTRIM (STRING (dmin, FORMAT='(F9.2)'), 2)
      sdmax = STRTRIM (STRING (dmax, FORMAT='(F9.2)'), 2)
      sdmin = 'MIN: ' + sdmin
      sdmax = 'MAX: ' + sdmax

      y1 = FIX ((cheight * cs) + 0.5) + 4
      y2 = y1 * 2
      y3 = y1 * 3
      y4 = y1 * 4


      XYOUTS, 3,           oydim - y1, stitle, 	 /device, charsize=cs, color=255
      XYOUTS, 3,           oydim - y2, sdate,	 /device, charsize=cs, color=255
      XYOUTS, 3,           oydim - y3, stime,	 /device, charsize=cs, color=255
      XYOUTS, 3,           oydim - y4, labeldoy, /device, charsize=cs, color=255
      XYOUTS, oxdim - (clen_obs+1)*lm*cs, oydim - y1, sobs, $
              /device, charsize=cs, color=255

;      XYOUTS, 3,           4,         sscale,	 /device, charsize=cs, color=255
      XYOUTS, 3,           y2+4,      stype_obs, /device, charsize=cs, color=255
      XYOUTS, 3,           y1+4,       sdmin,    /device, charsize=cs, color=255
      XYOUTS, 3,            4,         sdmax,    /device, charsize=cs, color=255

;     XYOUTS, oxdim/2 - 7, oydim   -20, 'N',     /device, charsize=cs, color=255
;     XYOUTS,  7,          oydim/2 - 7, 'E',     /device, charsize=cs, color=255
;     XYOUTS, oxdim/2 - 7, 10,          'S',     /device, charsize=cs, color=255
;     XYOUTS, oxdim   -20, oydim/2 - 7, 'W',     /device, charsize=cs, color=255
;     XYOUTS, oxdim   -19, 24,          '^',   /device, charsize=cs*2, color=255
;     XYOUTS, oxdim   -18, 18,          '|',     /device, charsize=cs, color=255
;     XYOUTS, oxdim   -20,  4,          'N',     /device, charsize=cs, color=255

      XYOUTS, oxdim - (clen_coord+1)*lm, 4, scoordnam, $
              /device, charsize=cs, color=255
   END  ;}

   telescop = STRLOWCASE (telescop)
;   IF (KEYWORD_SET (grid) AND (telescop EQ 'mk4' OR telescop EQ 'mk3') $
   IF (KEYWORD_SET (grid) $
       AND dataform5 EQ 'carte') THEN $
   BEGIN ;{
      xb = 0
      yb = 0
      kcor_suncir, oxdim, oydim, xcen, ycen, xb, yb, pixrs, roll
   END   ;}

   byt_img = TVRD ()

   ;--- Create JPEG image [24-bits/pixel].

   jpg_img = BYTARR (3, oxdim, oydim)
   jpg_img [0, *, *] = red   [byt_img [*, *]]
   jpg_img [1, *, *] = green [byt_img [*, *]]
   jpg_img [2, *, *] = blue  [byt_img [*, *]]

   ;--- Write jpeg image to disk.

   sloc     = RSTRPOS (fits_name, '.fts')
   jpg_name = STRMID  (fits_name, 0, sloc) + '.jpg'
   print, 'JPEG image : ', jpg_name
   WRITE_JPEG, jpg_name, jpg_img, true=1, quality=75	; Write new image.
   xdim_prev = xdim
   ydim_prev = ydim
END	;}

done:
SET_PLOT, 'X'
CLOSE, 1
END
