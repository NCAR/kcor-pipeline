;+
; overlay_kcor.pro
;-------------------------------------------------------------------------------
; :purpose: draw a polar grid overlay into the occulting region of a kcor image.
;-------------------------------------------------------------------------------
; :author: Andrew L. Stanger   HAO/NCAR   cosmo K-coronagraph
; :history:  9 Jun 2015 IDL procedure created.
;
; :params: 
;   hdu		fits header
;   xdim	x-axis dimension
;   ydim	y-axis dimention
;   xb		x-axis border
;   yb		y-axis border
;   wmim	display minimum
;   wmax	display maximum
;-------------------------------------------------------------------------------
;-

PRO overlay_kcor, hdu, xdim, ydim, xb, yb, wmin=dmin, wmax=dmax

  ;--- Color assignments for annotation.

  white  = 255
  red    = 254
  green  = 253
  blue   = 252
  grey   = 251
  yellow = 250
  black  =   0

  ;--- Get information from FITS header.

  xcen      = fxpar (hdu, 'CRPIX1')
  ycen      = fxpar (hdu, 'CRPIX2')
  cdelt1    = fxpar (hdu, 'CDELT1')
  rsun     = fxpar (hdu, 'RSUN_OBS', count=qrsun)
  if (qrsun eq 0L) then rsun = fxpar (hdu, 'RSUN', count=qrsun)

  pangle    = fxpar (hdu, 'INST_ROT')

  pixrs     = rsun / cdelt1
  print, 'pixrs: ', pixrs

  ; --- Draw sun circle.

  gMINCOL = xb
  gMAXCOL = xb + xdim - 1
  gMINROW = yb
  gMAXROW = yb + ydim - 1

  radius =   1.0
  angmin =   0.0
  angmax = 360.0
  anginc =  10.0

  sundot_kcor, radius, angmin, angmax, anginc, yellow,  		$
	       xcen, ycen, pixrs, pangle,				$
	       gMINCOL, gMAXCOL, gMINROW, gMAXROW

  radius = 1.0
  sundot_kcor, radius, angmin, angmax, anginc, red,	    		$
	       xcen, ycen, pixrs, pangle,				$
	       gMINCOL, gMAXCOL, gMINROW, gMAXROW

  ; --- Draw radial lines.

  rmin    =  1.2
  rmax    =  1.7
  rinc    =  0.2
  anginc  = 30.0
  dotsize =  3

;  sunray, rmin, rmax, rinc, anginc, dotsize,	$
;	  xcen, ycen, pixrs, pangle, red,  	$
;	  gMINCOL, gMAXCOL, gMINROW, gMAXROW

  ;--- 30 degree radial lines.

  rmin    = 0.2
  rmax    = 1.0
  rinc    = 0.2
  anginc  = 30.0
  dotsize = 3
  sunray_kcor, rmin, rmax, rinc, anginc, dotsize,	$
	       xcen, ycen, pixrs, pangle, grey,     	$
	       gMINCOL, gMAXCOL, gMINROW, gMAXROW

  ;--- 90 degree radial lines.

  rmin    =  0.3
  rmax    =  0.95
  rinc    =  0.1
  anginc  = 90.0
  dotsize =  3

  sunray_kcor, rmin, rmax, rinc, anginc, dotsize,	$
	       xcen, ycen, pixrs, pangle, red,    	$
	       gMINCOL, gMAXCOL, gMINROW, gMAXROW

  ;--- Draw north pointer.

  cirrad = 3.00
  tiprad = 0.1

  north_kcor, xcen, ycen, pixrs, pangle, cirrad, tiprad, yellow,	$
              gMINCOL, gMAXCOL, gMINROW, gMAXROW

  cirrad = 1.0
  tiprad = 0.03
  north_kcor, xcen, ycen, pixrs, pangle, cirrad, tiprad, yellow,	$
              gMINCOL, gMAXCOL, gMINROW, gMAXROW

  RETURN
END
