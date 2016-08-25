;+
;-------------------------------------------------------------------------------
; NAME		fits_annotate_kcor.pro
;-------------------------------------------------------------------------------
; PURPOSE	Annotate a FITS image.
;
; SYNTAX	fits_annotate_kcor, hdu
;
;		hdu: FITS header
;		xdim: x-axis dimension
;		ydim: y-axis dimension
;		xb:   x-axis border for annotation
;		yb:   y-axis border for annotation
;
; HISTORY	Andrew L. Stanger   HAO/NCAR   14 September 2001
; 28 Dec 2005: update for SMM C/P.
; 12 Nov 2015: Adapt for kcor.
;-------------------------------------------------------------------------------
;-

PRO fits_annotate_kcor, hdu, xdim, ydim, xb, yb, $
                        wmin=wmin, wmax=wmax, wexp=wexp

   print, '*** fits_annotate_kcor ***'

   month_name = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',      $
	         'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

;---------------------------------------------------------------------------
;  Define fonts.
;---------------------------------------------------------------------------

  !P.FONT = 1
;  DEVICE, SET_FONT='Helvetica', /TT_FONT
  SET_CHARACTER_SIZE = [12, 8]

;  bfont = '-adobe-courier-bold-r-normal--20-140-100-100-m-110-iso8859-1'
  bfont = '-*-times-bold-r-normal-*-16-*-100-100-*-*-*-*'
  bfont = '-*-helvetica-*-r-*-*-24-*-*-*-*-*-*-*'
;  bfont = (get_dfont (bfont))(0)
  IF (bfont EQ '') THEN bfont = 'fixed'
;  bfont = 0
  bfont = -1
;  bfont = 6

;  lfont = '-misc-fixed-bold-r-normal--13-100-100-100-c-70-iso8859-1'
;  lfont = '-*-lucida-*-r-*-*-14-*-*-*-*-*-*-*'
  lfont = '-*-helvetica-*-r-*-*-14-*-*-*-*-*-*-*'
  lfont = '-*-helvetica-*-r-*-*-10-*-*-*-*-*-*-*'
;  lfont = (get_dfont (lfont))(0)
  IF (lfont EQ '') THEN lfont = 'fixed'
  lfont = -1

  tfont = '-*-itc bookman-*-r-*-*-14-*-*-*-*-*-*-*'
;  tfont = (get_dfont (tfont))(0)
  IF (tfont EQ '') THEN tfont = 'fixed'
  tfont = -1

  ;-----------------
  ; Character sizes:
  ;-----------------

  xoff =  2
  yoff =  2

  xx1   =  8
  xx2   =  9
  xx3   = 12

  xx1   =  5
  xx2   =  8
  xx3   = 10

  yy1   = 14
  yy2   = 16
  yy3   =  8

  yy1   = 10
  yy2   = 12
  yy3   = 14

  cfac = 1.0
  cfac = 1.8
  IF (STRLOWCASE (!version.os) EQ 'irix')    THEN cfac = 1.0
  IF (STRLOWCASE (!version.os) EQ 'sunos' )  THEN cfac = 2.0

  cs1 = cfac * 0.75				; character size
  cs2 = cfac * 1.0
  cs3 = cfac * 1.25
  cs4 = cfac * 1.5

  print, 'cs1/cs2/cs3/cs4: ', cs1, cs2, cs3, cs4
  
  x1 = FIX (xx1 * cs1 + 0.5)
  x2 = FIX (xx1 * cs2 + 0.5)
  x3 = FIX (xx1 * cs3 + 0.5)
  x4 = FIX (xx1 * cs4 + 0.5)

  y1 = FIX (yy1 * cs1 + 0.5)
  y2 = FIX (yy1 * cs2 + 0.5)
  y3 = FIX (yy1 * cs3 + 0.5)
  y4 = FIX (yy1 * cs4 + 0.5)

  print, 'y1/y2/y3: ', y1, y2, y3

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

  object    = fxpar (hdu, 'OBJECT')
  datatype  = fxpar (hdu, 'DATATYPE', count=qdatatype)
;  type_obs  = fxpar (hdu, 'TYPE-OBS')
  origin    = fxpar (hdu, 'ORIGIN')
  telescop  = STRTRIM (fxpar (hdu, 'TELESCOP'), 2)
  instrume  = STRTRIM (fxpar (hdu, 'INSTRUME'), 2)
  date_obs  = fxpar (hdu, 'DATE-OBS', count=qdate_obs)
  time_obs  = fxpar (hdu, 'TIME-OBS', count=qtime_obs)

  xcen      = fxpar (hdu, 'CRPIX1') - 1
  ycen      = fxpar (hdu, 'CRPIX2') - 1
  bunit     = fxpar (hdu, 'BUNIT')
  bscale    = fxpar (hdu, 'BSCALE')
  bzero     = fxpar (hdu, 'BZERO')
  datamin   = fxpar (hdu, 'DATAMIN',  count=qdatamin)
  datamax   = fxpar (hdu, 'DATAMAX',  count=qdatamax)
  dispmin   = fxpar (hdu, 'DISPMIN',  count=qdispmin)
  dispmax   = fxpar (hdu, 'DISPMAX',  count=qdispmax)
  dispexp   = fxpar (hdu, 'DISPEXP',  count=qdispexp)

  cdelt1    = fxpar (hdu, 'CDELT1',   count=qcdelt1)
  rsun      = fxpar (hdu, 'RSUN',     count=qrsun)

  expdur    = fxpar (hdu, 'EXPTIME')
  roll      = fxpar (hdu, 'INST_ROT')

  dateobs  = STRMID (date_obs,  0, 11)
  timeobs  = STRMID (date_obs, 11,  8)

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

  date_img  = syear + '-' + smonth + '-' + sday
  time_img  = timeobs + ' UT'
  type_obs  = object

  pixrs    = rsun / cdelt1
  srsun    = STRING (rsun, FORMAT='(F7.2)')

;  if (datamin EQ 0.0 and datamax EQ 0.0) then $
;  begin
;     datamin = MIN (img)
;     datamax = MAX (img)
;  end

  print, 'xcen, ycen: ', xcen, ycen
  print, 'rsun, cdelt1, pixrs : ', rsun, cdelt1, pixrs
  print, 'bscale/bzero: ', bscale, bzero
  print, 'datamin/datamax: ', datamin, datamax
  print, 'dispmin/dispmax,dispexp: ', dispmin, dispmax, dispexp

  ;----------------------------------------------
  ; Determine min/max intensity range to display.
  ;----------------------------------------------

  dmin = datamin
  dmax = datamax
  dexp = 1.0

  dmin = 0.0
  dmax = 1.2
  dexp = 0.7

  IF (dispmin NE dispmax) THEN	$
  BEGIN
    dmin = dispmin
    dmax = dispmax
  END

  if (qdispmin NE 0) then dmin = dispmin
  if (qdispmax NE 0) then dmax = dispmax
  if (qdispexp NE 0) then dexp = dispexp

  IF (KEYWORD_SET (wmin)) THEN dmin = wmin
  IF (KEYWORD_SET (wmax)) THEN dmax = wmax
  IF (KEYWORD_SET (wexp)) THEN dexp = wexp

  print, 'dmin/dmax/dexp: ', dmin, dmax, dexp

  ixcen     = FIX (xcen + 0.5)
  iycen     = FIX (ycen + 0.5)
  iexpdur   = FIX (expdur + 0.5)
  iroll     = FIX (roll + 0.5)

  img_source = object

  ;---------------------------------------
  ; Choose data format for min/max values.
  ;---------------------------------------

  sdatamin   = STRTRIM (STRING (datamin, FORMAT='(E8.2)'), 2)
  IF (datamin EQ 0.0) THEN		$
    sdatamin = STRTRIM (STRING (datamin, FORMAT='(I4)'  ), 2)

  sdatamax   = STRTRIM (STRING (datamax, FORMAT='(E8.2)'), 2)
  IF (datamax EQ 0.0) THEN		$
    sdatamax = STRTRIM (STRING (datamax, FORMAT='(I4)'  ), 2)

  sdispmin   = STRTRIM (STRING (dispmin, FORMAT='(E8.2)'), 2)
  IF (dispmin EQ 0.0) THEN		$
    sdispmin = STRTRIM (STRING (dispmin, FORMAT='(I4)'  ), 2)

  sdispmax   = STRTRIM (STRING (dispmax, FORMAT='(E8.2)'), 2)
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

  sdexp = STRTRIM (STRING (dexp, FORMAT='(F4.2)'), 2)

  sexpdur   = STRTRIM (STRING (iexpdur, FORMAT='(I4)'  ), 2)
  sexpdur   = STRTRIM (STRING ( expdur, FORMAT='(F7.3)'), 2)
  sroll     = STRTRIM (STRING (iroll, FORMAT='(I4)'  ), 2)

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

  ;----------------
  ; Annotate image.
  ;----------------

  ylab = yend - yoff
  ydat = ylab - y2
  XYOUTS, xoff, ylab, 'DATE',	$
          /device, charsize=cs2, color=red
;          /device, font=lfont, charsize=cs1, color=red
  XYOUTS, xoff, ydat, sdate,	$
          /device, charsize=cs3, color=grey
;          /device, font=bfont, charsize=cs2, color=grey

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  XYOUTS, xoff, ylab, 'TIME',	$
          /device, charsize=cs2, color=red
;	  /device, font=lfont, charsize=cs1, color=red
  XYOUTS, xoff, ydat, time_img,	$
          /device, charsize=cs3, color=grey
;	  /device, font=bfont, charsize=cs2, color=grey

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  XYOUTS, xoff, ylab, 'OBJECT',	$
          /device, charsize=cs2, color=red
;	  /device, font=lfont, charsize=cs1, color=red
  XYOUTS, xoff, ydat, img_source,	$
          /device, charsize=cs3, color=grey
;	  /device, font=bfont, charsize=cs2, color=grey

  IF (object EQ 'CORONA') THEN	$
    pixval = 'K-CORONA'			$
  ELSE pixval = 'CALIBRATION'

;  IF (lfc  EQ 0) THEN pixval = '(K+F)'         
;  IF (lstr EQ 0) THEN pixval = 'S+'    + pixval
;  IF (lvig EQ 0) THEN pixval =           pixval + '*V'
;  IF (lcc  EQ 0) THEN pixval = '[' +     pixval + ']/C'

  pixval = STRTRIM (pixval, 2)
  print, 'pixval: ', pixval
  lenpixval = STRLEN (pixval)
  xloc = (xb - (lenpixval * x2)) / 2
  xloc = xoff
  IF (xloc < 0)  THEN xloc = xoff

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  XYOUTS, xloc, ylab,'INTENSITY SOURCE',	$
;          /device, charsize=1.0, color=red
;          /device, font=lfont, charsize=cs1, color=red
;  XYOUTS, xloc, ydat, pixval,			$
;          /device, charsize=1.5, color=grey
; 	  /device, font=bfont, charsize=cs2, color=grey

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  XYOUTS, xoff, ylab, 'DATATYPE',	$
          /device, charsize=cs2, color=red
;	  /device, font=lfont, charsize=cs1, color=red
  XYOUTS, xoff, ydat, datatype,	$
          /device, charsize=cs3, color=grey
;	  /device, font=bfont, charsize=cs2, color=grey

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  XYOUTS, xoff, ylab, 'FILTER',	$
;          /device, charsize=cs2, color=red
;	  /device, font=lfont, charsize=cs1, color=red
;  XYOUTS, xoff, ydat, colorfil,	$
;          /device, charsize=cs3, color=grey
;	  /device, font=bfont, charsize=cs2, color=grey

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  XYOUTS, xoff, ylab, 'POLAROID',	$
;          /device, charsize=cs2, color=red
;	  /device, font=lfont, charsize=cs1, color=red
;  XYOUTS, xoff, ydat, polaroid,	$
;          /device, charsize=cs3, color=grey
;	  /device, font=bfont, charsize=cs2, color=grey

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  XYOUTS, xoff, ylab, 'SECTOR',	$
;          /device, charsize=cs2, color=red
;	  /device, font=lfont, charsize=cs1, color=red
;  XYOUTS, xoff, ydat, sector,	$
;          /device, charsize=cs3, color=grey
;	  /device, font=bfont, charsize=cs2, color=grey

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  XYOUTS, xoff, ylab, 'EXPOSURE [sec]',	$
          /device, charsize=cs2, color=red
;	  /device, font=lfont, charsize=cs1, color=red
  XYOUTS, xoff, ydat, sexpdur,	$
          /device, charsize=cs3, color=grey
;	  /device, font=bfont, charsize=cs2, color=grey

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  XYOUTS, xoff, ylab, 'SPACECRAFT ROLL',	$
;          /device, charsize=cs2, color=red
;	  /device, font=lfont, charsize=cs1, color=red
;  XYOUTS, xoff, ydat, sroll,	$
;          /device, charsize=cs3, color=grey
;	  /device, font=bfont, charsize=cs2, color=grey

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  XYOUTS, xoff, ylab, 'TELESCOPE',	$
;	  /device, font=lfont, charsize=cs1, color=red
;  XYOUTS, xoff, ydat, telescop,	$
;	  /device, font=bfont, charsize=cs2, color=grey

;  ylab = ylab - y2 - y2 - y3
;  ydat = ylab - y2
;  XYOUTS, xoff, ylab, 'INSTRUMENT',	$
;	  /device, font=lfont, charsize=cs1, color=red
;  XYOUTS, xoff, ydat, instrume,	$
;	  /device, font=bfont, charsize=cs2, color=grey

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  XYOUTS, xoff, ylab, 'OBJECT',	$
;	  /device, font=lfont, charsize=cs1, color=red
;  XYOUTS, xoff, ydat, object,	$
;	  /device, font=bfont, charsize=cs2, color=grey

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  XYOUTS, xoff, ylab, 'TYPE-OBS',	$
;	  /device, font=lfont, charsize=cs1, color=red
;  XYOUTS, xoff, ydat, type_obs,	$
;	  /device, font=bfont, charsize=cs2, color=grey

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  XYOUTS, xoff, ylab, 'DATA FORM',	$
;	  /device, font=lfont, charsize=cs1, color=red
;  XYOUTS, xoff, ydat, dataform,	$
;	  /device, font=bfont, charsize=cs2, color=grey

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  XYOUTS, xoff, ylab, 'DATA MIN',	$
;          /device, charsize=1.0, color=red
;	  /device, font=lfont, charsize=cs1, color=red
;  XYOUTS, xoff, ydat, sdatamin,	$
;          /device, charsize=1.5, color=grey
;	  /device, font=bfont, charsize=cs2, color=grey

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  XYOUTS, xoff, ylab, 'DATA MAX',	$
;          /device, charsize=cs2, color=red
;	  /device, font=lfont, charsize=cs1, color=red
;  XYOUTS, xoff, ydat, sdatamax,	$
;          /device, charsize=cs3, color=grey
;	  /device, font=bfont, charsize=cs2, color=grey

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  XYOUTS, xoff, ylab, 'DISP MIN',	$
          /device, charsize=cs2, color=red
;	  /device, font=lfont, charsize=cs1, color=red
  XYOUTS, xoff, ydat, sdmin,	$
          /device, charsize=cs3, color=grey
;	  /device, font=bfont, charsize=cs2, color=grey

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  XYOUTS, xoff, ylab, 'DISP MAX',	$
          /device, charsize=cs2, color=red
;	  /device, font=lfont, charsize=cs1, color=red
  XYOUTS, xoff, ydat, sdmax,	$
          /device, charsize=cs3, color=grey
;	  /device, font=bfont, charsize=cs2, color=grey

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  XYOUTS, xoff, ylab, 'DISP EXP',	$
          /device, charsize=cs2, color=red
;          /device, font=lfont, charsize=cs1, color=red
  XYOUTS, xoff, ydat, sdexp,	$
          /device, charsize=cs3, color=grey
;          /device, font=bfont, charsize=cs2, color=grey

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
;		/device, font=bfont, charsize=cs2, color=grey
;  END

;  IF (KEYWORD_SET (wmax)) THEN	$
;  BEGIN
;     wmax = STRTRIM (STRING (wmax, FORMAT='(E8.2)'), 2)
;	ylab = ylab - y1 - y2 - y3
;     ydat = ylab - y2
;     XYOUTS, xoff, ylab, 'WMAX',	$
;		/device, font=lfont, charsize=cs1, color=red
;     XYOUTS, xoff, ydat, wmax,	$
;		/device, font=bfont, charsize=cs2, color=grey
;  END

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  XYOUTS, xoff, ylab, 'BRIGHTNESS UNIT',	$
;	  /device, font=lfont, charsize=cs1, color=red
;  XYOUTS, xoff, ydat, bunit,		$
;	  /device, font=bfont, charsize=cs2, color=grey

  ;-----------------
  ; Draw sun circle.
  ;-----------------

  gMINCOL = xb
  gMAXCOL = xb + xdim - 1
  gMINROW = yb
  gMAXROW = yb + ydim - 1

  radius =   1.0
  angmin =   0.0
  angmax = 360.0
  anginc =  10.0

  sun_circle, radius, angmin, angmax, anginc, yellow,  		$
	      xcen, ycen, pixrs, roll,				$
	      gMINCOL, gMAXCOL, gMINROW, gMAXROW

  radius = 1.6

  ;-------------------
  ; Draw radial lines.
  ;-------------------

  rmin    =  1.2
  rmax    =  1.7
  rinc    =  0.2
  anginc  = 30.0
  dotsize =  3

;  sunray, rmin, rmax, rinc, anginc, dotsize,	$
;	  xcen, ycen, pixrs, roll, red,  	$
;	  gMINCOL, gMAXCOL, gMINROW, gMAXROW

  rmin    =  0.2
  rmax    =  1.0
  rinc    =  0.2
  anginc  = 90.0
  dotsize =  3

  sunray_kcor, rmin, rmax, rinc, anginc, dotsize,	$
	       xcen, ycen, pixrs, roll, red,    	$
	       gMINCOL, gMAXCOL, gMINROW, gMAXROW

  ;--------------------
  ; Draw north pointer.
  ;--------------------

  cirrad = 1.0
  tiprad = 0.2

  north_kcor,  xcen, ycen, pixrs, roll, cirrad, tiprad, yellow,	$
               gMINCOL, gMAXCOL, gMINROW, gMAXROW

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

  ;------------------------
  ; Create color bar array.
  ;------------------------

  collin = bindgen (256)
  collin = rebin (collin, 512)
  colbar = bytarr (512, 12)
  for i = 0, 11 DO	$
     colbar [*, i] = collin [*]

  ;----------------
  ; Draw color bar.
  ;----------------

  xc1 = xdim / 2 + xb -1 - 256		; left   of color bar
  xc2 = xc1 + 511			; right  of color bar
  yc1 = 26				; bottom of color bar
  yc2 = 37				; top    of color bar

  print, 'xc1,xc2,yc1,yc2: ', xc1, xc2, yc1, yc2

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

  print, 'cs1: ', cs1
  XYOUTS, xc1 -         x1 / 2, yc1 -  8 - y1,   '0', /device, $
          charsize=cs2, color=grey
;          font=lfont, charsize=cs1, color=grey
  XYOUTS, xc1 + 127 - 2*x1 / 2, yc1 -  8 - y1,  '63', /device, $
          charsize=cs2, color=grey
;  	  font=lfont, charsize=cs1, color=grey
  XYOUTS, xc1 + 255 - 3*x1 / 2, yc1 -  8 - y1, '127', /device, $
          charsize=cs2, color=grey
;  	  font=lfont, charsize=cs1, color=grey
  XYOUTS, xc1 + 383 - 3*x1 / 2, yc1 -  8 - y1, '191', /device, $
          charsize=cs2, color=grey
;  	  font=lfont, charsize=cs1, color=grey
  XYOUTS, xc1 + 512 - 1.5*x1 - 1, yc1 -  8 - y1, '255', /device, $
          charsize=cs2, color=grey
;  	  font=lfont, charsize=cs1, color=grey

  ;------------
  ; Draw title.
  ;------------

  title = telescop
  lentit = STRLEN (title)
  print, 'lentit: ', lentit
  print, 'x4: ', x4
  print, 'lentit * x4 : ', lentit * x4
  xloc = xb + (xdim - (lentit * x4)) / 2
  ylab = yc2 + (yb - yc2 - y4) / 2 + FIX (y4 * 0.2) - 3
  ylab = yc2 + 10
  print, 'xloc: ', xloc
  print, 'yb, y4, ylab: ', yb, y4, ylab
  XYOUTS, xloc, ylab, title,		$
	  /device, charsize=cs4, color=red
;	  /device, font=bfont, charsize=cs4, color=red

  print, '<<<<<<< Leaving fits_annotate_kcor'
  RETURN
END
