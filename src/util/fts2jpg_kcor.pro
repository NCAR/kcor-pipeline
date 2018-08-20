;+
;-------------------------------------------------------------------------------
; NAME		fts2jpg_kcor.pro
;-------------------------------------------------------------------------------
; PURPOSE	Convert a sequence of kcor FITS images to JPEG format.
;-------------------------------------------------------------------------------
; SYNTAX
; fts2jpg_kcor, fits_list, cm='colormap.lut', wmin=0, wmax=5e-9
;
;	fits_list	list of filenames of SMM C/P FITS images.
;	gif		write displayed image as a GIF file.
;	cm		pathname of ASCII colormap file.
;			Each line has the syntax: index red green blue
;			where index = 0, 1, 2, ... 255,
;			and red/green/blue are in the range [0:255].
;	wmin		display minimum value.
;	wmax		display maximum value.
;	wexp		exponent for scaling image.
;	ov		display image with overlay graphics.
;			(solar north, angular points).
;	annotate	display image with FITS parameter annotation in sidebar.
;	label		Write annotation into corners of image.
;
; NOTE: The default is to display the image with the overlay graphics
;       and with FITS annotation (same as /ov /annotate).
;-------------------------------------------------------------------------------
; EXAMPLES
; fts2jpg_kcor, fits_list
; fts2jpg_kcor, fits_list, cm='/home/stanger/color/bwy.lut'
; fts2jpg_kcor, fits_list, wmax=1.e-9
; fts2jpg_kcor, fits_list, /ov
; fts2jpg_kcor, fits_list, /ov, /annotate
;
; ov:		 JPEG file name: basename.ov.jpg
; annotate:	 JPEG file name: basename.an.jpg
; ov + annotate: JPEG file name: basename.oa.jpg
; label:	 Label image in corners & draw polar grid in occulter region.
;		 JPEG file name: basename.pg..jpg
;-------------------------------------------------------------------------------
; EXTERNAL PROCEDURES
; fits_annotate_kcor.pro
; overlay_kcor.pro
; north_kcor.pro
; sundot_kcor.pro
; sunray_kcor.pro
;-------------------------------------------------------------------------------
; HISTORY	Andrew L. Stanger   HAO/NCAR   19 January 2006
; 15 Nov 2006 Add ov and annotate options.
; 09 Jun 2015 Adapt for use with kcor images.
; 17 Jun 2015 Modify to use DISPMIN, DISPMAX, DISPEXP (for nrgf fits files).
; 18 Jun 2015 Add label keyword.
; 15 Jul 2015 Add /NOSCALE keyword to readfits.
;-------------------------------------------------------------------------------
;-

PRO fts2jpg_kcor, fits_list, cm=cm, wmin=wmin, wmax=wmax, wexp=wexp, gif=gif, $
		  ov=ov, annotate=annotate, label=label

  fits_name = 'img.fts'

  black  =   0
  white  = 255
  red    = 254
  green  = 253
  blue   = 252
  grey   = 251
  yellow = 250

  ;----------------
  ; Load color map.
  ;----------------

  IF (KEYWORD_SET (cm))  THEN	$
    lct, cm			$
  ELSE				$
    lct, '/hao/acos/sw/colortable/quallab.lut'   ; Load default color table.

  ;--------------------------------------------------------------------
  ; If label keyword is set, then disable overlay and annotate options.
  ;--------------------------------------------------------------------

  IF (KEYWORD_SET (label)) THEN $
  BEGIN ;{
    ov       = 0
    annotate = 0
  END   ;}

  ;-----------------------------------------
  ; Create storage for color look-up tables.
  ;-----------------------------------------

  rtab = BYTARR (256)
  gtab = BYTARR (256)
  btab = BYTARR (256)
  TVLCT, rtab, gtab, btab, /GET		; Fetch RGB color look-up tables.

  month_name = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',	$
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

  ;-------------------------
  ; Set character font size.
  ;-------------------------

  cwidth = 8
  cheight = FIX ((cwidth * 1.5) + 0.5)

  ;------------------------------------------
  ; Define annotation borders: left & bottom.
  ;------------------------------------------

  IF (KEYWORD_SET (annotate))  THEN	$
      BEGIN
      xb = 152				; Left border width
      xb = 200				; Left border width
      yb =  64				; Bottom border height
      yb =  80				; Bottom border height
      END				$
  ELSE					$
     BEGIN
     xb = 0				; Left border width
     yb = 0				; Bottom border width
     END

  ;-----------------------------------
  ; Read first image in file list.
  ; Set the default output image size.
  ;-----------------------------------

  CLOSE, 1
  OPENR, 1, fits_list
     READF, 1, fits_name
     fits_img  = readfits (fits_name, hdu, /NOSCALE, /SILENT)
     xdim      = fxpar (hdu, 'NAXIS1')
     ydim      = fxpar (hdu, 'NAXIS2')
     oxdim     = xdim + xb
     oydim     = ydim + yb
     xdim_prev = xdim
     ydim_prev = ydim
  CLOSE, 1

  xdim_prev = 0
  ydim_prev = 0

  ;*****************************************************************************
  ; File list loop.
  ;*****************************************************************************

  OPENR, 1, fits_list
  WHILE (NOT EOF (1)) DO	$
  BEGIN ;{
    READF, 1, fits_name				; Get file name from list.

    ;----------------------------------------------
    ; Extract "base name" for optional output file.
    ;----------------------------------------------

    ftspos   = STRPOS (fits_name, '.fts')
    basename = STRMID (fits_name, 0, ftspos)
;    print, 'basename: ', basename

    ;-------------------------------------
    ; Read FITS image header & pixel data.
    ;-------------------------------------

    hdu = headfits (fits_name)
    img = readfits (fits_name, /NOSCALE, /SILENT)

    imin = MIN (img, max=imax)
    print, 'fts2jpg_kcor imin/imax: ', imin, imax

    ;----------------------------------
    ; Get information from FITS header.
    ;----------------------------------

    xdim     = fxpar (hdu, 'NAXIS1')
    ydim     = fxpar (hdu, 'NAXIS2')
    dateobs  = fxpar (hdu, 'DATE-OBS')
;    timeobs  = fxpar (hdu, 'TIME-OBS')
;    type_obs = fxpar (hdu, 'TYPE-OBS')
    location = fxpar (hdu, 'LOCATION')
    origin   = fxpar (hdu, 'ORIGIN')
    telescop = fxpar (hdu, 'TELESCOP')
    instrume = fxpar (hdu, 'INSTRUME')
    object   = fxpar (hdu, 'OBJECT')
    datatype = fxpar (hdu, 'DATATYPE', count=qdatatype)
    level    = fxpar (hdu, 'LEVEL')

    bscale   = fxpar (hdu, 'BSCALE')
    xcen     = fxpar (hdu, 'CRPIX1') - 1.0	; IDL origin = 1, not 0.
    ycen     = fxpar (hdu, 'CRPIX2') - 1.0	; IDL origin = 1, not 0.
    cdelt1   = fxpar (hdu, 'CDELT1',   count=qcdelt1)

    print, 'level: ', level
    print, 'datatype;  ', datatype
    print, 'qdatatype: ', qdatatype
    fimg = float (img)
    fmin = MIN (fimg, max=fmax)
    print, 'fts2jpg_kcor fmin/fmax: ', fmin, fmax

    datamin = fmin			; image min.
    datamax = fmax			; image max.

    dispmin   = 0.0
    dispmax   = 1.2
    dispexp   = 0.7
    dexp      = dispexp
    cbias     = 0.0

    datamin  = fxpar (hdu, 'DATAMIN', count=cdatamin)
    datamax  = fxpar (hdu, 'DATAMAX', count=cdatamax)

    dispmin  = fxpar (hdu, 'DISPMIN', count=cdispmin)
    dispmax  = fxpar (hdu, 'DISPMAX', count=cdispmax)
    dispexp  = fxpar (hdu, 'DISPEXP', count=cdispexp)

    rsun     = fxpar (hdu, 'RSUN_OBS', count=qrsun)
    if (qrsun eq 0L) then rsun = fxpar (hdu, 'RSUN', count=qrsun)

    solar_p0 = fxpar (hdu, 'SOLAR_P0')		; p-angle
    crlt_obs = fxpar (hdu, 'CRLT_OBS')		; b-angle
    crln_obs = fxpar (hdu, 'CRLN_OBS')		; l-angle

    occltrid = fxpar (hdu, 'OCCLTRID', count=qoccltrid)

    date_obs = strmid (dateobs, 0, 10)
    time_obs = strmid (dateobs, 11, 8)
    datatype = strtrim (datatype, 2)

    ;---------------------------------------------------------------------------
    ; NOTE: kcorl1r.pro stores corona * 1000 in FITS files.
    ;---------------------------------------------------------------------------
    ; The bscale value ought to be 0.001 in the FITS header.
    ; However, it is erroneously set to 1.0 instead.
    ; Therefore, the logic below restores the original values of the pixels.
    ;---------------------------------------------------------------------------

    print, 'bscale: ', bscale

    if (bscale EQ 1.0 OR bscale EQ 0.001) then $
      fimg = float (img) * 0.001   ; kcorl1r.pro stores corona*1000 in fits

    ;---------------------------------------------------
    ; Determine occulter size (arcsec).
    ;---------------------------------------------------
    ; occltrid: 'OC-xxx.x' or 'OC-xxxx.x'.
    ; kcor occulter sizes: 991.6, 1006.9, 1018.9 arcsec.
    ;---------------------------------------------------

    occulter = strmid (occltrid, 3, 5)
    occulter = float (occulter)
    IF (occulter eq 1018.0) THEN occulter = 1018.9
    IF (occulter eq 1006.0) THEN occulter = 1006.9

    radius_occ = occulter / cdelt1	; pixels / occulter radius
    pixrs      = rsun / cdelt1		; pixels/Rsun

    cneg = FIX (xcen - pixrs)		; pixel distance at Rsun left  of center
    cpos = FIX (xcen + pixrs)		; pixel distance ar Rsun right of center
    
    print, 'cneg/cpos: ', cneg, cpos

    ;-------------------------
    ; Output image dimensions.
    ;-------------------------

    oxdim = xdim + xb
    oydim = ydim + yb

    ;-------------------------------------------
    ; Resize window [if image size has changed].
    ;-------------------------------------------

;    SET_PLOT, 'X'
;    window, xs=10, ys=10

;    if (xdim NE xdim_prev OR ydim NE ydim_prev)  THEN	$
;        WINDOW, xsize=oxdim, ys=oydim, RETAIN=2

    SET_PLOT, 'Z'
    DEVICE, set_resolution = [oxdim, oydim], set_colors=256, z_buffering = 0
    DEVICE, SET_CHARACTER_SIZE = [cwidth, cheight]	; Set character size.

;    print, 'oxdim/oydim: ', oxdim, oydim

    xdim_prev = xdim
    ydim_prev = ydim

    print, 'datamin/max: ', datamin, datamax
    print, 'dispmin/max: ', dispmin, dispmax
    print, 'datatype: ', datatype

    if (datatype EQ 'science' OR qdatatype EQ 0) then $
    begin ;{
      dispmin = 0.0			; display min.
      dispmax = 1.2			; display max.
      dexp    = 0.7			; display exponent.
      cbias   = 0.2			; corona bias value.
    end   ;}

    print, 'dispmin/max, dexp, cbias: ', dispmin, dispmax, dexp, cbias

    ;------------------------------
    ; "Erase" left annotation area.
    ;------------------------------

    IF (KEYWORD_SET (annotate))  THEN	$
    BEGIN
        winleft = BYTARR (xb, ydim)
        winleft [*, *] = white
        TV, winleft, 0, yb
    END

    ;--------------------------------
    ; "Erase" bottom annotation area.
    ;--------------------------------

    IF (KEYWORD_SET (annotate))  THEN	$
    BEGIN
        winbottom = BYTARR (xb + xdim, yb)
        winbottom [*, *] = white
        TV, winbottom, 0, 0
    END

    ;-----------------------------------------------
    ; Determine min/max intensity levels to display.
    ;-----------------------------------------------

    dmin = datamin
    dmax = datamax

    IF (dispmin NE dispmax) THEN		$
    BEGIN
      dmin = dispmin
      dmax = dispmax
    END

    print, 'cdispexp: ', cdispexp
    IF (cdispexp GT 0) THEN dexp = dispexp

    IF (KEYWORD_SET (wmin))  THEN dmin = wmin
    IF (KEYWORD_SET (wmax))  THEN dmax = wmax
    IF (KEYWORD_SET (wexp))  THEN dexp = wexp

    print, 'fts2jpg_kcor dmin/dmax/dexp: ', dmin, dmax, dexp

    ;--------------------------------
    ; Fill occulting disk with black.
    ;--------------------------------

;    circfill, simg, xdim, ydim, xcen, ycen, radius_occ, black

    ;-------------------------------
    ; Use mask to build final image.
    ;-------------------------------

    xx1    = findgen (xdim, ydim) mod (xdim) - xcen
    yy1    = transpose (findgen (ydim, xdim) mod (ydim) ) - ycen 

    xx1    = double (xx1)
    yy1    = double (yy1)
    rad1   = sqrt ( xx1^2.0 + yy1^2.0 )

    r_in = radius_occ + 5.0
    r_out = 504.0

    bad = where (rad1 LT r_in OR rad1 GE r_out)
;    fimg (bad) = 0

    cbias = 0.01
    cbias = 0.02
    corona_bias = fimg + cbias
    corona_bias (bad) = 0

    ;---------------
    ; Display image.
    ;---------------

    if (dexp EQ 1.0) THEN $
       simg = bytscl (fimg, min=dmin, max=dmax, top=249) $
    else $
       simg = bytscl (corona_bias^dexp, min=dmin, max=dmax, top=249)

;    simg = bytscl (corona_cbias^dexp, top=249)

    smin = MIN (simg, max=smax)
    print, 'fts2jpg_kcor smin/smax: ', smin, smax

;    TV, BYTSCL (img, min=dispmin, max=dispmax, top=249), xb, yb

;    simg (bad) = 255		; To produce a while occulter & outer FOV.
    TV, simg, xb, yb

    ;------------------------
    ; Draw overlays on image.
    ;------------------------

    IF (KEYWORD_SET (ov))  THEN	$
	overlay_kcor, hdu, xdim, ydim, xb, yb, wmin=dmin, wmax=dmax

    ;----------------
    ; Annotate image.
    ;----------------

    IF (KEYWORD_SET (annotate))  THEN	$    
    BEGIN ;{
      print, 'fts2jpg_kcor dmin/dmax: ', dmin, dmax
      fits_annotate_kcor, hdu, xdim, ydim, xb, yb, dmin, dmax, dexp
    END   ;}

    ;-------------
    ; Label image.
    ;-------------

    if (KEYWORD_SET (label)) THEN $
    BEGIN ;{
      year  = strmid (dateobs, 0, 4)
      month = strmid (dateobs, 5, 2)
      day   = strmid (dateobs, 8, 2)

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

      date_dmy = day + ' ' + name_month + ' ' + year
      print, 'date_dmy: ', date_dmy

      ;--- Determine DOY.

      mday      = [0,31,59,90,120,151,181,212,243,273,304,334]
      mday_leap = [0,31,60,91,121,152,182,213,244,274,305,335] ;leap year

      IF ((fix (year) mod 4) EQ 0) THEN $
        doy = (mday_leap (fix (month) - 1) + fix (day))$
      ELSE $
        doy = (mday (fix (month) - 1) + fix (day))

      kcor_label_hires, date_dmy, doy, time_obs, datatype, $
                        xdim, ydim, xcen, ycen, pixrs, $
                        dmin, dmax, dexp, cneg, cpos
    END   ;}

    ;-----------------------------------
    ; Create JPEG image [24 bits/pixel].
    ;-----------------------------------

    tvimg = TVRD ()
    jpg_img = BYTARR (3, oxdim, oydim)
    jpg_img [0, *, *] = rtab [tvimg [*, *]]
    jpg_img [1, *, *] = gtab [tvimg [*, *]]
    jpg_img [2, *, *] = btab [tvimg [*, *]]

    ;-------------------------------------
    ; Write displayed image as a JPG file.
    ;-------------------------------------

    IF (KEYWORD_SET (ov))  THEN		$
        jpg_file = basename + '.ov.jpg'
 
    IF (KEYWORD_SET (annotate)) THEN	$
	jpg_file = basename + '.an.jpg'

    IF (KEYWORD_SET (label)) THEN	$
	jpg_file = basename + '.pg.jpg'

    IF (KEYWORD_SET (annotate) AND KEYWORD_SET (ov)) THEN	$
	jpg_file = basename + '.oa.jpg'

    IF (NOT KEYWORD_SET (annotate) AND NOT KEYWORD_SET (ov) AND $
        NOT KEYWORD_SET (label)) THEN	$
	jpg_file = basename + '.im.jpg'

    WRITE_JPEG, jpg_file, jpg_img, true=1, quality=100	; Write jpg file.
    PRINT, fits_name, ' ---> ', jpg_file

    ;---------------------------------------------------------------------------
    ; Write GIF image.
    ;-----------------

    IF (KEYWORD_SET (gif)) THEN		$
    BEGIN
      IF (KEYWORD_SET (ov))  THEN	$
        gif_file = basename + '.ov.gif'

      IF (KEYWORD_SET (annotate)) THEN	$
	gif_file = basename + '.an.gif'	

      IF (KEYWORD_SET (label)) THEN	$
	gif_file = basename + '.pg.gif'	

      IF (KEYWORD_SET (annotate) AND KEYWORD_SET (ov)) THEN	$
	gif_file = basename + '.oa.gif'

      IF (NOT KEYWORD_SET (annotate) AND NOT KEYWORD_SET (ov) AND $
          NOT KEYWORD_SET (label)) THEN	$
	gif_file = basename + '.im.gif'

      WRITE_GIF, gif_file, tvimg, rtab, gtab, btab
      PRINT, fits_name, ' ---> ', gif_file
    END
    ;---------------------------------------------------------------------------

  END   ;}
  ;*****************************************************************************
  ; End of FITS file loop.
  ;*****************************************************************************

END

