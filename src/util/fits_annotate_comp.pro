;+
; NAME		fits_annotate_comp.pro
;
; PURPOSE	Annotate a FITS image.
;
; SYNTAX	fits_annotate, hdu
;
;		hdu: FITS header
;		xdim: x-axis dimension
;		ydim: y-axis dimension
;		xb:   x-axis border for annotation
;		yb:   y-axis border for annotation
;
; HISTORY	Andrew L. Stanger   HAO/NCAR   14 September 2001
;		28 Dec 2005: update for SMM C/P.
;		10 Nov 2006: remove image overlay graphics.
;               09 Jun 2015: adapt for kcor.
;               17 Jun 2015: add hduext parameter
;-

PRO fits_annotate_comp, hdu, hduext, xdim, ydim, xb, yb, dmin, dmax, dexp

;   print, '*** fits_annotate_comp ***'

   month_name = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',      $
		 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

;---------------------------------------------------------------------------
;  Define fonts.
;---------------------------------------------------------------------------

;  !P.FONT = -1		; Hershey font
;  !P.FONT =  0		; device font
;  !P.FONT =  1		; true type font
;  SET_PLOT, 'Z'
;  DEVICE, GET_FONTNAMES=fontnames
;  print, 'font names : ', fontnames
;  DEVICE, SET_FONT='Times', /TT_FONT
;  DEVICE, SET_FONT='Helvetica', /TT_FONT
;  DEVICE, SET_FONT='Helvetica Bold', /TT_FONT
;  DEVICE, SET_FONT='Courier', /TT_FONT
;  DEVICE, SET_FONT='DejaVuSans', /TT_FONT
;  DEVICE, SET_FONT='lucidasans-14', /TT_FONT
;  SET_CHARACTER_SIZE = [12, 8]
;  SET_CHARACTER_SIZE = [16, 12]

  bfont = '-adobe-courier-bold-r-normal--20-140-100-100-m-110-iso8859-1'
  bfont = '-*-times-bold-r-normal-*-12-*-100-100-*-*-*-*'
  bfont = '-*-times-bold-r-normal-*-16-*-100-100-*-*-*-*'
  bfont = 'Times'
  bfont = 'Helvetica'
;  bfont = (get_dfont (bfont))(0)
  IF (bfont EQ '') THEN bfont = 'fixed'
  bfont = -1
  bfont =  0
  bfont =  1

  lfont = '-misc-fixed-bold-r-normal--13-100-100-100-c-70-iso8859-1'
  lfont = '-*-lucida-*-r-*-*-14-*-*-*-*-*-*-*'
  lfont = '-*-helvetica-*-r-*-*-14-*-*-*-*-*-*-*'
  lfont = '-*-helvetica-*-r-*-*-10-*-*-*-*-*-*-*'
  lfont = 'Times'
  lfont = 'Helvetica'
;  lfont = (get_dfont (lfont))(0)
  IF (lfont EQ '') THEN lfont = 'fixed'
  lfont = -1
  lfont =  0
  lfont =  1

  tfont = '-*-itc bookman-*-r-*-*-14-*-*-*-*-*-*-*'
;  tfont = (get_dfont (tfont))(0)
  IF (tfont EQ '') THEN tfont = 'fixed'
  tfont = -1
  tfont =  0
  tfont =  1

  ;-----------------
  ; Character sizes:
  ;-----------------

  xoff =  2
  yoff =  2

  xx1   =  8
  xx1   =  5.5
  xx2   =  9
  xx3   = 12

  yy1   = 14
  yy1   = 12
  yy2   = 16
  yy3   =  8

  cfac = 1.0
  cfac = 1.5
  IF (STRLOWCASE (!version.os) EQ 'irix')    THEN cfac = 1.0
;  IF (STRLOWCASE (!version.os) EQ 'sunos' )  THEN cfac = 2.0

  cs1 = cfac * 0.75				; character size
  cs2 = cfac * 1.0
  cs3 = cfac * 0.5
  cs4 = cfac * 1.2
  
  x1 = FIX (xx1 * cs1 + 0.5)
  x2 = FIX (xx1 * cs2 + 0.5)
  x3 = FIX (xx1 * cs3 + 0.5)
  x4 = FIX (xx1 * cs4 + 0.5)

  y1 = FIX (yy1 * cs1 + 0.5)
  y2 = FIX (yy1 * cs2 + 0.5)
  y3 = FIX (yy1 * cs3 + 0.5)
  y4 = FIX (yy1 * cs4 + 0.5)

;  print, 'y1/y2/y3: ', y1, y2, y3

  xend = xdim + xb - x1 
  yend = ydim + yb - y1

  ;----------------------------------
  ; Color assignments for annotation.
  ;----------------------------------

  white  = 255
  red    = 254
  green  = 253
  blue   = 252
  grey   = 251
  yellow = 250
  black  =   0

  ;----------------------------------
  ; Get information from FITS header.
  ;----------------------------------

;  type_obs = fxpar (hdu, 'TYPE-OBS')

  date_obs = STRTRIM (fxpar (hdu, 'DATE-OBS'), 2)	; 'yyyy-mm-dd'
  time_obs = STRTRIM (fxpar (hdu, 'TIME-OBS'), 2)	; 'hh:mm:ss'
  object   = STRTRIM (fxpar (hdu, 'OBJECT'),   2)
  type_obs = STRTRIM (fxpar (hdu, 'DATATYPE'), 2)
  location = STRTRIM (fxpar (hdu, 'LOCATION'), 2)
  origin   = STRTRIM (fxpar (hdu, 'ORIGIN'),   2)
  telescop = STRTRIM (fxpar (hdu, 'TELESCOP'), 2)
  instrume = STRTRIM (fxpar (hdu, 'INSTRUME'), 2)
  level    = STRTRIM (fxpar (hdu, 'LEVEL'),    2)

  crpix1   = fxpar (hdu, 'CRPIX1')
  crpix2   = fxpar (hdu, 'CRPIX2')
  bunit    = fxpar (hdu, 'BUNIT')
  bscale   = fxpar (hdu, 'BSCALE')
  bzero    = fxpar (hdu, 'BZERO')
  cdelt1   = fxpar (hdu, 'CDELT1').  ; arcsec / pixel

  dispmin  = dmin   ; display minimum
  dispmax  = dmax   ; display maximum
  dispexp  = dexp   ; display exponent

;  datamin  = fxpar (hdu, 'DATAMIN')
;  datamax  = fxpar (hdu, 'DATAMAX')
;  dispmin  = fxpar (hdu, 'DISPMIN')
;  dispmax  = fxpar (hdu, 'DISPMAX')

  rsun     = fxpar (hdu, 'RSUN_OBS', count=n_rsun)
  if (n_rsun eq 0L) then rsun = fxpar (hdu, 'RSUN', count=n_rsun)

  dataform = '10^-6 B/Bsun'

  solar_p0 = fxpar (hdu, 'SOLAR_P0')   ; P-angle
  solar_b0 = fxpar (hdu, 'SOLAR_B0')   ; B-angle
  solar_ra = fxpar (hdu, 'SOLAR_RA')   ; right ascension
  solardec = fxpar (hdu, 'SOLARDEC')   ; declination 
  car_rot  = fxpar (hdu, 'CAR_ROT')    ; Carrington rotation

  waveleng = fxpar (hduext, 'WAVELENG')
  expdur   = fxpar (hduext, 'EXPOSURE')

  year     = STRMID (date_obs, 0, 4)
  month    = STRMID (date_obs, 5, 2)
  day      = STRMID (date_obs, 8, 2)
  iyear    = FIX (year)
  imonth   = FIX (month)
  iday     = FIX (day)
  syear    = STRTRIM (STRING (iyear), 2)
  smonth   = month_name [imonth - 1]
  sday     = STRTRIM (STRING (iday),  2)
  sdate    = sday + ' ' + smonth + ' ' + syear

;  time_obs = strmid (date_obs, 11, 8)	; hh:mm:ss

  time_img = time_obs + ' UT'

  pixrs    = rsun / cdelt1		; pixels / Rsun
  srsun    = STRING (rsun, FORMAT='(F7.2)')

  pangle   = FLOAT (solar_p0)
  bangle   = FLOAT (solar_b0)
;  langle   = FLOAT (solar_l0)

  spangle  = STRING (solar_p0, FORMAT='(F7.2)')
  sbangle  = STRING (solar_b0, FORMAT='(F7.2)')
;  slangle  = STRING (solar_l0, FORMAT='(F7.2)')

;  print, 'rsun:         ', rsun
;  print, 'solar_p0:     ', solar_p0
;  print, 'solar_b0:     ', solar_b0
;  print, 'bscale/bzero: ', bscale, bzero
;  print, 'datamin/datamax: ', datamin, datamax
;  print, 'dispmin/dispmax: ', dispmin, dispmax

  xcen  = FLOAT (crpix1) - 1.0
  ycen  = FLOAT (crpix2) - 1.0
  ixcen = FIX (xcen + 0.5)
  iycen = FIX (ycen + 0.5)

;  calmir    = STRTRIM (calmir, 2)
;  IF (calmir EQ 'IN') THEN		$
;    img_source = 'Cal.Reticle'	$
;  ELSE img_source = object
  img_source = ''

  ;---------------------------------------
  ; Choose data format for min/max values.
  ;---------------------------------------

;  sdatamin   = STRTRIM (STRING (datamin, FORMAT='(E8.2)'), 2)
;  IF (datamin LT 0.0) THEN		$
;    sdatamin   = STRTRIM (STRING (datamin, FORMAT='(E9.2)'), 2)
;  IF (datamin EQ 0.0) THEN		$
;    sdatamin = STRTRIM (STRING (datamin, FORMAT='(I4)'  ), 2)

;  sdatamax   = STRTRIM (STRING (datamax, FORMAT='(E8.2)'), 2)
;  IF (datamax LT 0.0) THEN		$
;    sdatamax   = STRTRIM (STRING (datamax, FORMAT='(E9.2)'), 2)
;  IF (datamax EQ 0.0) THEN		$
;    sdatamax = STRTRIM (STRING (datamax, FORMAT='(I4)'  ), 2)

  sdispmin   = STRTRIM (STRING (dispmin, FORMAT='(E8.2)'), 2)
  IF (dispmin LT 0.0) THEN		$
    sdispmin   = STRTRIM (STRING (dispmin, FORMAT='(E9.2)'), 2)
  IF (dispmin EQ 0.0) THEN		$
    sdispmin = STRTRIM (STRING (dispmin, FORMAT='(I4)'  ), 2)

  sdispmax   = STRTRIM (STRING (dispmax, FORMAT='(E8.2)'), 2)
  IF (dispmax LT 0.0) THEN		$
    sdispmax   = STRTRIM (STRING (dispmax, FORMAT='(E9.2)'), 2)
  IF (dispmax EQ 0.0) THEN		$
    sdispmax = STRTRIM (STRING (dispmax, FORMAT='(I4)'  ), 2)

  IF (dmin GE 10000.0 OR dmin LT 1.0) THEN		$
    sdmin    = STRTRIM (STRING (dmin,    FORMAT='(E8.2)'), 2)
  IF (dmin LT 10000.0 AND dmin GT 1.0) THEN		$
    sdmin    = STRTRIM (STRING (dmin,    FORMAT='(F9.1)'), 2)
  IF (dmin EQ 0.0) THEN		$
    sdmin    = STRTRIM (STRING (dmin,    FORMAT='(I4)'  ), 2)

  IF (dmax GE 10000.0 OR dmax LT 1.0) THEN		$
  BEGIN
    print,'>10k dmax: ', dmax
    sdmax    = STRTRIM (STRING (dmax,    FORMAT='(E8.2)'), 2)
  END

  if (dmax LT 10000.0 AND dmax GT 1.0) THEN		$
  BEGIN
    print,'<10k dmax: ', dmax
    sdmax    = STRTRIM (STRING (dmax,    FORMAT='(F9.1)'), 2)
  END

  if (dmax EQ 0.0) THEN		$
  BEGIN
    print,'zero dmax: ', dmax
    sdmax    = STRTRIM (STRING (dmax,    FORMAT='(I4)'  ), 2)
  END

  sdexp = STRING (dexp, FORMAT='(f5.2)')

  sexpdur = STRTRIM (STRING ( expdur, FORMAT='(F7.3)'), 2)

  ;-----------------------
  ; Draw box around image.
  ;-----------------------

  wvec, 0,         yb,        0,         yb+ydim-1, grey
  wvec, 0,         yb+ydim-1, xdim+xb-1, yb+ydim-1, grey
  wvec, 0,         yb+ydim-1, 0,         yb+ydim-1, grey
  wvec, xb,        yb,        xdim+xb-1, yb,        grey
  wvec, xdim+xb-1, yb,        xdim+xb-1, ydim+yb-1, grey 
  wvec, xdim+xb-1, ydim+yb-1, xb,        ydim+yb-1, grey
  wvec, xb,        ydim+yb-1, xb,        yb,        grey
  wvec, 0,         yb,        xb,        yb,        grey

  ;*****************************************************************************
  ; Annotate image : left margin
  ;-----------------------------

  ylab = yend - yoff
  ydat = ylab - y2
  XYOUTS, xoff, ylab, 'DATE',	$
;          /device, charsize=1.0, color=red
          /device, font=lfont, charsize=cs1, color=red
  XYOUTS, xoff, ydat, sdate,	$
;          /device, charsize=1.5, color=black
          /device, font=bfont, charsize=cs2, color=black

  ;-----------------------------------------------------

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  XYOUTS, xoff, ylab, 'TIME',	$
;          /device, charsize=1.0, color=red
	  /device, font=lfont, charsize=cs1, color=red
  XYOUTS, xoff, ydat, time_img,	$
	  /device, font=bfont, charsize=cs2, color=black

  ;-----------------------------------------------------

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  XYOUTS, xoff, ylab, 'TELESCOPE',	$
	  /device, font=lfont, charsize=cs1, color=red
  XYOUTS, xoff, ydat, telescop,	$
	  /device, font=bfont, charsize=cs2, color=black

  ;-----------------------------------------------------

  IF (telescop NE instrume) THEN $
  BEGIN ;{
    ylab = ylab - y2 - y2 - y3
    ydat = ylab - y2
    XYOUTS, xoff, ylab, 'INSTRUMENT',	$
	    /device, font=lfont, charsize=cs1, color=red
    XYOUTS, xoff, ydat, instrume,	$
            /device, font=bfont, charsize=cs2, color=black
  END   ;}

  ;-----------------------------------------------------

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  XYOUTS, xoff, ylab, 'OBJECT',	$
;          /device, charsize=1.0, color=red
	  /device, font=lfont, charsize=cs1, color=red
  XYOUTS, xoff, ydat, 'Sun ' + img_source,	$
	  /device, font=bfont, charsize=cs2, color=black

  ;----------------------
  ; Intensity components.
  ;----------------------

;  lcc  = fxpar (hdu_hk, 'LCC')
;  lfc  = fxpar (hdu_hk, 'LFC')
;  lvig = fxpar (hdu_hk, 'LVIG')
;  lstr = fxpar (hdu_hk, 'LSTR')
;  print, 'lcc/lfc/lvig/lstr: ', lcc, lfc, lvig, lstr
;
;  print, 'object: ', object
;
  IF (object EQ 'CORONA' OR object EQ 'corona' OR $
      object EQ 'Solar K-Corona') THEN	$
    pixval = 'Corona'			$
  ELSE pixval = 'Calibration'
;
;  IF (lfc  EQ 0) THEN pixval = '(K+F)'         
;  IF (lstr EQ 0) THEN pixval = 'S+'    + pixval
;  IF (lvig EQ 0) THEN pixval =           pixval + '*V'
;  IF (lcc  EQ 0) THEN pixval = '[' +     pixval + ']/C'
;
  pixval = STRTRIM (pixval, 2)
  print, 'pixval: ', pixval
  lenpixval = STRLEN (pixval)
  xloc = (xb - (lenpixval * x2)) / 2
  xloc = xoff
  IF (xloc < 0)  THEN xloc = xoff
  print, 'xloc: ', xloc

  ;-----------------------------------------------------

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  print, 'ylab: ', ylab
  XYOUTS, xloc, ylab,'SOURCE',	$
;          /device, charsize=1.0, color=red
          /device, font=lfont, charsize=cs1, color=red
  XYOUTS, xloc, ydat, pixval,			$
	  /device, font=bfont, charsize=cs2, color=black

  ;-----------------------------------------------------

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  XYOUTS, xoff, ylab, 'TYPE-OBS',	$
;          /device, charsize=1.0, color=red
	  /device, font=lfont, charsize=cs1, color=red
  XYOUTS, xoff, ydat, type_obs,	$
	  /device, font=bfont, charsize=cs2, color=black

  ;-----------------------------------------------------

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  XYOUTS, xoff, ylab, 'DATA FORM',	$
	  /device, font=lfont, charsize=cs1, color=red
  XYOUTS, xoff, ydat, dataform,	$
	  /device, font=bfont, charsize=cs2, color=black

  ;-----------------------------------------------------

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  XYOUTS, xoff, ylab, 'EXPOSURE',	$
;          /device, charsize=1.0, color=red
	  /device, font=lfont, charsize=cs1, color=red
  XYOUTS, xoff, ydat, sexpdur,	$
	  /device, font=bfont, charsize=cs2, color=black

  ;-----------------------------------------------------

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  XYOUTS, xoff, ylab, 'P-angle',	$
;          /device, charsize=1.0, color=red
	  /device, font=lfont, charsize=cs1, color=red
  XYOUTS, xoff, ydat, spangle,	$
	  /device, font=bfont, charsize=cs2, color=black

  ;-----------------------------------------------------

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  XYOUTS, xoff, ylab, 'B-angle',	$
;          /device, charsize=1.0, color=red
	  /device, font=lfont, charsize=cs1, color=red
  XYOUTS, xoff, ydat, sbangle,	$
	  /device, font=bfont, charsize=cs2, color=black

  ;-----------------------------------------------------

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  XYOUTS, xoff, ylab, 'L-angle',	$
;;          /device, charsize=1.0, color=red
;	  /device, font=lfont, charsize=cs1, color=red
;  XYOUTS, xoff, ydat, slangle,	$
;	  /device, font=bfont, charsize=cs2, color=black

  ;-----------------------------------------------------

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  XYOUTS, xoff, ylab, 'DATA MIN',	$
;          /device, charsize=1.0, color=red
;	  /device, font=lfont, charsize=cs1, color=red
;  XYOUTS, xoff, ydat, sdatamin,	$
;	  /device, font=bfont, charsize=cs2, color=black

  ;-----------------------------------------------------

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  XYOUTS, xoff, ylab, 'DATA MAX',	$
;          /device, charsize=1.0, color=red
;	  /device, font=lfont, charsize=cs1, color=red
;  XYOUTS, xoff, ydat, sdatamax,	$
;	  /device, font=bfont, charsize=cs2, color=black

  ;-----------------------------------------------------

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  XYOUTS, xoff, ylab, 'DISP MIN',	$
;          /device, charsize=1.0, color=red
	  /device, font=lfont, charsize=cs1, color=red
  XYOUTS, xoff, ydat, sdmin,	$
	  /device, font=bfont, charsize=cs2, color=black

  ;-----------------------------------------------------

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  XYOUTS, xoff, ylab, 'DISP MAX',	$
;          /device, charsize=1.0, color=red
	  /device, font=lfont, charsize=cs1, color=red
  XYOUTS, xoff, ydat, sdmax,	$
	  /device, font=bfont, charsize=cs2, color=black

  ;-----------------------------------------------------

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  XYOUTS, xoff, ylab, 'DISP EXP',	$
;          /device, charsize=1.0, color=red
	  /device, font=lfont, charsize=cs1, color=red
  XYOUTS, xoff, ydat, sdexp,	$
	  /device, font=bfont, charsize=cs2, color=black

  ;-----------------------------------------------------

;  print, 'wmin: ', wmin
;  IF (KEYWORD_SET (wmin) OR wmin EQ 0.0) THEN	$
;  IF (KEYWORD_SET (wmin)) THEN	$
;  BEGIN
;     wmin = STRTRIM (STRING (wmin, FORMAT='(E8.2)'), 2)
;	ylab = ylab - y1 - y2 - y3
;     ydat = ylab - y2
;     XYOUTS, xoff, ylab, 'WMIN',	$
;		/device, font=lfont, charsize=cs1, color=red
;     XYOUTS, xoff, ydat, wmin,	$
;		/device, font=bfont, charsize=cs2, color=black
;  END
;
;  IF (KEYWORD_SET (wmax)) THEN	$
;  BEGIN
;     wmax = STRTRIM (STRING (wmax, FORMAT='(E8.2)'), 2)
;	ylab = ylab - y1 - y2 - y3
;     ydat = ylab - y2
;     XYOUTS, xoff, ylab, 'WMAX',	$
;		/device, font=lfont, charsize=cs1, color=red
;     XYOUTS, xoff, ydat, wmax,	$
;		/device, font=bfont, charsize=cs2, color=black
;  END

  ;-----------------------------------------------------

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  XYOUTS, xoff, ylab, 'BRIGHTNESS UNIT',	$
;	  /device, font=lfont, charsize=cs1, color=red
;  XYOUTS, xoff, ydat, bunit,		$
;	  /device, font=bfont, charsize=cs2, color=black

  ;*****************************************************************************

  ;-----------------------------------------------
  ; Draw solar radius scale along bottom of image.
  ;-----------------------------------------------

  npixrs = FIX (pixrs + 0.5)
  xcenwin = xcen + xb
  xloc = FIX (xcenwin + 0.5)
  i = 0
  WHILE (xloc GE xb AND xloc LE xdim+xb-1) DO	$
  BEGIN
    wvec, xloc, yb, xloc, yb-6, grey
    i = i + 1
    xloc = FIX (xcenwin + pixrs * i + 0.5)
  END

  xloc = FIX (xcenwin + 0.5)
  i = 0
  WHILE (xloc GE xb AND xloc LE xdim+xb-1) DO	$
  BEGIN
    wvec, xloc, yb, xloc, yb-6, grey
    i = i + 1
    xloc = FIX (xcenwin - pixrs * i - 0.5)
  END

  wvec, ixcen+xb-3, yb-3, ixcen+xb+3, yb-3, grey

  ycenwin = ycen + yb
  yloc = FIX (ycenwin + 0.5)
  i = 0
  WHILE (yloc GE yb AND yloc LE ydim+yb-1) DO	$
  BEGIN
    wvec, xb-6, yloc, xb, yloc, grey
    i = i + 1
    yloc = FIX (ycenwin + pixrs * i + 0.5)
  END

  yloc = FIX (ycenwin + 0.5)
  i = 0
  WHILE (yloc GE yb AND yloc LE ydim+yb-1) DO	$
  BEGIN
    wvec, xb-6, yloc, xb, yloc, grey
    i = i + 1
    yloc = FIX (ycenwin - pixrs * i - 0.5)
  END

  wvec, xb-3, iycen+yb-3, xb-3, iycen+yb+3, grey

  ;--- Create color bar array.

  collin = bindgen (256)
  collin = rebin (collin, 512)
  colbar = bytarr (512, 12)
  for i = 0, 11 DO	$
     colbar [*, i] = collin [*]

  ;----------------
  ; Draw color bar.
  ;----------------

  xc1 = (xdim - 512) / 2 - 1 + xb
  xc2 = xc1 + 511
  yc1 = 20
  yc2 = 31

  tv, colbar, xc1, yc1

  ;------------------------------
  ; Draw border around color bar.
  ;------------------------------

  plots, [xc1-1,     yc1-1], /device, color=251
  plots, [xc1-1,     yc2+1], /device, color=251, /CONTINUE
  plots, [xc1-1+514, yc2+1], /device, color=251, /CONTINUE
  plots, [xc1-1+514, yc1-1], /device, color=251, /CONTINUE
  plots, [xc1-1,     yc1-1], /device, color=251, /CONTINUE

  ;---------------------------------
  ; Draw tick marks below color bar.
  ;---------------------------------

  plots, [xc1,     yc1- 3], /device, color=251
  plots, [xc1,     yc1- 7], /device, color=251, /CONTINUE
  plots, [xc1+ 63, yc1- 3], /device, color=251
  plots, [xc1+ 63, yc1- 7], /device, color=251, /CONTINUE
  plots, [xc1+127, yc1- 3], /device, color=251
  plots, [xc1+127, yc1- 7], /device, color=251, /CONTINUE
  plots, [xc1+191, yc1- 3], /device, color=251
  plots, [xc1+191, yc1- 7], /device, color=251, /CONTINUE
  plots, [xc1+255, yc1- 3], /device, color=251
  plots, [xc1+255, yc1- 7], /device, color=251, /CONTINUE
  plots, [xc1+319, yc1- 3], /device, color=251
  plots, [xc1+319, yc1- 7], /device, color=251, /CONTINUE
  plots, [xc1+382, yc1- 3], /device, color=251
  plots, [xc1+382, yc1- 7], /device, color=251, /CONTINUE
  plots, [xc1+447, yc1- 3], /device, color=251
  plots, [xc1+447, yc1- 7], /device, color=251, /CONTINUE
  plots, [xc2,     yc1- 3], /device, color=251
  plots, [xc2,     yc1- 7], /device, color=251, /CONTINUE

  ;-----------------
  ; Label color bar.
  ;-----------------

;  print, 'cs1: ', cs1
;  XYOUTS, xc1 -         x1 / 2, yc1 -  8 - y1,   '0', /device, $
;  	font=lfont, charsize=cs1, color=black
;  XYOUTS, xc1 -         x1 / 2, 1,   '0', /device, $
;  	font=lfont, charsize=0.75, color=black
;  XYOUTS, xc1 + 127 - 2*x1 / 2, yc1 -  8 - y1,  '63', /device, $
;  	font=lfont, charsize=cs1, color=black
;  XYOUTS, xc1 + 255 - 3*x1 / 2, yc1 -  8 - y1, '127', /device, $
;  	font=lfont, charsize=cs1, color=black
;  XYOUTS, xc1 + 383 - 3*x1 / 2, yc1 -  8 - y1, '191', /device, $
;  	font=lfont, charsize=cs1, color=black
;  XYOUTS, xc1 + 512 - 3*x1 - 1, yc1 -  8 - y1, '255', /device, $
;  	font=lfont, charsize=cs1, color=black

  XYOUTS, xc1 -         x1 / 2, 1,   '0', /device, $
  	font=lfont, charsize=0.75, color=black
  XYOUTS, xc1 + 127 - 2*x1 / 2, 1,  '63', /device, $
  	font=lfont, charsize=0.75, color=black
  XYOUTS, xc1 + 255 - 3*x1 / 2, 1, '127', /device, $
  	font=lfont, charsize=0.75, color=black
  XYOUTS, xc1 + 383 - 3*x1 / 2, 1, '191', /device, $
  	font=lfont, charsize=0.75, color=black
  XYOUTS, xc1 + 512 - 3*x1 - 1, 1, '255', /device, $
  	font=lfont, charsize=0.75, color=black

  ;------------
  ; Draw title.
  ;------------

  title  = instrume + '    Mauna Loa Solar Observatory   HAO/NCAR'
  lentit = STRLEN (title)
  print, 'lentit: ', lentit
;  x4 = 12
  print, 'x4: ', x4
  xloc = xb + (xdim - (lentit * x4)) / 2
  ylab = yc2 + (yb - yc2 - y4) / 2 + FIX (y4 * 0.2) - 3
;  print, 'xloc: ', xloc
;  print, 'yb, y4, ylab: ', yb, y4, ylab
  XYOUTS, xloc, ylab, title,		$
	 /device, font=bfont, charsize=cs4, color=red
;	 /device, font=bfont, charsize=2, color=red
;  XYOUTS, xloc, ylab, title, charsize=cs4, color=red

;  print, '<<<<<<< Leaving fits_annotate_comp'
  RETURN
END
