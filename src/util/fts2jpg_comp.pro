;+
;-------------------------------------------------------------------------------
; NAME		fts2jpg_comp.pro
;-------------------------------------------------------------------------------
; PURPOSE	Convert a sequence of kcor FITS images to JPEG format.
;-------------------------------------------------------------------------------
; SYNTAX
; fts2jpg_comp, fits_list, cm='colormap.lut', wmin=0, wmax=5e-9
;
;	fits_list	list of filenames of CoMP FITS images.
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
; fts2jpg_comp, fits_list
; fts2jpg_comp, fits_list, cm='/home/stanger/color/bwy.lut'
; fts2jpg_comp, fits_list, wmax=1.e-9
; fts2jpg_comp, fits_list, /ov
; fts2jpg_comp, fits_list, /ov, /annotate
;
; ov:              JPEG file name: basename.ov.jpg
; annotate:        JPEG file name: basename.an.jpg
; ov and annotate: JPEG file name: basename.oa.jpg
;-------------------------------------------------------------------------------
; EXTERNAL PROCEDURES
; fits_annotate_comp.pro
; overlay_comp.pro
; north_kcor.pro
; sundot_kcor.pro
; sunray_kcor.pro
;-------------------------------------------------------------------------------
; AUTHOR	Andrew L. Stanger   HAO/NCAR
; HISTORY
; 19 January 2006 IDL procedure created.
; 15 Nov 2006 Add ov and annotate options.
; 09 Jun 2015 Adapt for use with kcor images.
; 16 Jun 2015 Adapt for use with comp images.
; 17 Jun 2015 Remove overlay_comp parameters hdu, wmin, wmax.  
;             Add xcen, ycen, pixrs, pangle.
;             fits_annotate_comp: add hduext parameter.
; 29 Jun 2015 Add label keyword.
;-------------------------------------------------------------------------------
;-

PRO fts2jpg_comp, fits_list, cm=cm, wmin=wmin, wmax=wmax, wexp=wexp, gif=gif, $
		  ov=ov, annotate=annotate, label=label

  fits_name = ''
  black =   0
  white = 255

  ;----------------
  ; Load color map.
  ;----------------

  IF (KEYWORD_SET (cm))  THEN	$
       lct, cm			$
  ELSE				$
       lct, '/home/stanger/color/redtemp1.lut'	; Load default color table.
;       lct, '/home/stanger/color/quallab.lut'	; Load default color table.
;  loadct, 3

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
     hdu  = headfits (fits_name)			 ; read primary header.
     fits_img = readfits (fits_name, hduext, exten_no=3) ; read ext 3 hdu + img.
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

    hdu  = headfits (fits_name)				; read primary header.
    fimg = readfits (fits_name, hduext, exten_no=3)	; read ext 3 hdu + img.

    ;----------------------------------
    ; Get information from FITS header.
    ;----------------------------------

    ;--- primary header :

;    type_obs = fxpar (hdu, 'TYPE-OBS', count=qtype_obs)

    telescop = fxpar (hdu, 'TELESCOP')
    instrume = fxpar (hdu, 'INSTRUME')
    date_obs = fxpar (hdu, 'DATE-OBS')
    time_obs = fxpar (hdu, 'TIME-OBS')
    location = fxpar (hdu, 'LOCATION')
    object   = fxpar (hdu, 'OBJECT')
    ntune    = fxpar (hdu, 'NTUNE')
    cover    = fxpar (hdu, 'COVER')
    polangle = fxpar (hdu, 'POLANGLE')
    polarizr = fxpar (hdu, 'POLARIZR')
    opal     = fxpar (hdu, 'OPAL')
    retarder = fxpar (hdu, 'RETARDER')
    level    = fxpar (hdu, 'LEVEL')

    xcen     = fxpar (hdu, 'CRPIX1') - 1.0	; IDL origin = 1, not 0.
    ycen     = fxpar (hdu, 'CRPIX2') - 1.0	; IDL origin = 1, not 0.
    cdelt1   = fxpar (hdu, 'CDELT1',   count=qcdelt1)
    crota1   = fxpar (hdu, 'CROTA1',   count=qcrota1)
    occ_size = fxpar (hdu, 'OCC-SIZE', count=qocc_size)
    rsun     = fxpar (hdu, 'RSUN_OBS', count=qrsun)
    if (qrsun eq 0L) then rsun = fxpar (hdu, 'RSUN', count=qrsun)
    solar_p0 = fxpar (hdu, 'SOLAR-P0', count=qsolar_p0)
    solar_b0 = fxpar (hdu, 'SOLAR-B0', count=qsolar_b0)
    solar_ra = fxpar (hdu, 'SOLAR-RA', count=qsolar_ra)
    solardec = fxpar (hdu, 'SOLARDEC', count=qsolardec)
    carr_rot = fxpar (hdu, 'CARR_ROT', count=qcarr_rot)

    ;--- extension header:

    xdim     = fxpar (hduext, 'NAXIS1',   count=qnaxis1)
    ydim     = fxpar (hduext, 'NAXIS2',   count=qnaxis2)
    waveleng = fxpar (hduext, 'WAVELENG', count=qwaveleng)
    polstate = fxpar (hduext, 'POLSTATE', count=qpolstate)
    exposure = fxpar (hduext, 'EXPOSURE', count=qexposure)
    naverage = fxpar (hduext, 'NAVERAGE', count=qnaverage)
    filter   = fxpar (hduext, 'FILTER',   count=qfilter)
    datatype = fxpar (hduext, 'DATATYPE', count=qdatatype)
    datamin  = fxpar (hduext, 'DATAMIN',  count=cdatamin)
    datamax  = fxpar (hduext, 'DATAMAX',  count=cdatamax)

;    dispmin  = fxpar (hduext, 'DISPMIN', count=cdispmin)
;    dispmax  = fxpar (hduext, 'DISPMAX', count=cdispmax)

    wave = STRTRIM (STRING (format='(f6.1)', waveleng), 2)

    pixrs = rsun / cdelt1

    cneg = FIX (xcen - pixrs)	; pixel distance at Rsun left of center.
    cpos = FIX (xcen + pixrs)	; pixel distance at Rsun left of center.

    print, 'date_obs, time_obs: ', date_obs, ' ', time_obs
    print, 'ntune: ', ntune
    print, 'cneg/cpos: ', cneg, cpos
    print, 'xdim/ydim: ', xdim, ydim

    ;---------------------------------------------------
    ; Determine occulter size & solar photosphere [pixels].
    ;---------------------------------------------------

    pixrs      = rsun / cdelt1		; pixels/Rsun
    radius_occ = pixrs

;    radius_occ = occ_size / cdelt1	; pixels / occulter radius

    ;-------------------------
    ; Output image dimensions.
    ;-------------------------

    oxdim = xdim + xb
    oydim = ydim + yb

    print, 'oxdim/oydim: ', oxdim, oydim

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

    dispmin =  0.0			; display min.
    dispmax = 12.0			; display max.
    dexp    =  0.3			; display exponent.
    cbias   =  0.0			; corona bias value.

    ;--- Temporary values.  May eventually read these from FITS header.

    fmin = MIN (fimg, max=fmax)
    print, 'fts2jpg_comp fmin/fmax: ', fmin, fmax

    datamin = fmin		; image min.
    datamax = fmax		; image max.
;    dispmin = datamin		; display min.
;    dispmax = datamax		; display max.

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

    IF (KEYWORD_SET (wmin))  THEN dmin = wmin
    IF (KEYWORD_SET (wmax))  THEN dmax = wmax
    IF (KEYWORD_SET (wexp))  THEN dexp = wexp

    print, 'fts2jpg_comp dmin/dmax/dexp: ', dmin, dmax, dexp

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

    r_in  = radius_occ + 5
    r_out = xdim / 2.0 - 7
;    r_out = 504.0
    print, 'r_in, r_out: ', r_in, r_out

    bad = where (rad1 LT r_in OR rad1 GE r_out)
;    fimg (bad) = 0

    cbias = 0.01
    cbias = 0.02
    cbias = 0.00
    corona_bias = fimg + cbias
    corona_bias (bad) = 0

    ;---------------
    ; Display image.
    ;---------------

    simg = BYTSCL (corona_bias^dexp, min=dmin, max=dmax, top=249)
;    simg = BYTSCL (corona_cbias^dexp, top=249)

    imin = MIN (simg, max=imax)
    print, 'fts2jpg_comp imin/imax: ', imin, imax

;    TV, BYTSCL (img, min=dispmin, max=dispmax, top=249), xb, yb

;    simg (bad) = 255		; To produce a while occulter & outer FOV.
    TV, simg, xb, yb

    ;------------------------
    ; Draw overlays on image.
    ;------------------------

;    print, 'ov: ', ov

    IF (KEYWORD_SET (ov))  THEN	$
	overlay_comp, xdim, ydim, xcen, ycen, pixrs, solar_p0, xb, yb

    ;----------------
    ; Annotate image.
    ;----------------

    IF (KEYWORD_SET (annotate))  THEN	$    
    BEGIN ;{
      print, 'fts2jpg_comp dmin/dmax: ', dmin, dmax
      fits_annotate_comp, hdu, hduext, xdim, ydim, xb, yb, dmin, dmax, dexp
    END   ;}

    ;-------------
    ; Label image.
    ;-------------

    IF (KEYWORD_SET (label)) THEN $
    BEGIN ;{
      year  = strmid (date_obs, 0, 4) 
      month = strmid (date_obs, 5, 2)
      day   = strmid (date_obs, 8, 2)

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

      comp_label, date_dmy, doy, time_obs, datatype, wave, $
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

    IF (KEYWORD_SET (annotate) AND KEYWORD_SET (ov)) THEN	$
	jpg_file = basename + '.oa.jpg'

    IF (NOT KEYWORD_SET (annotate) AND NOT KEYWORD_SET (ov)) THEN	$
	jpg_file = basename + '.im.jpg'

    WRITE_JPEG, jpg_file, jpg_img, true=1, quality=75	; Write jpg file.
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

      IF (KEYWORD_SET (annotate) AND KEYWORD_SET (ov)) THEN	$
	gif_file = basename + '.oa.gif'

      IF (NOT KEYWORD_SET (annotate) AND NOT KEYWORD_SET (ov)) THEN	$
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

